import '../api_client.dart';

/// Repository para dados do dashboard e relatórios
class DashboardRepository {
  /// Busca resumo do dashboard
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    return await ApiClient.get('/relatorios/dashboard');
  }

  /// Busca relatório de reservas por período
  static Future<Map<String, dynamic>> getRelatorioReservas({
    required String dataInicio,
    required String dataFim,
  }) async {
    return await ApiClient.get(
      '/relatorios/reservas?dataInicio=$dataInicio&dataFim=$dataFim',
    );
  }
}

