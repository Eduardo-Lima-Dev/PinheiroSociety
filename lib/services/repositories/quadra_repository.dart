import '../api_client.dart';

/// Repository para operações de quadras e reservas
class QuadraRepository {
  /// Busca todas as quadras (sem paginação) - usado para métricas
  static Future<Map<String, dynamic>> getQuadras() async {
    return await ApiClient.get('/quadras');
  }

  /// Busca quadras com paginação e filtros
  static Future<Map<String, dynamic>> buscarQuadras({
    String? query,
    bool? ativa,
    required int page,
    required int pageSize,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }

    if (ativa != null) {
      params['ativa'] = ativa.toString();
    }

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/quadras?$queryString');
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

  /// Cria uma nova quadra
  static Future<Map<String, dynamic>> criarQuadra({
    required String nome,
    required bool ativa,
  }) async {
    return await ApiClient.post('/quadras', {
      'nome': nome,
      'ativa': ativa,
    });
  }

  /// Atualiza dados de uma quadra
  static Future<Map<String, dynamic>> atualizarQuadra({
    required int quadraId,
    required String nome,
    required bool ativa,
  }) async {
    return await ApiClient.put('/quadras/$quadraId', {
      'nome': nome,
      'ativa': ativa,
    });
  }

  /// Remove uma quadra
  static Future<Map<String, dynamic>> deletarQuadra({
    required int quadraId,
  }) async {
    return await ApiClient.delete('/quadras/$quadraId');
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
  static Future<Map<String, dynamic>> criarReserva(
      Map<String, dynamic> dados) async {
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
