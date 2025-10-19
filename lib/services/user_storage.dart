class UserStorage {
  // Implementação temporária usando variáveis estáticas
  static Map<String, dynamic>? _userData;

  /// Salva os dados do usuário logado
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      _userData = userData;
      print('Dados do usuário salvos: $userData');
    } catch (e) {
      print('Erro ao salvar dados do usuário: $e');
    }
  }

  /// Recupera os dados do usuário logado
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      return _userData;
    } catch (e) {
      print('Erro ao recuperar dados do usuário: $e');
      return null;
    }
  }

  /// Recupera apenas o nome do usuário
  static Future<String> getUserName() async {
    try {
      if (_userData != null) {
        print('DEBUG: Estrutura completa dos dados: $_userData');

        // Se não encontrou nos campos diretos, tenta dentro do objeto 'user'
        if (_userData!['user'] != null) {
          final user = _userData!['user'] as Map<String, dynamic>;
          print('DEBUG: Dados do user: $user');
          final userName = user['name'] ??
              user['nome'] ??
              user['userName'] ??
              user['nomeCompleto'] ??
              'Usuário';
          print('DEBUG: Nome extraído: $userName');
          return userName;
        }

        // Primeiro tenta campos diretos (fallback)
        if (_userData!['name'] != null) {
          return _userData!['name'];
        }
        if (_userData!['nome'] != null) {
          return _userData!['nome'];
        }
        if (_userData!['userName'] != null) {
          return _userData!['userName'];
        }
        if (_userData!['nomeCompleto'] != null) {
          return _userData!['nomeCompleto'];
        }

        return 'Usuário';
      }
      return 'Usuário';
    } catch (e) {
      print('Erro ao recuperar nome do usuário: $e');
      return 'Usuário';
    }
  }

  /// Recupera a role do usuário
  static Future<String?> getUserRole() async {
    try {
      if (_userData != null) {
        // Primeiro tenta campos diretos
        if (_userData!['role'] != null) {
          return _userData!['role'].toString();
        }

        // Se não encontrou nos campos diretos, tenta dentro do objeto 'user'
        if (_userData!['user'] != null) {
          final user = _userData!['user'] as Map<String, dynamic>;
          return user['role']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar role do usuário: $e');
      return null;
    }
  }

  /// Verifica se o usuário é ADMIN
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toUpperCase() == 'ADMIN';
  }

  /// Remove os dados do usuário (logout)
  static Future<void> clearUserData() async {
    try {
      _userData = null;
      print('Dados do usuário removidos');
    } catch (e) {
      print('Erro ao limpar dados do usuário: $e');
    }
  }
}
