import '../api_client.dart';

/// Repository para operações de mesas
class MesaRepository {
  /// Busca mesas ativas/abertas
  static Future<Map<String, dynamic>> getMesasAbertas() async {
    return await ApiClient.get('/mesas?ativa=true');
  }

  /// Busca todas as mesas
  static Future<Map<String, dynamic>> getMesas() async {
    return await ApiClient.get('/mesas');
  }
}

