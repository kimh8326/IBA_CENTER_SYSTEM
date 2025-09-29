# 배포 시나리오 가이드

## 🏢 시나리오 1: 필라테스 센터 내부 배포 (권장)

### 서버 설정
```bash
# 고정 IP 설정: 192.168.1.100
# 서버 실행
cd server
npm start
```

### 클라이언트 설정
```dart
// lib/core/config/app_config.dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api';  // 웹은 서버 PC에서
  } else {
    return 'http://192.168.1.100:3000/api';  // 앱은 네트워크 IP
  }
}
```

### 배포 파일
- **서버 PC**: 웹 버전 자동 실행
- **Android**: pilates-center-system.apk 배포
- **iOS**: App Store 또는 TestFlight 배포

---

## ☁️ 시나리오 2: 클라우드 서버 배포

### 서버 배포
```bash
# Heroku, AWS, Google Cloud 등
# 환경변수 설정
DATABASE_URL=postgresql://...
PORT=80 또는 443
```

### 클라이언트 설정
```dart
static String get baseUrl {
  return 'https://pilates-api.yourdomain.com/api';
}
```

---

## 🔄 시나리오 3: 하이브리드 배포

### 로컬 + 클라우드 백업
- **기본**: 로컬 네트워크 사용
- **백업**: 인터넷 연결 시 클라우드 동기화

---

## 🧪 배포 테스트 방법

### 1. 네트워크 테스트
```bash
# 같은 Wi-Fi에서 다른 기기로 접속 테스트
curl http://192.168.1.100:3000/api/health

# 외부 인터넷에서 접속 테스트 (포트포워딩 필요)
curl http://your-public-ip:3000/api/health
```

### 2. 다중 기기 테스트
- [ ] 강사 스마트폰에서 접속
- [ ] 회원 태블릿에서 접속  
- [ ] 데스크톱에서 관리자 접속
- [ ] 동시 접속 (10+ 기기) 테스트

### 3. 성능 테스트
```bash
# 동시 접속 부하 테스트
ab -n 100 -c 10 http://192.168.1.100:3000/api/health
```

---

## 📋 배포 체크리스트

### 서버 측
- [ ] 고정 IP 주소 설정
- [ ] 방화벽 포트 3000 허용
- [ ] 자동 시작 서비스 등록
- [ ] SSL 인증서 설정 (HTTPS)
- [ ] 데이터 백업 설정

### 클라이언트 측
- [ ] 프로덕션 빌드 생성
- [ ] API URL 프로덕션용으로 변경
- [ ] 앱 스토어 배포 (선택)
- [ ] 사용자 교육 자료 준비

### 네트워크 측
- [ ] Wi-Fi 안정성 확인
- [ ] 대역폭 충분성 확인
- [ ] 인터넷 백업 연결 설정