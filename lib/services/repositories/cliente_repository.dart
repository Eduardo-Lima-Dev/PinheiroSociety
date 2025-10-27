import '../api_client.dart';

/// Repository para operações de clientes
class ClienteRepository {
  /// Busca todos os clientes
  static Future<Map<String, dynamic>> getClientes() async {
    return await ApiClient.get('/clientes');
  }

  /// Busca clientes por query
  static Future<Map<String, dynamic>> buscarClientes(String query) async {
    return await ApiClient.get('/clientes/buscar?q=$query');
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

