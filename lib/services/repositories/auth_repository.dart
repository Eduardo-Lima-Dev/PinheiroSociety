import '../api_client.dart';

/// Repository para autenticação e gerenciamento de usuários
class AuthRepository {
  /// Realiza o login do usuário
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  /// Realiza o cadastro de novo usuário
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String cpf,
    required String password,
    required String role,
    required String status,
  }) async {
    return await ApiClient.post('/users', {
      'name': name,
      'email': email,
      'cpf': cpf,
      'password': password,
      'role': role,
      'status': status,
    });
  }

  /// Lista todos os usuários (sem paginação) - usado para métricas
  static Future<Map<String, dynamic>> fetchUsers() async {
    return await ApiClient.get('/users');
  }

  /// Busca usuários com paginação e filtros
  static Future<Map<String, dynamic>> searchUsers({
    String? query,
    String? status,
    required int page,
    required int pageSize,
  }) async {
    final possuiFiltro = (query != null && query.isNotEmpty) ||
        (status != null && status.isNotEmpty);

    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    if (!possuiFiltro) {
      // API ainda não suporta paginação nativa para /users; retornamos lista completa
      return await fetchUsers();
    }

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/users/search?$queryString');
  }

  /// Mantido por compatibilidade
  static Future<Map<String, dynamic>> getUsers() async {
    return await fetchUsers();
  }

  static Future<Map<String, dynamic>> deleteUser(String id) async {
    return await ApiClient.delete('/users/$id');
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String name,
    required String email,
    required String cpf,
    required String role,
    required String status,
    String? password,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'cpf': cpf,
      'role': role,
      'status': status,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    return await ApiClient.put('/users/$id', body);
  }
}
