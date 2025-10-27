import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String baseUrl = 'https://pinheiro-society-api.vercel.app';
  static const String baseUrl = 'http://localhost:3000';

  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Realiza o login do usuário
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Erro no login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Realiza o cadastro do usuário
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Erro no cadastro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Verifica se a API está funcionando
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ----- Relatórios / Dashboard -----
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/relatorios/dashboard'),
        headers: _headers,
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar dashboard'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getRelatorioReservas(
      {required String dataInicio, required String dataFim}) async {
    try {
      final uri =
          Uri.parse('$baseUrl/relatorios/reservas').replace(queryParameters: {
        'dataInicio': dataInicio,
        'dataFim': dataFim,
      });
      final res = await http.get(uri, headers: _headers);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar reservas'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getClientes() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/clientes'), headers: _headers);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar clientes'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> buscarClientes(String query) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/clientes/buscar?q=$query'),
        headers: _headers,
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao buscar clientes'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getQuadras() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/quadras'), headers: _headers);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar quadras'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getDisponibilidadeQuadra(
      {required int quadraId, required String data}) async {
    try {
      final uri = Uri.parse('$baseUrl/quadras/$quadraId/disponibilidade')
          .replace(queryParameters: {
        'data': data,
      });
      final res = await http.get(uri, headers: _headers);
      final dataJson = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': dataJson};
      }
      return {
        'success': false,
        'error': dataJson['message'] ?? 'Erro ao carregar disponibilidade'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getReservas() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/reservas'), headers: _headers);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar reservas'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createCliente({
    required String nomeCompleto,
    required String cpf,
    required String email,
    required String telefone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clientes'),
        headers: _headers,
        body: jsonEncode({
          'nomeCompleto': nomeCompleto,
          'cpf': cpf,
          'email': email,
          'telefone': telefone,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ??
            responseData['error'] ??
            'Erro no cadastro do cliente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateCliente({
    required String id,
    required String nomeCompleto,
    required String cpf,
    required String email,
    required String telefone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/clientes/$id'),
        headers: _headers,
        body: jsonEncode({
          'id': id,
          'nomeCompleto': nomeCompleto,
          'cpf': cpf,
          'email': email,
          'telefone': telefone,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ??
            responseData['error'] ??
            'Erro na atualização do cliente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteCliente(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/clientes/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ??
            responseData['error'] ??
            'Erro ao deletar cliente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Busca mesas ativas/abertas
  static Future<Map<String, dynamic>> getMesasAbertas() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/mesas?ativa=true'),
        headers: _headers,
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['message'] ?? 'Erro ao carregar mesas abertas'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }
}
