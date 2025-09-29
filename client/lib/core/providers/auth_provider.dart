import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/user.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  Future<void> checkAuthStatus() async {
    // SharedPreferences에서 토큰 로드
    await _loadStoredToken();
    
    // 저장된 토큰이 없으면 unauthenticated 상태로 설정
    if (_token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    
    try {
      final response = await _apiClient.verifyToken();
      final user = User.fromJson(response['user']);
      
      _status = AuthStatus.authenticated;
      _user = user;
      
      notifyListeners();
    } catch (e) {
      // 토큰이 유효하지 않을 때만 정리
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
      
      await _apiClient.clearToken();
      notifyListeners();
    }
  }
  
  Future<void> _loadStoredToken() async {
    // ApiClient에서 토큰을 로드하고 AuthProvider의 _token에도 저장
    _token = await _apiClient.loadToken();
  }

  Future<bool> login(String phone, String password) async {
    try {
      print('🔐 AuthProvider: 로그인 시작 - $phone');
      final response = await _apiClient.login(phone, password);
      print('🔐 AuthProvider: API 응답 받음 - $response');
      
      final loginResponse = LoginResponse.fromJson(response);
      print('🔐 AuthProvider: LoginResponse 파싱 완료');
      print('   - Token: ${loginResponse.token.substring(0, 20)}...');
      print('   - User: ${loginResponse.user.name} (${loginResponse.user.userType})');
      
      _status = AuthStatus.authenticated;
      _user = loginResponse.user;
      _token = loginResponse.token;
      
      print('🔐 AuthProvider: 상태 업데이트 완료 - authenticated');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('❌ AuthProvider: 로그인 실패');
      print('   - 에러: $e');
      print('   - 스택트레이스: $stackTrace');
      
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
      
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiClient.logout();
    
    _status = AuthStatus.unauthenticated;
    _user = null;
    _token = null;
    
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_user == null) return false;

    switch (permission) {
      case 'manage_users':
        return _user!.isMaster;
      case 'manage_schedules':
        return _user!.isMaster || _user!.isInstructor;
      case 'view_all_bookings':
        return _user!.isMaster || _user!.isInstructor;
      case 'manage_system':
        return _user!.isMaster;
      default:
        return false;
    }
  }
}