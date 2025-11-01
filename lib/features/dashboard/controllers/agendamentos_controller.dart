import 'package:flutter/material.dart';
import '../../../services/repositories/repositories.dart';

class AgendamentosController extends ChangeNotifier {
  DateTime dataSelecionada = DateTime.now();
  final TextEditingController dataController = TextEditingController();
  
  List<Map<String, dynamic>> quadras = [];
  List<Map<String, dynamic>> reservas = [];
  List<String> horariosDisponiveis = [];
  
  bool isLoading = false;
  String? error;
  
  // Paginação de horários
  int _paginaHorariosAtual = 0;
  static const int _horariosPorPagina = 5;

  AgendamentosController() {
    _atualizarDataController();
  }
  
  // Getters para horários paginados
  List<String> get horariosPaginados {
    final inicio = _paginaHorariosAtual * _horariosPorPagina;
    final fim = inicio + _horariosPorPagina;
    if (inicio >= horariosDisponiveis.length) return [];
    return horariosDisponiveis.sublist(
      inicio, 
      fim > horariosDisponiveis.length ? horariosDisponiveis.length : fim
    );
  }
  
  bool get podePaginaAnterior => _paginaHorariosAtual > 0;
  
  bool get podePaginaProxima {
    final proximaPagina = (_paginaHorariosAtual + 1) * _horariosPorPagina;
    return proximaPagina < horariosDisponiveis.length;
  }
  
  void proximaPaginaHorarios() {
    if (podePaginaProxima) {
      _paginaHorariosAtual++;
      notifyListeners();
    }
  }
  
  void paginaAnteriorHorarios() {
    if (podePaginaAnterior) {
      _paginaHorariosAtual--;
      notifyListeners();
    }
  }
  
  // Navegação de datas
  void irParaHoje() {
    selecionarData(DateTime.now());
  }
  
  void irParaDiaAnterior() {
    selecionarData(dataSelecionada.subtract(const Duration(days: 1)));
  }
  
  void irParaProximoDia() {
    selecionarData(dataSelecionada.add(const Duration(days: 1)));
  }

  void _atualizarDataController() {
    final formatter = '${dataSelecionada.day.toString().padLeft(2, '0')}/'
        '${dataSelecionada.month.toString().padLeft(2, '0')}/'
        '${dataSelecionada.year}';
    dataController.text = formatter;
  }

  void selecionarData(DateTime data) {
    dataSelecionada = data;
    _atualizarDataController();
    carregarDadosAgendamentos();
    notifyListeners();
  }

  Future<void> carregarDadosAgendamentos() async {
    setLoading(true);
    clearError();

    try {
      final dataFormatada = _formatarDataParaAPI(dataSelecionada);
      
      // Carregar quadras
      final quadrasResp = await QuadraRepository.getQuadras();
      if (quadrasResp['success'] == true) {
        quadras = List<Map<String, dynamic>>.from(quadrasResp['data'] ?? [])
            .where((q) => q['ativa'] == true)
            .toList();
      }

      // Carregar todas as reservas do dia (sem filtro de status)
      final reservasResp = await QuadraRepository.getReservasComFiltros(
        dataInicio: dataFormatada,
        dataFim: dataFormatada,
        // Removido o filtro de status para pegar todas as reservas
      );
      
      if (reservasResp['success'] == true) {
        // Filtrar apenas reservas ativas (não canceladas)
        final todasReservas = List<Map<String, dynamic>>.from(reservasResp['data'] ?? []);
        reservas = todasReservas.where((r) => r['status'] != 'CANCELADA').toList();
        print('DEBUG: Carregadas ${reservas.length} reservas para $dataFormatada');
        if (reservas.isNotEmpty) {
          print('DEBUG: Primeira reserva: ${reservas[0]}');
        }
      }

      // Gerar horários disponíveis
      _gerarHorariosDisponiveis();
      print('DEBUG: Horários disponíveis: $horariosDisponiveis');
      
      // Montar estrutura de dados para o grid
      _montarDadosGrid();
      print('DEBUG: Quadras montadas: ${quadras.length}');
      if (quadras.isNotEmpty) {
        print('DEBUG: Primeira quadra horários: ${quadras[0]['horarios']?.length ?? 0}');
      }
    } catch (e) {
      setError('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void _montarDadosGrid() {
    print('DEBUG: Montando grid com ${quadras.length} quadras e ${reservas.length} reservas');
    
    // Para cada quadra, criar lista de horários com status
    for (var quadra in quadras) {
      final quadraId = quadra['id'];
      final horariosQuadra = <Map<String, dynamic>>[];
      
      for (final horario in horariosDisponiveis) {
        final horaInt = int.parse(horario.split(':')[0]);
        
        // Verificar se existe reserva para este horário nesta quadra
        final reserva = reservas.firstWhere(
          (r) {
            final match = r['quadraId'] == quadraId && r['hora'] == horaInt;
            if (match) {
              print('DEBUG: Match encontrado - Quadra: $quadraId, Hora: $horaInt, StatusPagamento: ${r['statusPagamento']}, Percentual: ${r['percentualPago']}');
            }
            return match;
          },
          orElse: () => {},
        );
        
        if (reserva.isNotEmpty) {
          // Horário ocupado com reserva
          final clienteNome = reserva['cliente']?['nomeCompleto'] ?? 'Cliente';
          final statusReserva = _determinarStatusReserva(reserva);
          
          horariosQuadra.add({
            'hora': horario,
            'status': statusReserva,
            'texto': clienteNome,
            'reservaId': reserva['id'],
          });
          print('DEBUG: Horário $horario - $clienteNome - Status: $statusReserva');
        } else {
          // Horário disponível
          horariosQuadra.add({
            'hora': horario,
            'status': 'disponivel',
            'texto': 'Disponível',
            'reservaId': null,
          });
        }
      }
      
      quadra['horarios'] = horariosQuadra;
      print('DEBUG: Quadra ${quadra['nome']}: ${horariosQuadra.length} horários montados');
    }
  }

  String _determinarStatusReserva(Map<String, dynamic> reserva) {
    // Verificar se é cliente fixo (mensalista) pelas observações
    final observacoes = (reserva['observacoes'] as String?)?.toLowerCase() ?? '';
    if (observacoes.contains('fixo') || observacoes.contains('mensalista')) {
      return 'cliente_fixo';
    }
    
    // Verificar status do pagamento
    final statusPagamento = reserva['statusPagamento'] as String?;
    final percentualPago = reserva['percentualPago'] as int?;
    
    // Pré-reserva: pagamento parcial (50%)
    if (statusPagamento == 'PARCIAL' || percentualPago == 50) {
      return 'pre_reserva';
    }
    
    // Confirmado: pagamento completo (100%)
    if (statusPagamento == 'COMPLETO' || percentualPago == 100) {
      return 'confirmado';
    }
    
    // Default: confirmado
    return 'confirmado';
  }

  void _gerarHorariosDisponiveis() {
    horariosDisponiveis = [];
    // Horários de 8h às 23h (conforme a API retorna)
    for (int hora = 8; hora <= 23; hora++) {
      horariosDisponiveis.add('${hora.toString().padLeft(2, '0')}:00');
    }
  }

  String _formatarDataParaAPI(DateTime data) {
    return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    this.error = error;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    dataController.dispose();
    super.dispose();
  }
}
