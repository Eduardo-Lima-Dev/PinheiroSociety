import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import 'dart:async';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  String _userName = 'Usuário';
  bool _isAdmin = false;

  // Métricas
  String reservasHoje = '-';
  String totalClientes = '-';
  String receitaHoje = '-';
  String ocupacao = '-';

  // Listas
  List<Map<String, String>> proximasReservas = [];
  List<Map<String, dynamic>> alertasEstoque = [];
  List<Map<String, dynamic>> clientes = [];
  Timer? _autoRefreshTimer;
  String _selectedSection =
      'inicio'; // 'inicio' | 'clientes' | 'cadastro-acesso' | 'agendamentos'

  // Controller para busca de clientes
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Controllers para modal de cliente
  final _modalFormKey = GlobalKey<FormState>();
  final _modalNomeController = TextEditingController();
  final _modalEmailController = TextEditingController();
  final _modalTelefoneController = TextEditingController();
  final _modalCpfController = TextEditingController();
  bool _modalIsSubmitting = false;
  bool _isEditing = false;
  Map<String, dynamic>? _clienteEditando;

  // Controllers para cadastro de acesso
  final _cadastroAcessoFormKey = GlobalKey<FormState>();
  final _cadastroNomeController = TextEditingController();
  final _cadastroEmailController = TextEditingController();
  final _cadastroSenhaController = TextEditingController();
  final _cadastroConfirmarSenhaController = TextEditingController();
  bool _cadastroSenhaVisivel = false;
  bool _cadastroConfirmarSenhaVisivel = false;
  bool _cadastroIsSubmitting = false;
  String _cadastroRoleSelecionada = 'ADMIN';

  // Lista de roles disponíveis
  final List<Map<String, String>> _rolesDisponiveis = [
    {'value': 'ADMIN', 'label': 'Administrador'},
    {'value': 'USER', 'label': 'Funcionário'},
  ];

  // Variáveis para agendamentos
  DateTime _dataSelecionada = DateTime.now();
  final TextEditingController _dataController = TextEditingController();
  List<Map<String, dynamic>> _quadrasApi = [];
  List<Map<String, dynamic>> _reservasApi = [];
  List<String> _horariosDisponiveis = [];
  bool _isLoadingAgendamentos = false;

  // Máscaras para CPF e Telefone
  final _cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _carregarDados();
    _atualizarDataController(); // Inicializar o controller da data
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _carregarDados());
  }

  Future<void> _carregarNomeUsuario() async {
    final userName = await UserStorage.getUserName();
    final isAdmin = await UserStorage.isAdmin();
    if (mounted) {
      setState(() {
        _userName = userName;
        _isAdmin = isAdmin;
        // Se não for admin e estiver na seção de cadastro de acesso, redirecionar para início
        if (!isAdmin && _selectedSection == 'cadastro-acesso') {
          _selectedSection = 'inicio';
        }
      });
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await ApiService.getDashboardSummary();
      final reservasResp = await ApiService.getReservas();
      final quadrasResp = await ApiService.getQuadras();
      final clientesResp = await ApiService.getClientes();

      if (dashboard['success'] == true) {
        final data = dashboard['data'] as Map<String, dynamic>;
        final mes = (data['mes'] ?? {}) as Map<String, dynamic>;
        final hoje = (data['hoje'] ?? {}) as Map<String, dynamic>;
        final alertas = (data['alertas'] ?? {}) as Map<String, dynamic>;

        // Reservas de hoje = quantidade em hoje.reservas
        final reservasHojeList = (hoje['reservas'] ?? []) as List<dynamic>;
        reservasHoje = reservasHojeList.length.toString();

        // Total de clientes: preferir /relatorios/clientes
        if (clientesResp['success'] == true) {
          final d = clientesResp['data'];
          if (d is List) {
            totalClientes = d.length.toString();
          } else if (d is Map<String, dynamic>) {
            final c =
                d['total'] ?? d['count'] ?? d['clientesCount'] ?? d['clientes'];
            if (c is int) {
              totalClientes = c.toString();
            } else if (c is List) {
              totalClientes = c.length.toString();
            } else {
              totalClientes = _asString(c);
            }
          }
        } else {
          // fallback: usar comandasCount do mês
          totalClientes = _asString(mes['comandasCount']);
        }

        // Receita do dia: somatório de precoCents
        final int receitaCentsHoje = reservasHojeList.fold<int>(0, (acc, item) {
          final m = item is Map<String, dynamic> ? item : <String, dynamic>{};
          final preco = m['precoCents'];
          if (preco is int) return acc + preco;
          if (preco is num) return acc + preco.toInt();
          return acc;
        });
        receitaHoje = _formatCurrencyBRL(receitaCentsHoje / 100.0);

        // Ocupação: calcular com base em quantidade de quadras e janelas de horário
        // Regra aproximada: janela operacional 08:00–22:00 (14 slots/hora) por quadra
        int quadrasCount = 0;
        if (quadrasResp['success'] == true) {
          final listaQ = quadrasResp['data'];
          if (listaQ is List) quadrasCount = listaQ.length;
        }
        if (quadrasCount > 0) {
          const int slotsPorQuadra = 14; // 08–22
          final int totalSlots = quadrasCount * slotsPorQuadra;
          final int ocupadas = reservasHojeList.length;
          final double pct =
              totalSlots > 0 ? (ocupadas / totalSlots) * 100.0 : 0.0;
          ocupacao = '${pct.toStringAsFixed(0)}%';
        } else {
          ocupacao = '-';
        }

        // Alertas de estoque: lista em alertas.produtos (name, quantidade, minQuantidade)
        final produtosAlertas = (alertas['produtos'] ?? []) as List<dynamic>;
        alertasEstoque = produtosAlertas.map((e) {
          final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
          final productName =
              (m['name'] ?? m['nome'] ?? m['produto'] ?? 'Item').toString();
          final currentQty = m['quantidade'] ??
              m['estoqueAtual'] ??
              m['atual'] ??
              m['current'] ??
              0;
          final minQty = m['minQuantidade'] ??
              m['estoqueMin'] ??
              m['minimo'] ??
              m['min'] ??
              0;
          return <String, dynamic>{
            'product': productName,
            'current': currentQty,
            'min': minQty,
          };
        }).toList();
      } else {
        _error = dashboard['error']?.toString();
      }

      if (reservasResp['success'] == true) {
        final lista = reservasResp['data'] as List<dynamic>;
        // Filtrar apenas reservas dos próximos 3 dias (hoje + 2 dias)
        final reservasFiltradas = lista.where((e) {
          final m = e as Map<String, dynamic>;
          return _isReservaWithinNext3Days(m);
        }).toList();

        proximasReservas = reservasFiltradas.map((e) {
          final m = e as Map<String, dynamic>;
          final name = _extractClienteNome(m['cliente']).isEmpty
              ? _asString(m['nomeCliente']).isEmpty
                  ? 'Cliente'
                  : _asString(m['nomeCliente'])
              : _extractClienteNome(m['cliente']);
          final quadra = _extractQuadraNome(m['quadra']).isEmpty
              ? _asString(m['campo']).isEmpty
                  ? 'Quadra'
                  : _asString(m['campo'])
              : _extractQuadraNome(m['quadra']);
          final time = _extractHorario(m);
          final data = _extractData(m);
          final status = _asString(m['status']);

          return {
            'name': name,
            'time': '$quadra · $time',
            'data': data,
            'status': status.isEmpty ? '—' : status,
          };
        }).toList();
      } else {
        _error ??= reservasResp['error']?.toString();
      }

      // Carregar lista de clientes
      if (clientesResp['success'] == true) {
        final listaClientes = clientesResp['data'];
        if (listaClientes is List) {
          clientes = listaClientes.map((e) {
            final m = e as Map<String, dynamic>;
            return {
              'id': m['id']?.toString() ?? '',
              'nomeCompleto': m['nomeCompleto']?.toString() ?? '',
              'cpf': m['cpf']?.toString() ?? '',
              'email': m['email']?.toString() ?? '',
              'telefone': m['telefone']?.toString() ?? '',
            };
          }).toList();
        }
      }
    } catch (e) {
      _error = 'Erro ao carregar dados: ${e.toString()}';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _modalNomeController.dispose();
    _modalEmailController.dispose();
    _modalTelefoneController.dispose();
    _modalCpfController.dispose();
    _cadastroNomeController.dispose();
    _cadastroEmailController.dispose();
    _cadastroSenhaController.dispose();
    _cadastroConfirmarSenhaController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String _asString(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toString();
    return v.toString();
  }

  String _formatCurrencyBRL(double value) {
    // Formatação simples: R$ 2.450,00 (sem intl por enquanto)
    String s = value.toStringAsFixed(2).replaceAll('.', ',');
    // inserir pontos para milhares
    final parts = s.split(',');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return 'R\$ ${buffer.toString()},${parts[1]}';
  }

  String _formatCPF(String cpf) {
    if (cpf.isEmpty) return 'Não informado';
    // Remove caracteres não numéricos
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCpf.length != 11) return cpf; // Retorna original se não for válido

    // Aplica máscara: 000.000.000-00
    return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9)}';
  }

  String _formatTelefone(String telefone) {
    if (telefone.isEmpty) return 'Não informado';
    // Remove caracteres não numéricos
    final cleanTel = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanTel.length == 11) {
      // Formato: (11) 99999-9999
      return '(${cleanTel.substring(0, 2)}) ${cleanTel.substring(2, 7)}-${cleanTel.substring(7)}';
    } else if (cleanTel.length == 10) {
      // Formato: (11) 9999-9999
      return '(${cleanTel.substring(0, 2)}) ${cleanTel.substring(2, 6)}-${cleanTel.substring(6)}';
    }
    return telefone; // Retorna original se não for válido
  }

  String _extractClienteNome(dynamic cliente) {
    if (cliente == null) return '';
    if (cliente is Map<String, dynamic>) {
      return (cliente['nomeCompleto'] ?? cliente['nome'] ?? cliente['name'])
              ?.toString() ??
          '';
    }
    return cliente.toString();
  }

  String _extractQuadraNome(dynamic quadra) {
    if (quadra == null) return '';
    if (quadra is Map<String, dynamic>) {
      final nome = quadra['nome'] ?? quadra['name'];
      if (nome != null) return nome.toString();
      if (quadra['id'] != null) return 'Quadra ${quadra['id']}';
    }
    return quadra.toString();
  }

  String _extractHorario(Map<String, dynamic> reserva) {
    final h = reserva['horario'] ??
        reserva['hora'] ??
        reserva['inicio'] ??
        reserva['time'];
    if (h == null) return '-';
    if (h is int) {
      return '${h.toString().padLeft(2, '0')}:00';
    }
    return h.toString();
  }

  String _extractData(Map<String, dynamic> reserva) {
    // Tentar diferentes campos possíveis para a data
    final data = reserva['data'] ??
        reserva['date'] ??
        reserva['dia'] ??
        reserva['dataReserva'] ??
        reserva['createdAt'] ??
        reserva['updatedAt'] ??
        reserva['dataAgendamento'] ??
        reserva['agendamento'] ??
        reserva['reservaData'];

    if (data == null) {
      return '-';
    }

    // Se a data vem como string, tentar formatar
    if (data is String) {
      try {
        // Assumindo formato ISO ou similar: "2024-01-15" ou "2024-01-15T10:00:00Z"
        final dateOnly = data.split('T')[0];
        final parts = dateOnly.split('-');
        if (parts.length == 3) {
          // Formato: DD/MM/YYYY
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return dateOnly;
      } catch (e) {
        return data;
      }
    }

    return data.toString();
  }

  /// Verifica se uma reserva está dentro dos próximos 3 dias (hoje + 2 dias)
  bool _isReservaWithinNext3Days(Map<String, dynamic> reserva) {
    try {
      final data = reserva['data'] ??
          reserva['date'] ??
          reserva['dia'] ??
          reserva['dataReserva'] ??
          reserva['createdAt'] ??
          reserva['updatedAt'] ??
          reserva['dataAgendamento'] ??
          reserva['agendamento'] ??
          reserva['reservaData'];

      if (data == null) return false;

      DateTime? reservaDate;

      if (data is String) {
        try {
          // Tentar diferentes formatos de data
          final dateOnly = data.split('T')[0];
          final parts = dateOnly.split('-');
          if (parts.length == 3) {
            // Formato YYYY-MM-DD
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            reservaDate = DateTime(year, month, day);
          } else {
            // Tentar parse direto
            reservaDate = DateTime.parse(data);
          }
        } catch (e) {
          return false;
        }
      } else if (data is DateTime) {
        reservaDate = data;
      }

      if (reservaDate == null) return false;

      // Pegar data atual (sem hora)
      final hoje = DateTime.now();
      final hojeLimpo = DateTime(hoje.year, hoje.month, hoje.day);

      // Limpar hora da data da reserva
      final reservaDateLimpo =
          DateTime(reservaDate.year, reservaDate.month, reservaDate.day);

      // Calcular diferença em dias
      final diasDiferenca = reservaDateLimpo.difference(hojeLimpo).inDays;

      // Retorna true se estiver entre hoje (0 dias) e 2 dias no futuro (2 dias)
      return diasDiferenca >= 0 && diasDiferenca <= 2;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> _getFilteredClientes() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return clientes;
    }

    return clientes.where((cliente) {
      final nome = cliente['nomeCompleto']?.toString().toLowerCase() ?? '';
      return nome.contains(query);
    }).toList();
  }

  Future<void> _buscarClientes() async {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // Apenas atualiza a UI para refletir a filtragem local
      if (mounted) {
        setState(() {
          // A filtragem é feita pelo _getFilteredClientes()
        });
      }
    });
  }

  Future<void> _carregarClientes() async {
    try {
      final result = await ApiService.getClientes();
      if (result['success'] == true) {
        final listaClientes = result['data'];
        if (listaClientes is List) {
          setState(() {
            clientes = listaClientes.map((e) {
              final m = e as Map<String, dynamic>;
              return {
                'id': m['id']?.toString() ?? '',
                'nomeCompleto': m['nomeCompleto']?.toString() ?? '',
                'cpf': m['cpf']?.toString() ?? '',
                'email': m['email']?.toString() ?? '',
                'telefone': m['telefone']?.toString() ?? '',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      // Em caso de erro, manter a lista atual
    }
  }

  // Validação de CPF
  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int firstDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != firstDigit) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int secondDigit = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cpf[10]) == secondDigit;
  }

  // Validação de telefone
  bool _isValidPhone(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPhone.length == 10 || cleanPhone.length == 11;
  }

  void _abrirModalCliente({Map<String, dynamic>? cliente}) {
    _isEditing = cliente != null;
    _clienteEditando = cliente;

    // Limpar ou preencher campos
    _modalNomeController.text = cliente?['nomeCompleto'] ?? '';
    _modalEmailController.text = cliente?['email'] ?? '';

    // Para telefone e CPF, aplicar as máscaras corretamente
    final telefone = cliente?['telefone'] ?? '';
    final cpf = cliente?['cpf'] ?? '';

    // Limpar controllers primeiro
    _modalTelefoneController.clear();
    _modalCpfController.clear();

    // Aplicar valores formatados nos controllers
    if (telefone.isNotEmpty) {
      _modalTelefoneController.text = _formatTelefone(telefone);
    }

    if (cpf.isNotEmpty) {
      _modalCpfController.text = _formatCPF(cpf);
    }

    showDialog(
      context: context,
      builder: (context) => _ClienteModal(
        formKey: _modalFormKey,
        nomeController: _modalNomeController,
        emailController: _modalEmailController,
        telefoneController: _modalTelefoneController,
        cpfController: _modalCpfController,
        cpfMaskFormatter: _cpfMaskFormatter,
        telefoneMaskFormatter: _telefoneMaskFormatter,
        isEditing: _isEditing,
        isSubmitting: _modalIsSubmitting,
        onSave: _salvarCliente,
        onCancel: () => Navigator.of(context).pop(),
        isValidCPF: _isValidCPF,
        isValidPhone: _isValidPhone,
      ),
    );
  }

  Future<void> _salvarCliente() async {
    if (!_modalFormKey.currentState!.validate()) return;

    setState(() => _modalIsSubmitting = true);

    try {
      final result = _isEditing
          ? await ApiService.updateCliente(
              id: _clienteEditando!['id'],
              nomeCompleto: _modalNomeController.text.trim(),
              cpf: _cpfMaskFormatter.getUnmaskedText(),
              email: _modalEmailController.text.trim(),
              telefone: _telefoneMaskFormatter.getUnmaskedText(),
            )
          : await ApiService.createCliente(
              nomeCompleto: _modalNomeController.text.trim(),
              cpf: _cpfMaskFormatter.getUnmaskedText(),
              email: _modalEmailController.text.trim(),
              telefone: _telefoneMaskFormatter.getUnmaskedText(),
            );

      if (!mounted) return;
      setState(() => _modalIsSubmitting = false);

      if (result['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Cliente atualizado com sucesso!'
                : 'Cliente criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _limparModal();
        _carregarClientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao salvar cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _modalIsSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limparModal() {
    _modalNomeController.clear();
    _modalEmailController.clear();
    _modalTelefoneController.clear();
    _modalCpfController.clear();
    _isEditing = false;
    _clienteEditando = null;
  }

  Future<void> _salvarCadastroAcesso() async {
    if (!_cadastroAcessoFormKey.currentState!.validate()) return;

    setState(() => _cadastroIsSubmitting = true);

    try {
      final result = await ApiService.register(
        name: _cadastroNomeController.text.trim(),
        email: _cadastroEmailController.text.trim(),
        password: _cadastroSenhaController.text,
        role: _cadastroRoleSelecionada,
      );

      if (!mounted) return;
      setState(() => _cadastroIsSubmitting = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _limparFormularioCadastroAcesso();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao criar usuário'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cadastroIsSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limparFormularioCadastroAcesso() {
    _cadastroNomeController.clear();
    _cadastroEmailController.clear();
    _cadastroSenhaController.clear();
    _cadastroConfirmarSenhaController.clear();
    _cadastroSenhaVisivel = false;
    _cadastroConfirmarSenhaVisivel = false;
    _cadastroRoleSelecionada = 'ADMIN';
  }

  void _atualizarDataController() {
    final formatter = '${_dataSelecionada.day.toString().padLeft(2, '0')}/'
        '${_dataSelecionada.month.toString().padLeft(2, '0')}/'
        '${_dataSelecionada.year}';
    _dataController.text = formatter;
  }

  Future<void> _carregarDadosAgendamentos() async {
    if (_selectedSection != 'agendamentos') return;

    setState(() {
      _isLoadingAgendamentos = true;
    });

    try {
      // Carregar quadras
      final quadrasResp = await ApiService.getQuadras();
      if (quadrasResp['success'] == true) {
        _quadrasApi =
            List<Map<String, dynamic>>.from(quadrasResp['data'] ?? []);
      }

      // Carregar reservas para a data selecionada
      final reservasResp = await ApiService.getReservas();
      if (reservasResp['success'] == true) {
        final todasReservas =
            List<Map<String, dynamic>>.from(reservasResp['data'] ?? []);

        // Filtrar reservas para a data selecionada
        final dataFormatada = _formatarDataParaAPI(_dataSelecionada);
        _reservasApi = todasReservas.where((reserva) {
          final dataReserva = _extrairDataReserva(reserva);
          return dataReserva == dataFormatada;
        }).toList();
      }

      // Carregar disponibilidade de cada quadra para a data selecionada
      for (var quadra in _quadrasApi) {
        final quadraId = quadra['id'];
        if (quadraId != null) {
          final dataFormatada = _formatarDataParaAPI(_dataSelecionada);
          final disponibilidadeResp = await ApiService.getDisponibilidadeQuadra(
            quadraId: int.tryParse(quadraId.toString()) ?? 0,
            data: dataFormatada,
          );

          if (disponibilidadeResp['success'] == true) {
            quadra['disponibilidade'] = disponibilidadeResp['data'];
          }
        }
      }

      // Extrair todos os horários disponíveis do sistema
      _extrairHorariosDisponiveis();
    } catch (e) {
      print('Erro ao carregar dados de agendamentos: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingAgendamentos = false;
      });
    }
  }

  void _extrairHorariosDisponiveis() {
    Set<String> horariosUnicos = {};

    // Coletar horários das reservas
    for (var reserva in _reservasApi) {
      final horario = _extrairHorarioReserva(reserva);
      if (horario.isNotEmpty) {
        horariosUnicos.add(horario);
      }
    }

    // Coletar horários das próprias quadras (configuração de funcionamento)
    for (var quadra in _quadrasApi) {
      // Verificar se a quadra tem configuração de horários
      final horariosConfig = quadra['horarios'] ??
          quadra['horariosFuncionamento'] ??
          quadra['workingHours'] ??
          quadra['horariosDisponiveis'];

      if (horariosConfig != null) {
        if (horariosConfig is List) {
          for (var item in horariosConfig) {
            if (item != null) {
              final horarioStr = item.toString();
              if (_isHorarioValido(horarioStr)) {
                horariosUnicos.add(_formatarHorario(horarioStr));
              }
            }
          }
        } else if (horariosConfig is Map<String, dynamic>) {
          final inicio = horariosConfig['inicio'] ?? horariosConfig['start'];
          final fim = horariosConfig['fim'] ?? horariosConfig['end'];
          if (inicio != null && fim != null) {
            _adicionarHorariosEntre(inicio, fim, horariosUnicos);
          }
        }
      }

      // Coletar horários da disponibilidade das quadras
      final disponibilidade = quadra['disponibilidade'];
      if (disponibilidade != null) {
        if (disponibilidade is List) {
          for (var item in disponibilidade) {
            if (item != null) {
              final horarioStr = item.toString();
              if (_isHorarioValido(horarioStr)) {
                horariosUnicos.add(_formatarHorario(horarioStr));
              }
            }
          }
        } else if (disponibilidade is Map<String, dynamic>) {
          final horariosDisponiveis = disponibilidade['horarios'] ??
              disponibilidade['disponiveis'] ??
              disponibilidade['available'] ??
              disponibilidade['slots'];
          if (horariosDisponiveis is List) {
            for (var item in horariosDisponiveis) {
              if (item != null) {
                final horarioStr = item.toString();
                if (_isHorarioValido(horarioStr)) {
                  horariosUnicos.add(_formatarHorario(horarioStr));
                }
              }
            }
          }
        }
      }
    }

    // Converter para lista e ordenar
    _horariosDisponiveis = horariosUnicos.toList();
    _horariosDisponiveis.sort((a, b) => a.compareTo(b));

    // Se não encontrou horários, usar padrão
    if (_horariosDisponiveis.isEmpty) {
      _horariosDisponiveis = [
        '08:00',
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
        '20:00',
        '21:00',
        '22:00'
      ];
    }
  }

  bool _isHorarioValido(String horario) {
    if (horario.isEmpty) return false;

    // Verificar se está no formato HH:mm ou H:mm
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(horario);
  }

  String _formatarHorario(String horario) {
    // Se já está no formato correto, retornar
    if (_isHorarioValido(horario)) {
      // Adicionar zero à esquerda se necessário (ex: 9:00 -> 09:00)
      final parts = horario.split(':');
      if (parts.length == 2) {
        final hora = parts[0].padLeft(2, '0');
        final minuto = parts[1];
        return '$hora:$minuto';
      }
    }

    // Se é apenas um número (ex: 9, 18), converter para HH:00
    final horaInt = int.tryParse(horario);
    if (horaInt != null && horaInt >= 0 && horaInt <= 23) {
      return '${horaInt.toString().padLeft(2, '0')}:00';
    }

    return horario;
  }

  void _adicionarHorariosEntre(
      dynamic inicio, dynamic fim, Set<String> horariosUnicos) {
    try {
      int horaInicio;
      int horaFim;

      // Converter entrada para int (assumindo que são horas como 8, 9, 18, etc.)
      if (inicio is int) {
        horaInicio = inicio;
      } else if (inicio is String) {
        if (inicio.contains(':')) {
          horaInicio = int.parse(inicio.split(':')[0]);
        } else {
          horaInicio = int.parse(inicio);
        }
      } else {
        return;
      }

      if (fim is int) {
        horaFim = fim;
      } else if (fim is String) {
        if (fim.contains(':')) {
          horaFim = int.parse(fim.split(':')[0]);
        } else {
          horaFim = int.parse(fim);
        }
      } else {
        return;
      }

      // Adicionar horários de hora em hora entre inicio e fim
      for (int h = horaInicio; h <= horaFim; h++) {
        if (h >= 0 && h <= 23) {
          horariosUnicos.add('${h.toString().padLeft(2, '0')}:00');
        }
      }
    } catch (e) {
      // Em caso de erro na conversão, não adicionar horários
    }
  }

  String _formatarDataParaAPI(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  String _extrairDataReserva(Map<String, dynamic> reserva) {
    final data = reserva['data'] ??
        reserva['dataReserva'] ??
        reserva['dataAgendamento'] ??
        reserva['createdAt'];

    if (data == null) return '';

    if (data is String) {
      try {
        final dateOnly = data.split('T')[0];
        return dateOnly; // Já deve estar no formato YYYY-MM-DD
      } catch (e) {
        return '';
      }
    }

    return data.toString();
  }

  void _irParaDataAnterior() {
    setState(() {
      _dataSelecionada = _dataSelecionada.subtract(const Duration(days: 1));
      _atualizarDataController();
    });
    _carregarDadosAgendamentos();
  }

  void _irParaHoje() {
    setState(() {
      _dataSelecionada = DateTime.now();
      _atualizarDataController();
    });
    _carregarDadosAgendamentos();
  }

  void _irParaProximaData() {
    setState(() {
      _dataSelecionada = _dataSelecionada.add(const Duration(days: 1));
      _atualizarDataController();
    });
    _carregarDadosAgendamentos();
  }

  // Função para construir as quadras com dados reais da API
  List<Map<String, dynamic>> _getQuadras() {
    if (_quadrasApi.isEmpty) {
      return [];
    }

    return _quadrasApi.map((quadraApi) {
      final nome = quadraApi['nome']?.toString() ?? 'Quadra sem nome';
      final id = quadraApi['id']?.toString();

      // Buscar reservas desta quadra para a data selecionada
      final reservasQuadra = _reservasApi.where((reserva) {
        final quadraReserva = reserva['quadra'];
        String? idQuadraReserva;

        if (quadraReserva is Map<String, dynamic>) {
          idQuadraReserva = quadraReserva['id']?.toString();
        } else {
          idQuadraReserva = quadraReserva?.toString();
        }

        return idQuadraReserva == id;
      }).toList();

      // Construir horários baseado na disponibilidade e reservas
      List<Map<String, dynamic>> horarios = [];

      for (String hora in _getHorarios()) {
        // Verificar se há reserva neste horário
        Map<String, dynamic> reservaHora = {};
        try {
          reservaHora = reservasQuadra.firstWhere(
            (reserva) {
              final horarioReserva = _extrairHorarioReserva(reserva);
              return horarioReserva == hora;
            },
          );
        } catch (e) {
          // Nenhuma reserva encontrada para este horário
          reservaHora = {};
        }

        Map<String, dynamic> horario;
        if (reservaHora.isNotEmpty) {
          // Há reserva neste horário
          final status =
              reservaHora['status']?.toString().toLowerCase() ?? 'confirmado';
          horario = {
            'hora': hora,
            'status': status,
            'texto': _getTextoStatus(status),
            'reserva': reservaHora,
          };
        } else {
          // Verificar disponibilidade na API
          final disponibilidade = quadraApi['disponibilidade'];
          final isDisponivel =
              _verificarDisponibilidadeHorario(disponibilidade, hora);

          horario = {
            'hora': hora,
            'status': isDisponivel ? 'disponivel' : 'bloqueado',
            'texto': isDisponivel ? 'Disponível' : 'Bloqueado',
          };
        }

        horarios.add(horario);
      }

      return {
        'id': id,
        'nome': nome,
        'horarios': horarios,
      };
    }).toList();
  }

  String _extrairHorarioReserva(Map<String, dynamic> reserva) {
    final horario = reserva['horario'] ??
        reserva['hora'] ??
        reserva['inicio'] ??
        reserva['time'];

    if (horario == null) return '';

    if (horario is int) {
      return '${horario.toString().padLeft(2, '0')}:00';
    }

    if (horario is String) {
      // Se já está no formato HH:mm, retornar
      if (horario.contains(':')) {
        return horario;
      }
      // Se é apenas um número, converter para HH:00
      final horarioInt = int.tryParse(horario);
      if (horarioInt != null) {
        return '${horarioInt.toString().padLeft(2, '0')}:00';
      }
    }

    return horario.toString();
  }

  String _getTextoStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
      case 'confirmed':
        return 'Confirmado';
      case 'cancelado':
      case 'cancelled':
        return 'Cancelado';
      case 'pendente':
      case 'pending':
        return 'Pendente';
      case 'pre-reserva':
      case 'prereserva':
        return 'Pré-reserva';
      case 'bloqueado':
      case 'blocked':
        return 'Bloqueado';
      default:
        return 'Confirmado';
    }
  }

  bool _verificarDisponibilidadeHorario(dynamic disponibilidade, String hora) {
    if (disponibilidade == null) return true;

    // Se disponibilidade é uma lista de horários disponíveis
    if (disponibilidade is List) {
      return disponibilidade.contains(hora) ||
          disponibilidade
              .any((item) => item.toString().contains(hora.split(':')[0]));
    }

    // Se disponibilidade é um objeto com horários
    if (disponibilidade is Map<String, dynamic>) {
      final horariosDisponiveis = disponibilidade['horarios'] ??
          disponibilidade['disponiveis'] ??
          disponibilidade['available'];
      if (horariosDisponiveis is List) {
        return horariosDisponiveis.contains(hora);
      }
    }

    // Por padrão, considerar disponível
    return true;
  }

  List<String> _getHorarios() {
    // Retorna os horários carregados da API ou fallback para padrão
    if (_horariosDisponiveis.isNotEmpty) {
      return _horariosDisponiveis;
    }

    // Fallback para horários padrão se ainda não carregou
    return [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00'
    ];
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'confirmado':
        return Colors.green;
      case 'pre-reserva':
        return Colors.blue;
      case 'bloqueado':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _mostrarFuncionalidadeEmDesenvolvimento() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deletarCliente(Map<String, dynamic> cliente) async {
    // Mostrar diálogo de confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[400],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Confirmar Exclusão',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a excluir permanentemente:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.red[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${cliente['nomeCompleto']}"',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.orange[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ ATENÇÃO: Esta ação é IRREVERSÍVEL!',
                          style: GoogleFonts.poppins(
                            color: Colors.orange[300],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Todos os dados do cliente serão permanentemente removidos do sistema.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Excluir Permanentemente',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final result = await ApiService.deleteCliente(cliente['id']);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cliente "${cliente['nomeCompleto']}" excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarClientes(); // Recarregar lista de clientes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao excluir cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const greenBackground = Color(0xFF0E5C3A); // fundo verde escuro
    const sidebarColor = Color(0xFF121416); // sidebar quase preta
    const warningColor = Color(0xFF3A2A00); // alerta estoque baixo

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: sidebarColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // avatar - apenas ícone sem imagem
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.sports_soccer,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARENA',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'PINHEIRO SOCIETY',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (alertasEstoque.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _lowStockBanner(warningColor, alertasEstoque.length),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _SidebarItem(
                          icon: Icons.home_outlined,
                          label: 'Início',
                          selected: _selectedSection == 'inicio',
                          onTap: () =>
                              setState(() => _selectedSection = 'inicio')),
                      _SidebarItem(
                          icon: Icons.people_outline,
                          label: 'Clientes',
                          selected: _selectedSection == 'clientes',
                          onTap: () {
                            setState(() => _selectedSection = 'clientes');
                            _carregarClientes();
                          }),
                      _SidebarItem(
                          icon: Icons.event_note_outlined,
                          label: 'Agendamentos',
                          badge: '3',
                          selected: _selectedSection == 'agendamentos',
                          onTap: () {
                            setState(() => _selectedSection = 'agendamentos');
                            _carregarDadosAgendamentos();
                          }),
                      _SidebarItem(
                          icon: Icons.restaurant_menu,
                          label: 'Mesas',
                          onTap: () =>
                              _mostrarFuncionalidadeEmDesenvolvimento()),
                      _SidebarItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Estoque',
                          onTap: () =>
                              _mostrarFuncionalidadeEmDesenvolvimento()),
                      _SidebarItem(
                          icon: Icons.bar_chart_outlined,
                          label: 'Relatórios',
                          onTap: () =>
                              _mostrarFuncionalidadeEmDesenvolvimento()),
                      if (_isAdmin)
                        _SidebarItem(
                            icon: Icons.person_add_alt_1,
                            label: 'Cadastro de Acesso',
                            selected: _selectedSection == 'cadastro-acesso',
                            onTap: () {
                              setState(
                                  () => _selectedSection = 'cadastro-acesso');
                            }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      await UserStorage.clearUserData();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    icon: const Icon(Icons.exit_to_app),
                    label: Text(
                      'Sair',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: greenBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!,
                            style:
                                GoogleFonts.poppins(color: Colors.redAccent)),
                      ),
                    ),
                  // Header - apenas na seção início
                  if (_selectedSection == 'inicio')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo, $_userName!',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'sexta-feira, 10 de outubro de 2025',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Logo no canto superior direito
                          Image.asset(
                            'assets/images/Logo.png',
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),

                  // Stat cards - apenas na seção início
                  if (_selectedSection == 'inicio') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatCard(
                                  title: 'Reservas Hoje',
                                  value: reservasHoje,
                                  icon: Icons.calendar_today_outlined)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _StatCard(
                                  title: 'Total de Clientes',
                                  value: totalClientes,
                                  subtitle: null,
                                  icon: Icons.people_outline)),
                          if (_isAdmin) ...[
                            const SizedBox(width: 16),
                            Expanded(
                                child: _StatCard(
                                    title: 'Receita Hoje',
                                    value: receitaHoje,
                                    subtitle: null,
                                    icon: Icons.attach_money)),
                          ],
                          const SizedBox(width: 16),
                          Expanded(
                              child: _StatCard(
                                  title: 'Horários ocupados',
                                  value: ocupacao,
                                  subtitle: null,
                                  icon: Icons.trending_up)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Conteúdo alternável: Início (listas), Clientes, Cadastro de Acesso ou Cadastro de Cliente
                  if (_selectedSection == 'inicio')
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _Panel(
                                title: 'Próximas Reservas',
                                child: proximasReservas.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 48,
                                              color: Colors.white30,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Nenhuma reserva próxima',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white60,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Não há reservas para os próximos 3 dias',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white
                                                    .withOpacity(0.4),
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView(
                                        children: proximasReservas.map((r) {
                                          final status =
                                              (r['status'] ?? '').toLowerCase();
                                          Color color;
                                          // Cores específicas para diferentes status
                                          if (status.contains('confirm') ||
                                              status.contains('confirmado')) {
                                            color = Colors
                                                .green; // Verde para confirmado/ativo
                                          } else if (status
                                                  .contains('cancel') ||
                                              status.contains('cancelado')) {
                                            color = Colors
                                                .red; // Vermelho para cancelado
                                          } else if (status
                                                  .contains('conclu') ||
                                              status.contains('concluido') ||
                                              status.contains('finalizado')) {
                                            color = Colors
                                                .blue; // Azul para concluído
                                          } else if (status
                                                  .contains('aguard') ||
                                              status.contains('pend') ||
                                              status.contains('aguardando')) {
                                            color = Colors
                                                .orange; // Laranja para aguardando/pendente
                                          } else {
                                            color = Colors
                                                .grey; // Cinza para status não identificado
                                          }
                                          return _ReservationTile(
                                            name: r['name'] ?? '—',
                                            time: r['time'] ?? '—',
                                            data: r['data'] ?? '—',
                                            status: r['status'] ?? '—',
                                            statusColor: color,
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _Panel(
                                title: 'Alertas de Estoque',
                                child: ListView(
                                  children: alertasEstoque
                                      .map((a) => _StockAlertTile(
                                            product: (a['product'] ?? 'Item')
                                                .toString(),
                                            current: int.tryParse(
                                                    '${a['current']}') ??
                                                0,
                                            min: int.tryParse('${a['min']}') ??
                                                0,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Seção de Clientes
                  if (_selectedSection == 'clientes')
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header da seção
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clientes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Gerencie o cadastro de clientes!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Image.asset(
                                  'assets/images/Logo.png',
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Barra de busca e botão novo cliente
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1E21),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar por nome...',
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400]),
                                        prefixIcon: const Icon(Icons.search,
                                            color: Colors.white70),
                                        suffixIcon: _searchController
                                                .text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear,
                                                    color: Colors.white70),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _buscarClientes();
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF2A2D30),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 16),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          // Força a reconstrução para mostrar/esconder o botão de limpar
                                        });
                                        _buscarClientes();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _abrirModalCliente();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      'Novo Cliente',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Lista de clientes
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1E21),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_getFilteredClientes().length} Clientes',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount:
                                            _getFilteredClientes().length,
                                        itemBuilder: (context, index) {
                                          final cliente =
                                              _getFilteredClientes()[index];
                                          return _ClienteCard(
                                            cliente: cliente,
                                            onEdit: () {
                                              _abrirModalCliente(
                                                  cliente: cliente);
                                            },
                                            onDelete: () {
                                              _deletarCliente(cliente);
                                            },
                                            formatCPF: _formatCPF,
                                            formatTelefone: _formatTelefone,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Seção de Cadastro de Acesso
                  if (_selectedSection == 'cadastro-acesso' && _isAdmin)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header da seção
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cadastro de Acesso',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Criar novos usuários do sistema',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Image.asset(
                                  'assets/images/Logo.png',
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Formulário de cadastro
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1E21),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _cadastroAcessoFormKey,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Novo Usuário',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Nome
                                        Text(
                                          'Nome Completo',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _cadastroNomeController,
                                          keyboardType: TextInputType.name,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'João da Silva',
                                            hintStyle: TextStyle(
                                                color: Colors.grey[400]),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.25),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor, insira o nome completo';
                                            }
                                            if (value.length < 2) {
                                              return 'O nome deve ter pelo menos 2 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Email
                                        Text(
                                          'Email',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _cadastroEmailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'exemplo@exemplo.com',
                                            hintStyle: TextStyle(
                                                color: Colors.grey[400]),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.25),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor, insira o email';
                                            }
                                            final emailRegex = RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                            if (!emailRegex.hasMatch(value)) {
                                              return 'Por favor, insira um email válido';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Senha
                                        Text(
                                          'Senha',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _cadastroSenhaController,
                                          obscureText: !_cadastroSenhaVisivel,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Senha123',
                                            hintStyle: TextStyle(
                                                color: Colors.grey[400]),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.25),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _cadastroSenhaVisivel
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey[400],
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cadastroSenhaVisivel =
                                                      !_cadastroSenhaVisivel;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor, insira uma senha';
                                            }
                                            if (value.length < 6) {
                                              return 'A senha deve ter pelo menos 6 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Confirmar Senha
                                        Text(
                                          'Confirmar Senha',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller:
                                              _cadastroConfirmarSenhaController,
                                          obscureText:
                                              !_cadastroConfirmarSenhaVisivel,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Confirme a senha',
                                            hintStyle: TextStyle(
                                                color: Colors.grey[400]),
                                            filled: true,
                                            fillColor:
                                                Colors.black.withOpacity(0.25),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _cadastroConfirmarSenhaVisivel
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey[400],
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cadastroConfirmarSenhaVisivel =
                                                      !_cadastroConfirmarSenhaVisivel;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor, confirme a senha';
                                            }
                                            if (value !=
                                                _cadastroSenhaController.text) {
                                              return 'As senhas não coincidem';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Role
                                        Text(
                                          'Tipo de Usuário',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _cadastroRoleSelecionada,
                                            dropdownColor:
                                                const Color(0xFF2A2D30),
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8)),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            items:
                                                _rolesDisponiveis.map((role) {
                                              return DropdownMenuItem<String>(
                                                value: role['value'],
                                                child: Text(
                                                  role['label']!,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _cadastroRoleSelecionada =
                                                      newValue;
                                                });
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor, selecione um tipo de usuário';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Botão Cadastrar
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: _cadastroIsSubmitting
                                                ? null
                                                : _salvarCadastroAcesso,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _cadastroIsSubmitting
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    'Cadastrar Usuário',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Seção de Agendamentos
                  if (_selectedSection == 'agendamentos')
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header da seção
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Agendamentos',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Gerencie as reservas das quadras',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Image.asset(
                                  'assets/images/Logo.png',
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Barra de navegação de data
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1E21),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _dataController,
                                      readOnly: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Selecionar data',
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400]),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF2A2D30),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                      onTap: () async {
                                        final selectedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: _dataSelecionada,
                                          firstDate: DateTime.now().subtract(
                                              const Duration(days: 30)),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.dark(
                                                  primary: Colors.green,
                                                  onPrimary: Colors.white,
                                                  surface: Color(0xFF1B1E21),
                                                  onSurface: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (selectedDate != null) {
                                          setState(() {
                                            _dataSelecionada = selectedDate;
                                            _atualizarDataController();
                                          });
                                          _carregarDadosAgendamentos();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: _irParaDataAnterior,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                    child: Text(
                                      'Anterior',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _irParaHoje,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                    child: Text(
                                      'Hoje',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _irParaProximaData,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                    child: Text(
                                      'Próximo',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _mostrarFuncionalidadeEmDesenvolvimento();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(
                                      'Nova Reserva',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Timeline das Quadras
                            Text(
                              'Timeline das Quadras',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Legenda
                            Row(
                              children: [
                                _LegendaItem(
                                  color: Colors.green,
                                  label: 'Confirmado',
                                ),
                                const SizedBox(width: 24),
                                _LegendaItem(
                                  color: Colors.blue,
                                  label: 'Pré-reserva',
                                ),
                                const SizedBox(width: 24),
                                _LegendaItem(
                                  color: Colors.black,
                                  label: 'Cliente Fixo',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Grid de agendamentos
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1E21),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _isLoadingAgendamentos
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.green),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Carregando agendamentos...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _AgendamentosGrid(
                                        quadras: _getQuadras(),
                                        horarios: _getHorarios(),
                                        getCorStatus: _getCorStatus,
                                      ),
                              ),
                            ),

                            // Texto informativo
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Horários bloqueados indicam clientes fixos (mensalistas). Estes horários são permanentemente reservados e não podem ser alterados sem autorização administrativa.',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar banner
Widget _lowStockBanner(Color warningColor, int itemCount) {
  return Container(
    decoration: BoxDecoration(
      color: warningColor,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$itemCount ${itemCount == 1 ? 'item com' : 'itens com'}\nestoque baixo',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.green.withOpacity(0.15) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          label,
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
        ),
        onTap: onTap,
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(badge!,
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  const _StatCard(
      {super.key,
      required this.title,
      required this.value,
      this.subtitle,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E21),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text(value,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 11)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Panel(
      {super.key, required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1B1E21),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white60, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final String name;
  final String time;
  final String data;
  final String status;
  final Color statusColor;
  const _ReservationTile({
    super.key,
    required this.name,
    required this.time,
    required this.data,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(time,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Data: $data',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999)),
            child: Text(status,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _StockAlertTile extends StatelessWidget {
  final String product;
  final int current;
  final int min;
  const _StockAlertTile(
      {super.key,
      required this.product,
      required this.current,
      required this.min});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF2A210E),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Estoque atual: $current | Mínimo: $min',
              style: GoogleFonts.poppins(color: Colors.amber, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(String) formatCPF;
  final String Function(String) formatTelefone;

  const _ClienteCard({
    super.key,
    required this.cliente,
    required this.onEdit,
    required this.onDelete,
    required this.formatCPF,
    required this.formatTelefone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D30),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente['nomeCompleto'] ?? 'Nome não informado',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CPF: ${formatCPF(cliente['cpf']?.toString() ?? '')}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${cliente['email'] ?? 'Não informado'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tel: ${formatTelefone(cliente['telefone']?.toString() ?? '')}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.white70),
                tooltip: 'Editar cliente',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'Excluir cliente',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClienteModal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController emailController;
  final TextEditingController telefoneController;
  final TextEditingController cpfController;
  final MaskTextInputFormatter cpfMaskFormatter;
  final MaskTextInputFormatter telefoneMaskFormatter;
  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool Function(String) isValidCPF;
  final bool Function(String) isValidPhone;

  const _ClienteModal({
    super.key,
    required this.formKey,
    required this.nomeController,
    required this.emailController,
    required this.telefoneController,
    required this.cpfController,
    required this.cpfMaskFormatter,
    required this.telefoneMaskFormatter,
    required this.isEditing,
    required this.isSubmitting,
    required this.onSave,
    required this.onCancel,
    required this.isValidCPF,
    required this.isValidPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B1E21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Editar Cliente' : 'Novo Cliente',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Nome Completo
              Text(
                'Nome Completo',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nomeController,
                keyboardType: TextInputType.name,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'João da Silva',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Por favor, insira o nome completo';
                  if (value.length < 2)
                    return 'O nome deve ter pelo menos 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              Text(
                'Email',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'exemplo@exemplo.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Por favor, insira o email';
                  final emailRegex =
                      RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value))
                    return 'Por favor, insira um email válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefone
              Text(
                'Telefone',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneMaskFormatter],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '(11) 99999-9999',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Por favor, insira o telefone';
                  if (!isValidPhone(value))
                    return 'Por favor, insira um telefone válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CPF
              Text(
                'CPF',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfMaskFormatter],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '000.000.000-00',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Por favor, insira o CPF';
                  if (!isValidCPF(value))
                    return 'Por favor, insira um CPF válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isSubmitting ? null : onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEditing ? 'Atualizar' : 'Criar',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendaItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AgendamentosGrid extends StatelessWidget {
  final List<Map<String, dynamic>> quadras;
  final List<String> horarios;
  final Color Function(String) getCorStatus;

  const _AgendamentosGrid({
    required this.quadras,
    required this.horarios,
    required this.getCorStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com horários
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Quadra',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: horarios.map((hora) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        hora,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Linhas das quadras
        Expanded(
          child: ListView.builder(
            itemCount: quadras.length,
            itemBuilder: (context, index) {
              final quadra = quadras[index];
              final nomeQuadra = quadra['nome'] as String;
              final horariosQuadra =
                  quadra['horarios'] as List<Map<String, dynamic>>;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Nome da quadra
                    SizedBox(
                      width: 120,
                      child: Text(
                        nomeQuadra,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Horários da quadra
                    Expanded(
                      child: Row(
                        children: horarios.map((hora) {
                          Map<String, dynamic> horarioQuadra;
                          try {
                            horarioQuadra = horariosQuadra.firstWhere(
                              (h) => h['hora'] == hora,
                            ) as Map<String, dynamic>;
                          } catch (e) {
                            // Se não encontrar, usar valores padrão
                            horarioQuadra = {
                              'hora': hora,
                              'status': 'disponivel',
                              'texto': 'Disponível',
                            };
                          }

                          final status = horarioQuadra['status'] as String;
                          final texto = horarioQuadra['texto'] as String;
                          final cor = getCorStatus(status);

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Aqui pode ser adicionada a lógica para abrir uma modal de reserva
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('$texto - $hora - $nomeQuadra'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cor,
                                  foregroundColor: status == 'disponivel'
                                      ? Colors.white
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  texto,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
