import '../api_client.dart';

/// Repository para operações de quadras e reservas
class QuadraRepository {
  /// Busca todas as quadras
  static Future<Map<String, dynamic>> getQuadras() async {
    return await ApiClient.get('/quadras');
  }

  /// Busca disponibilidade de uma quadra específica
  static Future<Map<String, dynamic>> getDisponibilidadeQuadra({
    required int quadraId,
    required String data,
  }) async {
    return await ApiClient.get(
      '/quadras/$quadraId/disponibilidade?data=$data',
    );
  }

  /// Busca todas as reservas
  static Future<Map<String, dynamic>> getReservas() async {
    return await ApiClient.get('/reservas');
  }

  /// Busca reservas com filtros de data e status
  static Future<Map<String, dynamic>> getReservasComFiltros({
    required String dataInicio,
    required String dataFim,
    String? status,
  }) async {
    String url = '/reservas?dataInicio=$dataInicio&dataFim=$dataFim';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    return await ApiClient.get(url);
  }

  /// Busca detalhes de uma reserva específica
  static Future<Map<String, dynamic>> getReservaById(int id) async {
    return await ApiClient.get('/reservas/$id');
  }

  /// Cria uma nova reserva
  static Future<Map<String, dynamic>> criarReserva(Map<String, dynamic> dados) async {
    return await ApiClient.post('/reservas', dados);
  }

  /// Cancela uma reserva
  static Future<Map<String, dynamic>> cancelarReserva(int reservaId) async {
    return await ApiClient.put('/reservas/$reservaId/cancelar', {});
  }

  /// Reagenda uma reserva
  static Future<Map<String, dynamic>> reagendarReserva({
    required int reservaId,
    required Map<String, dynamic> dados,
  }) async {
    return await ApiClient.put('/reservas/$reservaId/reagendar', dados);
  }
}

