import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/horario_disponivel.dart';
import '../models/reserva.dart';
import '../../../services/repositories/repositories.dart';

class NovaReservaController extends ChangeNotifier {
  // Flag para evitar uso após dispose
  bool _disposed = false;

  // Modo de edição (reagendamento)
  bool _modoEdicao = false;
  int? _reservaIdParaReagendar;

  bool get modoEdicao => _modoEdicao;
  int? get reservaIdParaReagendar => _reservaIdParaReagendar;

  // Dados da reserva
  Cliente? clienteSelecionado;
  Map<String, dynamic>? quadraSelecionada;
  DateTime? dataSelecionada;
  HorarioDisponivel? horarioSelecionado;
  int duracaoMinutos = 60;
  bool isClienteFixo = false;
  DateTime? dataFimRecorrencia;

  // Dados de disponibilidade
  List<Map<String, dynamic>> quadras = [];
  List<Cliente> clientes = [];
  DisponibilidadeQuadra? disponibilidade;

  // Estados
  bool isLoading = false;
  bool isLoadingDisponibilidade = false;
  String? error;

  // Dados de pagamento
  String? formaPagamento;
  int? percentualPago;

  Future<void> carregarDadosIniciais() async {
    setLoading(true);
    clearError();

    try {
      print('DEBUG: Carregando dados iniciais...');

      // Carregar quadras
      final quadrasResp = await QuadraRepository.getQuadras();
      print(
          'DEBUG: Resposta quadras: ${quadrasResp['success']}, Dados: ${quadrasResp['data']}');
      if (quadrasResp['success'] == true) {
        final quadrasData = quadrasResp['data'];
        List<Map<String, dynamic>> listaQuadras = [];

        if (quadrasData is List) {
          listaQuadras = List<Map<String, dynamic>>.from(quadrasData);
        } else if (quadrasData is Map<String, dynamic>) {
          final lista = quadrasData['data'] ??
              quadrasData['items'] ??
              quadrasData['quadras'];
          if (lista is List) {
            listaQuadras = List<Map<String, dynamic>>.from(lista);
          }
        }

        quadras = listaQuadras.where((q) => q['ativa'] == true).toList();
        print('DEBUG: ${quadras.length} quadras carregadas');
      }

      // Carregar clientes
      final clientesResp = await ClienteRepository.getClientes();
      print('DEBUG: Resposta clientes RAW: $clientesResp');
      print('DEBUG: Resposta clientes success: ${clientesResp['success']}');
      print('DEBUG: Tipo de data: ${clientesResp['data'].runtimeType}');

      if (clientesResp['success'] == true) {
        final clientesData = clientesResp['data'];
        print('DEBUG: clientesData: $clientesData');

        List<dynamic> listaClientes = [];

        if (clientesData is List) {
          listaClientes = clientesData;
        } else if (clientesData is Map<String, dynamic>) {
          final lista = clientesData['data'] ??
              clientesData['items'] ??
              clientesData['clientes'];
          if (lista is List) {
            listaClientes = lista;
          }
        }

        if (listaClientes.isNotEmpty) {
          print(
              'DEBUG: clientesData é uma lista com ${listaClientes.length} itens');
          try {
            clientes = listaClientes.map((c) {
              print('DEBUG: Convertendo cliente: $c');
              return Cliente.fromJson(c as Map<String, dynamic>);
            }).toList();
            print('DEBUG: ${clientes.length} clientes carregados com sucesso');
            if (clientes.isNotEmpty) {
              print('DEBUG: Primeiro cliente: ${clientes[0].nomeCompleto}');
            }
          } catch (e) {
            print('ERROR: Erro ao converter clientes: $e');
            setError('Erro ao processar clientes: $e');
          }
        } else {
          print('DEBUG: Nenhum cliente encontrado na resposta');
        }
      } else {
        print(
            'ERROR: Falha ao carregar clientes: ${clientesResp['error'] ?? "Erro desconhecido"}');
        setError(
            'Erro ao carregar clientes: ${clientesResp['error'] ?? "Erro desconhecido"}');
      }
    } catch (e) {
      print('ERROR: Exceção ao carregar dados: ${e.toString()}');
      setError('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setLoading(false);
      print(
          'DEBUG: Carregamento finalizado. Clientes: ${clientes.length}, Quadras: ${quadras.length}');
    }
  }

  Future<void> carregarDisponibilidade() async {
    if (quadraSelecionada == null || dataSelecionada == null) return;

    setLoadingDisponibilidade(true);
    clearError();

    try {
      final quadraId = quadraSelecionada!['id'] as int;
      final dataFormatada = _formatarDataParaAPI(dataSelecionada!);

      final response = await QuadraRepository.getDisponibilidadeQuadra(
        quadraId: quadraId,
        data: dataFormatada,
      );

      if (response['success'] == true) {
        disponibilidade = DisponibilidadeQuadra.fromJson(
            response['data'] as Map<String, dynamic>);
        print(
            'DEBUG: Disponibilidade carregada: ${disponibilidade?.horarios.length} horários');
        print(
            'DEBUG: Horários disponíveis filtrados: ${horariosDisponiveisFiltrados.length}');
      } else {
        setError('Erro ao carregar disponibilidade');
      }
    } catch (e) {
      setError('Erro ao carregar disponibilidade: ${e.toString()}');
    } finally {
      setLoadingDisponibilidade(false);
    }
  }

  /// Retorna horários disponíveis filtrados por:
  /// 1. Apenas horários disponíveis (não ocupados)
  /// 2. Se for hoje, apenas horários a partir da hora atual
  List<HorarioDisponivel> get horariosDisponiveisFiltrados {
    if (disponibilidade == null) return [];

    final agora = DateTime.now();
    final ehHoje = dataSelecionada != null &&
        dataSelecionada!.year == agora.year &&
        dataSelecionada!.month == agora.month &&
        dataSelecionada!.day == agora.day;

    return disponibilidade!.horarios.where((horario) {
      // Filtro 1: Apenas horários disponíveis
      if (!horario.disponivel) return false;

      // Filtro 2: Se for hoje, apenas horários a partir da hora atual
      if (ehHoje) {
        final horaAtual = agora.hour;
        // Se já passou do minuto 30, considerar próxima hora
        final horaMinima = agora.minute >= 30 ? horaAtual + 1 : horaAtual;
        return horario.hora >= horaMinima;
      }

      return true;
    }).toList();
  }

  /// Inicializa o controller em modo de edição (reagendamento)
  Future<void> inicializarModoEdicao(Reserva reserva) async {
    if (_disposed) return;

    _modoEdicao = true;
    _reservaIdParaReagendar = reserva.id;

    // Preencher dados da reserva existente
    clienteSelecionado =
        reserva.cliente != null ? Cliente.fromJson(reserva.cliente!) : null;
    quadraSelecionada = reserva.quadra;

    // Parse da data
    try {
      // Remove timestamp se houver (2025-11-04T12:00:00 -> 2025-11-04)
      final dataSemTimestamp = reserva.data.split('T')[0];
      final dataParts = dataSemTimestamp.split('-');
      if (dataParts.length >= 3) {
        dataSelecionada = DateTime(
          int.parse(dataParts[0]),
          int.parse(dataParts[1]),
          int.parse(dataParts[2]),
        );
      }
    } catch (e) {
      print('ERROR: Erro ao parsear data: $e');
    }

    // Criar HorarioDisponivel temporário com os dados da reserva
    horarioSelecionado = HorarioDisponivel(
      hora: reserva.hora,
      disponivel: true,
      precoCents: reserva.precoCents,
      precoReais: reserva.precoReais,
    );

    isClienteFixo = reserva.recorrente;

    notifyListeners();

    // Carregar dados iniciais após preencher
    await carregarDadosIniciais();
  }

  Future<bool> criarReserva() async {
    if (!validarDados()) return false;

    // Se estiver em modo de edição, chama reagendar em vez de criar
    if (_modoEdicao && _reservaIdParaReagendar != null) {
      return await reagendarReserva();
    }

    setLoading(true);
    clearError();

    try {
      final quadraIdRaw = quadraSelecionada!['id'];
      final clienteIdRaw = clienteSelecionado!.id;

      int quadraId;
      if (quadraIdRaw is int) {
        quadraId = quadraIdRaw;
      } else {
        quadraId = int.parse(quadraIdRaw.toString());
      }

      final int clienteId = clienteIdRaw is int
          ? clienteIdRaw as int
          : int.parse(clienteIdRaw.toString());

      final reserva = Reserva(
        clienteId: clienteId,
        quadraId: quadraId,
        data: _formatarDataParaAPI(dataSelecionada!),
        hora: horarioSelecionado!.hora,
        precoCents: horarioSelecionado!.precoCents,
        status: 'ATIVA',
        observacoes: isClienteFixo ? 'Cliente fixo (mensalista)' : null,
      );

      // Criar JSON com dados de pagamento e recorrência (quando cliente fixo)
      final reservaJson = {
        'clienteId': reserva.clienteId,
        'quadraId': reserva.quadraId,
        'data': reserva.data,
        'hora': reserva.hora,
        'duracaoMinutos': duracaoMinutos,
        if (formaPagamento != null) 'payment': formaPagamento,
        if (percentualPago != null) 'percentualPago': percentualPago,
        if (reserva.observacoes != null && reserva.observacoes!.isNotEmpty)
          'observacoes': reserva.observacoes,
        if (isClienteFixo) ...{
          'recorrente': true,
          // weekday do Dart: 1=Mon ... 7=Sun. Backend deve alinhar.
          'diaSemana': dataSelecionada!.weekday,
          if (dataFimRecorrencia != null)
            'dataFimRecorrencia': _formatarDataParaAPI(dataFimRecorrencia!),
        },
      };

      print('DEBUG: Criando reserva com dados: $reservaJson');
      print('DEBUG: Duração selecionada: $duracaoMinutos minutos');

      final response = await QuadraRepository.criarReserva(reservaJson);

      print('DEBUG: Resposta da API: $response');
      if (response['success'] == true && response['data'] != null) {
        print(
            'DEBUG: Duração retornada pela API: ${response['data']['duracaoMinutos']}');
      }

      if (response['success'] == true) {
        return true;
      } else {
        final errorMsg =
            response['error'] ?? response['message'] ?? 'Erro ao criar reserva';
        setError(errorMsg);
        print('ERROR: $errorMsg');
        return false;
      }
    } catch (e) {
      final errorMsg = 'Erro ao criar reserva: ${e.toString()}';
      setError(errorMsg);
      print('ERROR: $errorMsg');
      return false;
    } finally {
      if (!_disposed) {
        setLoading(false);
      }
    }
  }

  Future<bool> reagendarReserva() async {
    if (_reservaIdParaReagendar == null) return false;
    if (!validarDados()) return false;

    setLoading(true);
    clearError();

    try {
      final dados = {
        'novaData': _formatarDataParaAPI(dataSelecionada!),
        'novaHora': horarioSelecionado!.hora,
        'duracaoMinutos': duracaoMinutos,
        'observacoes': 'Reagendamento solicitado',
      };

      print(
          'DEBUG: Reagendando reserva ${_reservaIdParaReagendar} com dados: $dados');

      final response = await QuadraRepository.reagendarReserva(
        reservaId: _reservaIdParaReagendar!,
        dados: dados,
      );

      print('DEBUG: Resposta da API: $response');

      if (response['success'] == true) {
        return true;
      } else {
        final errorMsg = response['error'] ??
            response['message'] ??
            'Erro ao reagendar reserva';
        setError(errorMsg);
        print('ERROR: $errorMsg');
        return false;
      }
    } catch (e) {
      final errorMsg = 'Erro ao reagendar reserva: ${e.toString()}';
      setError(errorMsg);
      print('ERROR: $errorMsg');
      return false;
    } finally {
      if (!_disposed) {
        setLoading(false);
      }
    }
  }

  bool validarDados() {
    if (clienteSelecionado == null) {
      setError('Selecione um cliente');
      return false;
    }
    if (quadraSelecionada == null) {
      setError('Selecione uma quadra');
      return false;
    }
    if (dataSelecionada == null) {
      setError('Selecione uma data');
      return false;
    }
    if (horarioSelecionado == null) {
      setError('Selecione um horário');
      return false;
    }
    return true;
  }

  bool podeAvancar() {
    return clienteSelecionado != null &&
        quadraSelecionada != null &&
        dataSelecionada != null &&
        horarioSelecionado != null;
  }

  double get valorTotal {
    if (horarioSelecionado == null) return 0.0;

    // Calcular valor proporcional baseado na duração
    // Preço base é para 60 minutos, então multiplicamos pela proporção
    final precoBase = horarioSelecionado!.precoReais;
    final proporcaoDuracao = duracaoMinutos / 60.0;

    return precoBase * proporcaoDuracao;
  }

  String _formatarDataParaAPI(DateTime data) {
    return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  void selecionarCliente(Cliente cliente) {
    if (_disposed) return;
    clienteSelecionado = cliente;
    notifyListeners();
  }

  void selecionarQuadra(Map<String, dynamic> quadra) {
    if (_disposed) return;
    quadraSelecionada = quadra;
    disponibilidade = null;
    horarioSelecionado = null;
    if (dataSelecionada != null) {
      carregarDisponibilidade();
    }
    notifyListeners();
  }

  void selecionarData(DateTime data) {
    if (_disposed) return;
    dataSelecionada = data;
    disponibilidade = null;
    horarioSelecionado = null;
    if (quadraSelecionada != null) {
      carregarDisponibilidade();
    }
    notifyListeners();
  }

  void selecionarHorario(HorarioDisponivel horario) {
    if (_disposed) return;
    horarioSelecionado = horario;
    notifyListeners();
  }

  void selecionarDuracao(int minutos) {
    if (_disposed) return;
    duracaoMinutos = minutos;
    notifyListeners();
  }

  void selecionarFimRecorrencia(DateTime? data) {
    if (_disposed) return;
    dataFimRecorrencia = data;
    notifyListeners();
  }

  void toggleClienteFixo(bool value) {
    if (_disposed) return;
    isClienteFixo = value;
    notifyListeners();
  }

  void selecionarFormaPagamento(String forma) {
    if (_disposed) return;
    formaPagamento = forma;
    notifyListeners();
  }

  void selecionarPercentualPago(int percentual) {
    if (_disposed) return;
    percentualPago = percentual;
    notifyListeners();
  }

  void reset() {
    if (_disposed) return;
    _modoEdicao = false;
    _reservaIdParaReagendar = null;
    clienteSelecionado = null;
    quadraSelecionada = null;
    dataSelecionada = null;
    horarioSelecionado = null;
    duracaoMinutos = 60;
    isClienteFixo = false;
    dataFimRecorrencia = null;
    disponibilidade = null;
    formaPagamento = null;
    percentualPago = null;
    error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_disposed) return;
    isLoading = loading;
    notifyListeners();
  }

  void setLoadingDisponibilidade(bool loading) {
    if (_disposed) return;
    isLoadingDisponibilidade = loading;
    notifyListeners();
  }

  void setError(String? error) {
    if (_disposed) return;
    this.error = error;
    notifyListeners();
  }

  void clearError() {
    if (_disposed) return;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
