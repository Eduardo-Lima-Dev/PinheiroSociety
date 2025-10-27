import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP centralizado para todas as requisições
class ApiClient {
  // static const String baseUrl = 'https://pinheiro-society-api.vercel.app';
  static const String baseUrl = 'http://localhost:3000';

  /// Headers padrão para as requisições
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Realiza requisição GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      
      return {
        'success': false,
        'error': data['message'] ?? 'Erro na requisição'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Realiza requisição POST
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Erro na requisição',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Realiza requisição PUT
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Erro na requisição',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Realiza requisição DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Erro na requisição',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Verifica se a API está funcionando
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

