import 'package:flutter/foundation.dart';

class AppConfig {
  // 환경별 서버 URL 설정
  static const String _devBaseUrl = 'http://localhost:3000/api';
  static const String _stagingBaseUrl = 'https://pilates-staging.yourdomain.com/api';
  static const String _prodBaseUrl = 'https://pilates.yourdomain.com/api';
  static const String _localNetworkUrl = 'http://192.168.1.100:3000/api';
  
  // 배포 환경 설정
  static const AppEnvironment environment = AppEnvironment.development;
  
  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.development:
        return _devBaseUrl;
      case AppEnvironment.staging:
        return _stagingBaseUrl;
      case AppEnvironment.production:
        // 프로덕션에서도 로컬 네트워크 사용 (필라테스 센터 특성)
        return kIsWeb ? _devBaseUrl : _localNetworkUrl;
      case AppEnvironment.cloud:
        return _prodBaseUrl;
    }
  }
  
  // 디버그 모드 여부
  static bool get isDebugMode => kDebugMode;
  
  // 로컬 네트워크 모드 여부
  static bool get isLocalNetwork => environment == AppEnvironment.production;
}

enum AppEnvironment {
  development,
  staging, 
  production,  // 로컬 네트워크 배포
  cloud,       // 클라우드 배포
}