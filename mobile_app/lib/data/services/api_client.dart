import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String realDeviceHost = 'http://192.168.0.116:5050';
  static const String emulatorHost = 'http://10.0.2.2:5050';
  static const String localhostHost = 'http://localhost:5050';

  static String get baseHost {
    if (kIsWeb) return localhostHost;
    if (Platform.isAndroid) return realDeviceHost;
    return realDeviceHost;
  }

  static String get baseUrl => '$baseHost/api';

  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseHost$cleanPath';
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _headers();
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    List<File> files = const [],
    String fileFieldName = 'files',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);

    for (final file in files) {
      final multipartFile = await http.MultipartFile.fromPath(fileFieldName, file.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? decoded;
    }
    final errorBody = jsonDecode(response.body);
    throw Exception(errorBody['message'] ?? 'API error: ${response.statusCode}');
  }
}

