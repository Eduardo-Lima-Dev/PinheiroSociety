import '../api_client.dart';

class RelatorioRepository {
  /// Busca relatório de faturamento
  static Future<Map<String, dynamic>> getFaturamento({
    required String dataInicio,
    required String dataFim,
  }) async {
    return await ApiClient.get(
      '/relatorios/faturamento?dataInicio=$dataInicio&dataFim=$dataFim',
    );
  }

  /// Busca relatório de estoque
  static Future<Map<String, dynamic>> getEstoque() async {
    return await ApiClient.get('/relatorios/estoque');
  }

  /// Busca relatório de reservas
  static Future<Map<String, dynamic>> getReservas({
    required String dataInicio,
    required String dataFim,
  }) async {
    return await ApiClient.get(
      '/relatorios/reservas?dataInicio=$dataInicio&dataFim=$dataFim',
    );
  }

  /// Busca relatório de clientes
  static Future<Map<String, dynamic>> getClientes({
    String? dataInicio,
    String? dataFim,
  }) async {
    String query = '';
    if (dataInicio != null && dataFim != null) {
      query = '?dataInicio=$dataInicio&dataFim=$dataFim';
    }
    return await ApiClient.get('/relatorios/clientes$query');
  }
}
