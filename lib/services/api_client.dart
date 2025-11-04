import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_storage.dart';

/// Cliente HTTP centralizado para todas as requisições
class ApiClient {
  // static const String baseUrl = 'https://pinheiro-society-api.vercel.app';
  static const String baseUrl = 'http://localhost:3000';

  /// Headers padrão para as requisições
  static Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Monta headers com token de autenticação (se disponível)
  static Future<Map<String, String>> _getHeaders() async {
    final headers = Map<String, String>.from(_baseHeaders);
    final token = await UserStorage.getToken();
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// Realiza requisição GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
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
      final headers = await _getHeaders();
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
      final headers = await _getHeaders();
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
      final headers = await _getHeaders();
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

  /// Verifica se a API está funcionando (sem autenticação)
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _baseHeaders, // Usa headers base sem autenticação
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

