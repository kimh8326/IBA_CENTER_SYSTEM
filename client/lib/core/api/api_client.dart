import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _tokenKey = 'auth_token';
  static const String _serverUrlKey = 'server_url';

  // 서버 URL을 SharedPreferences에서 읽어오기
  static Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_serverUrlKey);

    // 저장된 URL이 있으면 사용, 없으면 기본값
    final url = savedUrl ?? (kDebugMode
        ? 'http://localhost:3000'  // 개발 중 기본값
        : 'http://192.168.0.20:3000'); // 프로덕션 기본값

    print('🌐 API_CLIENT: 현재 플랫폼=${kIsWeb ? "Web" : "Mobile"}, 디버그=${kDebugMode}, URL=$url/api');
    return '$url/api';
  }

  // 서버 URL 저장
  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // /api 제거하고 저장
    final cleanUrl = url.replaceAll('/api', '').replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_serverUrlKey, cleanUrl);
    print('💾 API_CLIENT: 서버 URL 저장됨: $cleanUrl');
  }

  // 서버 URL 조회
  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }

  final http.Client _client = http.Client();
  String? _authToken;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> _loadToken() async {
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
    }
  }

  // AuthProvider에서 사용할 public 메서드
  Future<String?> loadToken() async {
    await _loadToken();
    return _authToken;
  }

  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> data;

    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Invalid response format', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['message'] ?? 'Unknown error occurred',
        response.statusCode,
        data['error'],
      );
    }
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    await _loadToken();

    try {
      final base = await baseUrl;
      var uri = Uri.parse('$base$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      );

      return await _handleResponse(response);
    } on http.ClientException {
      throw ApiException('No internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e', 0);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    if (includeAuth) await _loadToken();

    try {
      final base = await baseUrl;
      final url = Uri.parse('$base$endpoint');
      final headers = _getHeaders(includeAuth: includeAuth);
      final body = json.encode(data);

      // 디버그 정보 출력
      print('🌐 API POST Request:');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: $body');

      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      print('📥 API Response:');
      print('   Status: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      return await _handleResponse(response);
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw ApiException('No internet connection', 0);
    } catch (e) {
      print('❌ Request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e', 0);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await _loadToken();

    try {
      final base = await baseUrl;
      final response = await _client.put(
        Uri.parse('$base$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      return await _handleResponse(response);
    } on http.ClientException {
      throw ApiException('No internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e', 0);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    await _loadToken();

    try {
      final base = await baseUrl;
      final response = await _client.delete(
        Uri.parse('$base$endpoint'),
        headers: _getHeaders(),
      );

      return await _handleResponse(response);
    } on http.ClientException {
      throw ApiException('No internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e', 0);
    }
  }

  // 인증 관련 메서드들
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await post('/auth/login', {
      'phone': phone,
      'password': password,
    }, includeAuth: false);

    if (response['token'] != null) {
      await _saveToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> verifyToken() async {
    return await get('/auth/verify');
  }

  Future<void> logout() async {
    await clearToken();
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;

  ApiException(this.message, this.statusCode, [this.errorCode]);

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}