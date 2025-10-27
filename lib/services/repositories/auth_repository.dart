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
    required String password,
    required String role,
  }) async {
    return await ApiClient.post('/users', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }
}

