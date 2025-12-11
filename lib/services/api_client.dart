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
      
      // Verificar se a resposta é JSON antes de tentar decodificar
      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('application/json') && !contentType.contains('text/json')) {
        // Se não for JSON, pode ser HTML (erro 404) ou outro formato
        if (res.statusCode == 404) {
          return {
            'success': false,
            'error': 'Recurso não encontrado',
            'notFound': true,
          };
        }
        return {
          'success': false,
          'error': 'Resposta inválida do servidor (não é JSON)',
        };
      }
      
      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (e) {
        // Se falhar ao decodificar, pode ser HTML ou outro formato
        if (res.body.trim().startsWith('<!DOCTYPE') || res.body.trim().startsWith('<html')) {
          if (res.statusCode == 404) {
            return {
              'success': false,
              'error': 'Recurso não encontrado',
              'notFound': true,
            };
          }
          return {
            'success': false,
            'error': 'Servidor retornou HTML ao invés de JSON',
          };
        }
        rethrow;
      }
      
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      
      return {
        'success': false,
        'error': data is Map ? (data['message'] ?? 'Erro na requisição') : 'Erro na requisição',
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
      final url = '$baseUrl$endpoint';
      final headers = await _getHeaders();
      final bodyJson = jsonEncode(body);
      
      print('🔵 [ApiClient] POST $url');
      print('🔵 [ApiClient] Headers: $headers');
      print('🔵 [ApiClient] Body: $bodyJson');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: bodyJson,
      );

      print('🟢 [ApiClient] Status Code: ${response.statusCode}');
      print('🟢 [ApiClient] Response Body: ${response.body}');

      // Verificar se a resposta é JSON antes de tentar decodificar
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json') && !contentType.contains('text/json')) {
        // Se não for JSON, pode ser HTML (erro 404) ou outro formato
        if (response.statusCode == 404) {
          return {
            'success': false,
            'error': 'Rota não encontrada: $endpoint',
            'notFound': true,
          };
        }
        return {
          'success': false,
          'error': 'Resposta inválida do servidor (não é JSON)',
        };
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        // Se falhar ao decodificar, pode ser HTML ou outro formato
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          if (response.statusCode == 404) {
            return {
              'success': false,
              'error': 'Rota não encontrada: $endpoint',
              'notFound': true,
            };
          }
          return {
            'success': false,
            'error': 'Servidor retornou HTML ao invés de JSON',
          };
        }
        rethrow;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [ApiClient] Sucesso na requisição');
        return {'success': true, 'data': responseData};
      }

      print('❌ [ApiClient] Erro na requisição - Status: ${response.statusCode}');
      print('❌ [ApiClient] Erro message: ${responseData is Map ? responseData['message'] : 'Erro desconhecido'}');
      
      return {
        'success': false,
        'error': responseData is Map ? (responseData['message'] ?? 'Erro na requisição') : 'Erro na requisição',
      };
    } catch (e, stackTrace) {
      print('🔴 [ApiClient] Exceção na requisição POST:');
      print('🔴 [ApiClient] Erro: $e');
      print('🔴 [ApiClient] Tipo: ${e.runtimeType}');
      print('🔴 [ApiClient] StackTrace: $stackTrace');
      
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
