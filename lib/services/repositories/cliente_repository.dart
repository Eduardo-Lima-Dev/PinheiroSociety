import '../api_client.dart';

/// Repository para operações de clientes
class ClienteRepository {
  /// Busca todos os clientes (sem paginação) - usado para métricas
  static Future<Map<String, dynamic>> getClientes() async {
    return await ApiClient.get('/clientes');
  }

  /// Busca clientes com paginação e filtros
  static Future<Map<String, dynamic>> buscarClientes({
    String? query,
    required int page,
    required int pageSize,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) {
      final queryString = Uri(queryParameters: {
        'q': query,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      }).query;
      return await ApiClient.get('/clientes/buscar?$queryString');
    }

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/clientes?$queryString');
  }

  /// Cria novo cliente
  static Future<Map<String, dynamic>> createCliente({
    required String nomeCompleto,
    required String cpf,
    required String email,
    required String telefone,
  }) async {
    return await ApiClient.post('/clientes', {
      'nomeCompleto': nomeCompleto,
      'cpf': cpf,
      'email': email,
      'telefone': telefone,
    });
  }

  /// Atualiza cliente existente
  static Future<Map<String, dynamic>> updateCliente({
    required String id,
    required String nomeCompleto,
    required String cpf,
    required String email,
    required String telefone,
  }) async {
    return await ApiClient.put('/clientes/$id', {
      'id': id,
      'nomeCompleto': nomeCompleto,
      'cpf': cpf,
      'email': email,
      'telefone': telefone,
    });
  }

  /// Deleta cliente
  static Future<Map<String, dynamic>> deleteCliente(String id) async {
    return await ApiClient.delete('/clientes/$id');
  }
}
