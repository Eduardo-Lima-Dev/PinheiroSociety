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
}

