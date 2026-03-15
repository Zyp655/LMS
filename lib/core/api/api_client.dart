import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../error/exceptions.dart';
import 'api_constants.dart';

class ApiClient {
  final http.Client client;
  SharedPreferences? _prefs;

  ApiClient({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    _prefs ??= await SharedPreferences.getInstance();
    final token = _prefs!.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
    );
    return _processResponse(response);
  }

  Future<dynamic> post(String path, dynamic body) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String path, dynamic body) async {
    final headers = await _getHeaders();
    final response = await client.put(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final headers = await _getHeaders();
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        return response.body;
      }
    } else {
      try {
        final errorMap = jsonDecode(utf8.decode(response.bodyBytes));
        throw ServerException(
          errorMap['error'] ?? errorMap['message'] ?? 'Unknown Error',
          statusCode: response.statusCode,
        );
      } on ServerException {
        rethrow;
      } catch (_) {
        throw ServerException(
          'Lỗi máy chủ: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    }
  }
}
