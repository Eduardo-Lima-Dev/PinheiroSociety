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

  AgendamentosController() {
    _atualizarDataController();
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
      // Carregar quadras
      final quadrasResp = await QuadraRepository.getQuadras();
      if (quadrasResp['success'] == true) {
        quadras = List<Map<String, dynamic>>.from(quadrasResp['data'] ?? []);
      }

      // Carregar reservas para a data selecionada
      final reservasResp = await QuadraRepository.getReservas();
      if (reservasResp['success'] == true) {
        final todasReservas = List<Map<String, dynamic>>.from(reservasResp['data'] ?? []);

        // Filtrar reservas para a data selecionada
        final dataFormatada = _formatarDataParaAPI(dataSelecionada);
        reservas = todasReservas.where((reserva) {
          final dataReserva = _extrairDataReserva(reserva);
          return dataReserva == dataFormatada;
        }).toList();
      }

      // Carregar disponibilidade de cada quadra para a data selecionada
      for (var quadra in quadras) {
        final quadraId = quadra['id'];
        if (quadraId != null) {
          final dataFormatada = _formatarDataParaAPI(dataSelecionada);
          final disponibilidadeResp = await QuadraRepository.getDisponibilidadeQuadra(
            quadraId: int.tryParse(quadraId.toString()) ?? 0,
            data: dataFormatada,
          );

          if (disponibilidadeResp['success'] == true) {
            final disponibilidade = disponibilidadeResp['data'] as Map<String, dynamic>;
            quadra['disponibilidade'] = disponibilidade;
          }
        }
      }

      // Gerar horários disponíveis
      _gerarHorariosDisponiveis();
    } catch (e) {
      setError('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void _gerarHorariosDisponiveis() {
    horariosDisponiveis = [];
    for (int hora = 6; hora <= 22; hora++) {
      horariosDisponiveis.add('${hora.toString().padLeft(2, '0')}:00');
    }
  }

  String _formatarDataParaAPI(DateTime data) {
    return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  String _extrairDataReserva(Map<String, dynamic> reserva) {
    final dataReserva = reserva['data']?.toString() ?? '';
    // Converter formato DD/MM/YYYY para YYYY-MM-DD se necessário
    if (dataReserva.contains('/')) {
      final partes = dataReserva.split('/');
      if (partes.length == 3) {
        return '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
      }
    }
    return dataReserva;
  }

  bool isHorarioDisponivel(String quadraId, String horario) {
    final quadra = quadras.firstWhere(
      (q) => q['id'].toString() == quadraId,
      orElse: () => {},
    );

    if (quadra.isEmpty) return false;

    final disponibilidade = quadra['disponibilidade'] as Map<String, dynamic>?;
    if (disponibilidade == null) return true;

    final horariosDisponiveis = disponibilidade['horariosDisponiveis'] as List<dynamic>? ?? [];
    return horariosDisponiveis.contains(horario);
  }

  bool isHorarioReservado(String quadraId, String horario) {
    return reservas.any((reserva) {
      return reserva['quadraId']?.toString() == quadraId &&
             reserva['horario']?.toString() == horario;
    });
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
