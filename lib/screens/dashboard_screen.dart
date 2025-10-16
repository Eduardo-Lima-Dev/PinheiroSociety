import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
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

  // Métricas
  String reservasHoje = '-';
  String totalClientes = '-';
  String receitaHoje = '-';
  String ocupacao = '-';

  // Listas
  List<Map<String, String>> proximasReservas = [];
  List<Map<String, dynamic>> alertasEstoque = [];
  Timer? _autoRefreshTimer;
  bool _mostrarTodasReservas = false;
  String _selectedSection = 'inicio'; // 'inicio' | 'cadastro' | 'cliente'

  // Controllers da seção de cadastro (mesmo modelo de Register)
  final _registerFormKey = GlobalKey<FormState>();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regIsPasswordVisible = false;
  bool _regIsSubmitting = false;

  // Controllers da seção de cadastro de cliente
  final _clienteFormKey = GlobalKey<FormState>();
  final _clienteNomeController = TextEditingController();
  final _clienteEmailController = TextEditingController();
  final _clienteTelefoneController = TextEditingController();
  final _clienteCpfController = TextEditingController();
  bool _clienteIsSubmitting = false;

  // Máscaras para CPF e Telefone
  final _cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _carregarDados());
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
      final clientesResp = await ApiService.getRelatorioClientes();

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
        proximasReservas = lista.map((e) {
          final m = e as Map<String, dynamic>;
          final name = _extractClienteNome(m['cliente']) ??
              _asString(m['nomeCliente']) ??
              'Cliente';
          final quadra = _extractQuadraNome(m['quadra']) ??
              _asString(m['campo']) ??
              'Quadra';
          final time = _extractHorario(m);
          final status = _asString(m['status']);
          return {
            'name': name,
            'time': '$quadra · $time',
            'status': status.isEmpty ? '—' : status,
          };
        }).toList();
      } else {
        _error ??= reservasResp['error']?.toString();
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
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmbeddedRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _regIsSubmitting = true);
    try {
      final result = await ApiService.register(
        name: _regNameController.text.trim(),
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text,
        role: 'ADMIN',
      );
      if (!mounted) return;
      setState(() => _regIsSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green),
        );
        _regNameController.clear();
        _regEmailController.clear();
        _regPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Erro no cadastro'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _regIsSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro inesperado: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cadastrarCliente() async {
    if (!_clienteFormKey.currentState!.validate()) return;
    setState(() => _clienteIsSubmitting = true);
    try {
      final result = await ApiService.createCliente(
        nomeCompleto: _clienteNomeController.text.trim(),
        cpf: _cpfMaskFormatter.getUnmaskedText(),
        email: _clienteEmailController.text.trim(),
        telefone: _telefoneMaskFormatter.getUnmaskedText(),
      );

      if (!mounted) return;
      setState(() => _clienteIsSubmitting = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cliente cadastrado com sucesso!'),
              backgroundColor: Colors.green),
        );
        _clienteNomeController.clear();
        _clienteEmailController.clear();
        _clienteTelefoneController.clear();
        _clienteCpfController.clear();
        _telefoneMaskFormatter.clear();
        _cpfMaskFormatter.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Erro no cadastro'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _clienteIsSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro inesperado: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  // Validação de CPF
  bool _isValidCPF(String cpf) {
    // Remove pontos e traços
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica se tem 11 dígitos
    if (cpf.length != 11) return false;

    // Verifica se todos os dígitos são iguais
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;

    // Algoritmo de validação do CPF
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
    // Remove caracteres especiais
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Verifica se tem 10 ou 11 dígitos (com ou sem DDD)
    return cleanPhone.length == 10 || cleanPhone.length == 11;
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

  String? _extractClienteNome(dynamic cliente) {
    if (cliente == null) return null;
    if (cliente is Map<String, dynamic>) {
      return (cliente['nomeCompleto'] ?? cliente['nome'] ?? cliente['name'])
          ?.toString();
    }
    return cliente.toString();
  }

  String? _extractQuadraNome(dynamic quadra) {
    if (quadra == null) return null;
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

  @override
  Widget build(BuildContext context) {
    const greenBackground = Color(0xFF0E5C3A); // fundo verde escuro
    const sidebarColor = Color(0xFF121416); // sidebar quase preta
    const cardColor = Color(0xFF1B1E21); // cards/prateleiras
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
                      // avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sports_soccer,
                            color: Colors.white70),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _lowStockBanner(warningColor),
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
                      const _SidebarItem(
                          icon: Icons.people_outline, label: 'Clientes'),
                      const _SidebarItem(
                          icon: Icons.event_note_outlined,
                          label: 'Agendamentos',
                          badge: '3'),
                      const _SidebarItem(
                          icon: Icons.restaurant_menu, label: 'Mesas'),
                      const _SidebarItem(
                          icon: Icons.inventory_2_outlined, label: 'Estoque'),
                      const _SidebarItem(
                          icon: Icons.bar_chart_outlined, label: 'Relatórios'),
                      _SidebarItem(
                          icon: Icons.person_add_alt_1,
                          label: 'Cadastro de Acesso',
                          selected: _selectedSection == 'cadastro',
                          onTap: () =>
                              setState(() => _selectedSection = 'cadastro')),
                      _SidebarItem(
                          icon: Icons.person_add,
                          label: 'Cadastro de Cliente',
                          selected: _selectedSection == 'cliente',
                          onTap: () =>
                              setState(() => _selectedSection = 'cliente')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bem-vindo, Admin!',
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
                        Text(
                          'ARENA\nPINHEIRO SOCIETY',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        )
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
                          const SizedBox(width: 16),
                          Expanded(
                              child: _StatCard(
                                  title: 'Receita Hoje',
                                  value: receitaHoje,
                                  subtitle: null,
                                  icon: Icons.attach_money)),
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

                  // Conteúdo alternável: Início (listas), Cadastro de Acesso ou Cadastro de Cliente
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
                                action: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarTodasReservas =
                                          !_mostrarTodasReservas;
                                    });
                                  },
                                  child: Text(
                                    _mostrarTodasReservas
                                        ? 'Mostrar menos'
                                        : 'Mostrar todas',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70),
                                  ),
                                ),
                                child: ListView(
                                  children: proximasReservas
                                      .map((r) {
                                        final status =
                                            (r['status'] ?? '').toLowerCase();
                                        Color color;
                                        if (status.contains('confirm')) {
                                          color = Colors.green;
                                        } else if (status.contains('aguard') ||
                                            status.contains('pend')) {
                                          color = Colors.amber;
                                        } else {
                                          color = Colors.blueAccent;
                                        }
                                        return _ReservationTile(
                                          name: r['name'] ?? '—',
                                          time: r['time'] ?? '—',
                                          status: r['status'] ?? '—',
                                          statusColor: color,
                                        );
                                      })
                                      .take(_mostrarTodasReservas ? 9999 : 5)
                                      .toList(),
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

                  // Formulário de Cadastro de Acesso
                  if (_selectedSection == 'cadastro')
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Center(
                          child: Container(
                            width: 500,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1E21),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Form(
                              key: _registerFormKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Cadastro de Acesso',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  Text('Nome',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _regNameController,
                                    keyboardType: TextInputType.name,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'João da Silva',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira seu nome';
                                      if (value.length < 2)
                                        return 'O nome deve ter pelo menos 2 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Email',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _regEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'exemplo@exemplo.com',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira seu email';
                                      final emailRegex = RegExp(
                                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(value))
                                        return 'Por favor, insira um email válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Senha',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _regPasswordController,
                                    obscureText: !_regIsPasswordVisible,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Senha123',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _regIsPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[400],
                                        ),
                                        onPressed: () => setState(() =>
                                            _regIsPasswordVisible =
                                                !_regIsPasswordVisible),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira sua senha';
                                      if (value.length < 6)
                                        return 'A senha deve ter pelo menos 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _regIsSubmitting
                                          ? null
                                          : _handleEmbeddedRegister,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          elevation: 0),
                                      child: _regIsSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white)))
                                          : Text('Cadastrar',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Formulário de Cadastro de Cliente
                  if (_selectedSection == 'cliente')
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1E21),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Form(
                              key: _clienteFormKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Cadastro de Cliente',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  Text('Nome Completo',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _clienteNomeController,
                                    keyboardType: TextInputType.name,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'João da Silva',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
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
                                  Text('Email',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _clienteEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'exemplo@exemplo.com',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira o email';
                                      final emailRegex = RegExp(
                                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(value))
                                        return 'Por favor, insira um email válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Telefone',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _clienteTelefoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [_telefoneMaskFormatter],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '(11) 99999-9999',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira o telefone';
                                      if (!_isValidPhone(value))
                                        return 'Por favor, insira um telefone válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text('CPF',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _clienteCpfController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [_cpfMaskFormatter],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '000.000.000-00',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Por favor, insira o CPF';
                                      if (!_isValidCPF(value))
                                        return 'Por favor, insira um CPF válido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _clienteIsSubmitting
                                        ? null
                                        : _cadastrarCliente,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A90E2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _clienteIsSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Cadastrar Cliente',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
Widget _lowStockBanner(Color warningColor) {
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
            '2 itens com\nestoque baixo',
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
  final String status;
  final Color statusColor;
  const _ReservationTile({
    super.key,
    required this.name,
    required this.time,
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
