# 🏃‍♀️ Pilates Center Management System

**로컬 네트워크 기반 필라테스/요가 센터 통합 관리 시스템**

> **0원 서버 운영비!** 센터 내부 Wi-Fi로 운영하는 완전한 멀티유저 시스템

---

## ✨ 주요 특징

### 💰 **완전 무료 운영**
- 클라우드 서버 비용 0원
- 월 운영비 0원
- 한 번 설치로 영구 사용

### 🏠 **로컬 네트워크 기반**
- 센터 내부 Wi-Fi로 운영
- 초고속 응답 속도
- 데이터 외부 유출 불가능
- 인터넷 없이도 동작

### 👥 **멀티유저 지원**
- **관리자(Master)**: 모든 권한, 센터 총괄 관리
- **강사(Instructor)**: 수업 스케줄 관리, 회원 조회
- **회원(Member)**: 예약/취소, 개인 정보 관리

### 📱 **크로스 플랫폼**
- **서버**: Node.js (Windows/Mac/Linux 지원)
- **클라이언트**: Flutter 앱 (Android/iOS/Web)

---

## 🏗️ 시스템 아키텍처

```
센터 내부 Wi-Fi 네트워크 (192.168.1.x)
┌─────────────────────────────┐
│      서버 PC (메인)          │  ← 192.168.1.100:3000
│  ✅ Node.js API Server      │
│  ✅ SQLite Database         │
│  ✅ 관리자 대시보드          │
│  ✅ 파일 스토리지            │
└─────────────────────────────┘
            ↕️ Wi-Fi 연결
┌─────────────────────────────┐
│        사용자 기기들         │
├─ 📱 강사 스마트폰 (앱)       │
├─ 📱 회원 스마트폰 (앱)       │
├─ 💻 데스크톱 (웹)           │
└─ 📱 태블릿 (웹/앱)          │
└─────────────────────────────┘
```

---

## 🚀 빠른 시작

> 💡 **처음 사용하는 경우:** 아래 단계를 순서대로 따라해주세요. 전체 설치 과정은 5-10분 소요됩니다.

### 1단계: 서버 설치 및 실행

**필수 요구사항 확인:**
- Node.js 18.0+ 설치 필수 ([다운로드](https://nodejs.org))
- npm 또는 yarn 설치

**서버 실행 방법:**
```bash
# 1. 프로젝트 루트 폴더로 이동
cd pilates_center_system

# 2. 서버 폴더로 이동
cd server

# 3. 의존성 설치 (최초 1회만)
npm install

# 4. 서버 실행
npm start
```

**간편 실행 (권장):**
```bash
# 프로젝트 루트에서 한 번에 실행
cd pilates_center_system/server && npm start
```

### 2단계: 서버 실행 확인

서버가 성공적으로 실행되면 다음과 같은 메시지가 표시됩니다:

```
🚀 =================================
🏃‍♀️ Pilates Center Server Started!
📍 Local: http://localhost:3000
🌐 Network: http://172.30.1.18:3000
📱 External Access: http://172.30.1.18:3000
🚀 =================================
```

**접속 주소:**
- **같은 컴퓨터**: http://localhost:3000
- **다른 기기**: http://[표시된-네트워크-IP]:3000

### 3단계: 관리자 로그인

**기본 관리자 계정**
- 📱 전화번호: `admin`
- 🔐 비밀번호: `admin123`

### 4단계: 서버 문제 해결

**서버가 시작되지 않을 때:**

1. **포트 충돌 확인**
   ```bash
   # 3000 포트 사용 중인 프로세스 확인
   lsof -i :3000          # macOS/Linux
   netstat -ano | findstr :3000    # Windows
   ```

2. **의존성 재설치**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Node.js 버전 확인**
   ```bash
   node --version    # v18.0.0 이상 필요
   npm --version
   ```

**외부에서 접속이 안 될 때:**

1. **방화벽 설정 확인**
   - Windows: Windows Defender 방화벽에서 3000 포트 허용
   - macOS: 시스템 환경설정 > 보안 및 개인정보보호 > 방화벽

2. **같은 Wi-Fi 네트워크 확인**
   - 서버 컴퓨터와 클라이언트 기기가 같은 Wi-Fi에 연결되어야 함

3. **IP 주소 확인**
   - 서버 시작 시 표시되는 Network IP 주소 사용

### 5단계: 클라이언트 실행 방법

**방법 1: 웹 브라우저에서 실행 (권장 - 관리자용)**
```bash
# 새 터미널 창에서
cd pilates_center_system/client
flutter run -d chrome
```

**방법 2: macOS 데스크톱 앱**
```bash
cd pilates_center_system/client
flutter run -d macos
```

**방법 3: 빌드된 앱 직접 실행**
```bash
# 앱 빌드
cd pilates_center_system/client
flutter build macos

# 앱 실행
open build/macos/Build/Products/Release/client.app
```

### 6단계: Android APK 생성 (선택사항)

Android 설치 파일을 생성하려면:

**자동 빌드 스크립트 사용**
```bash
# 프로젝트 루트에서
./build-apk.sh        # macOS/Linux
build-apk.bat         # Windows
```

**수동 빌드**
```bash
cd pilates_center_system/client
flutter clean
flutter pub get
flutter build apk --release
```

생성된 파일: `pilates-center-system.apk`

---

## 💻 상세 실행 가이드

### 🖥️ 터미널에서 서버 실행하기

**방법 1: 간단 실행**
```bash
cd pilates_center_system/server
npm start
```

**방법 2: 개발 모드 실행 (서버 수정 시 자동 재시작)**
```bash
cd pilates_center_system/server
npm run dev
```

**서버 정지하기**
- `Ctrl + C` (Windows/Linux)
- `Cmd + C` (macOS)

### 📱 터미널에서 클라이언트 실행하기

**웹 버전 (권장)**
```bash
# 새 터미널 창 열고
cd pilates_center_system/client
flutter run -d chrome
```

**macOS 앱**
```bash
cd pilates_center_system/client
flutter run -d macos
```

**앱 정지하기**
- Flutter 실행 중 터미널에서 `q` 입력 후 Enter
- 또는 `Ctrl + C`

### 🔄 동시 실행하기

**방법 1: 터미널 2개 사용**
```bash
# 터미널 1: 서버 실행
cd pilates_center_system/server && npm start

# 터미널 2: 클라이언트 실행  
cd pilates_center_system/client && flutter run -d chrome
```

**방법 2: 백그라운드 실행**
```bash
# 서버를 백그라운드에서 실행
cd pilates_center_system/server
npm start &

# 클라이언트 실행
cd ../client
flutter run -d chrome
```

### 🚨 실행 시 자주 발생하는 문제 해결

**1. "포트 3000이 이미 사용 중" 오류**
```bash
# 포트 사용 프로세스 찾기
lsof -i :3000              # macOS/Linux
netstat -ano | findstr :3000   # Windows

# 프로세스 종료 후 다시 실행
```

**2. "No internet connection" 오류**
- 서버가 실행 중인지 확인
- 클라이언트 실행 전에 서버 먼저 실행 필수

**3. Flutter 빌드 오류**
```bash
cd pilates_center_system/client
flutter clean
flutter pub get
flutter run -d chrome
```

**4. Node.js/npm 관련 오류**
```bash
# npm 캐시 정리
npm cache clean --force

# node_modules 재설치
rm -rf node_modules package-lock.json
npm install
```

---

## 🆕 최근 업데이트 (2025-09-10)

### ✅ **주요 개선사항**

#### 🔧 **관리자 계정 시스템 개선**
- **파일 기반 관리자 계정**: `config/admin.json`으로 관리자 계정 별도 보관
- **DB 초기화 시 관리자 계정 보존**: 데이터베이스 리셋해도 관리자 계정 손실 없음
- **서버 재시작 불필요**: DB 초기화 후 자동 연결 재설정으로 중단 없는 서비스

#### 🛠️ **시스템 안정성 강화**
- **자동 데이터베이스 재연결**: SQLITE_READONLY 오류 자동 해결
- **권한 시스템 개선**: 강사가 회원권 템플릿 조회 가능하도록 권한 확장
- **회원 스케줄 접근**: 회원이 강사/관리자 생성 스케줄 조회 가능

#### 🐛 **해결된 주요 버그**
1. **회원권 템플릿 로딩 오류**: 500 에러 해결 (데이터베이스 스키마 불일치 수정)
2. **회원 스케줄 접근 불가**: 권한 필터 수정으로 모든 공개 스케줄 조회 가능
3. **DB 초기화 후 SQLITE_READONLY**: 자동 연결 재설정으로 완전 해결
4. **강사 회원권 조회 불가**: requireStaff 권한으로 변경하여 해결

### 🎯 **현재 상태**
- ✅ 관리자 계정: **admin** / **admin123** (영구 보존)
- ✅ DB 초기화 시스템: 서버 재시작 없이 완전 동작
- ✅ 강사 권한: 스케줄 관리 + 회원권 조회 + 회원 관리
- ✅ 회원 권한: 모든 공개 스케줄 조회 + 예약 관리

### 🏗️ **기술적 개선사항**
- **환경변수 기반 관리자**: 파일 시스템으로 관리자 계정 분리
- **동적 권한 관리**: dataFilters를 통한 세밀한 권한 제어
- **자동 복구 시스템**: DB 연결 문제 시 자동 재연결
- **로깅 시스템**: 파일 기반 인증 로깅으로 추적성 향상

---

## 📊 기능 소개

### 🎯 **핵심 기능**

#### 👤 **회원 관리**
- 회원 등록/수정/삭제
- 회원권 관리 (개수형/기간형)
- 회원별 수강 이력
- 결제 내역 관리

#### 📅 **스케줄 관리**
- 수업 스케줄 등록
- 실시간 예약 현황
- 대기자 명단 관리
- 강사별 스케줄 관리

#### 💳 **예약 시스템**
- 실시간 예약/취소
- 자동 정원 관리
- 취소 규정 적용
- 노쇼 관리

#### 💰 **매출 관리**
- 실시간 매출 집계
- 기간별 매출 분석
- 결제 방법별 통계
- 수익 리포트

#### ⚙️ **설정 관리**
- 센터 기본 정보
- 영업 시간 설정
- 예약 규정 설정
- 사용자 권한 관리

### 📱 **사용자별 기능**

| 기능 | 관리자 | 강사 | 회원 |
|------|--------|------|------|
| 회원 관리 | ✅ | 📖 | ❌ |
| 강사 관리 | ✅ | ❌ | ❌ |
| 스케줄 관리 | ✅ | ✅ | ❌ |
| 예약 관리 | ✅ | ✅ | 본인만 |
| 매출 관리 | ✅ | ❌ | ❌ |
| 시스템 설정 | ✅ | ❌ | ❌ |

---

## 🛠️ 기술 스택

### **서버 (Backend)**
- **Node.js** + Express.js - API 서버
- **SQLite** - 로컬 데이터베이스
- **JWT** - 인증 시스템
- **bcrypt** - 비밀번호 암호화

### **클라이언트 (Frontend)**
- **Flutter** - 크로스 플랫폼 앱 개발
- **Material Design** - UI/UX
- **HTTP Client** - API 통신

---

## 📁 프로젝트 구조

```
pilates_center_system/
├── server/                 # Node.js 서버
│   ├── database/           # 데이터베이스 스키마 & 초기화
│   ├── routes/             # API 라우트
│   ├── uploads/            # 파일 업로드 저장소
│   └── index.js            # 서버 메인 파일
├── client/                 # Flutter 클라이언트 앱
│   ├── lib/
│   │   ├── core/           # 핵심 기능 (API, 인증 등)
│   │   ├── features/       # 기능별 페이지
│   │   ├── shared/         # 공통 컴포넌트
│   │   └── main.dart
│   └── pubspec.yaml
└── docs/                   # 문서
    ├── api-docs.md         # API 문서
    ├── user-guide.md       # 사용자 가이드
    └── installation.md     # 설치 가이드
```

---

## 🔧 상세 설치 가이드

### 필수 요구사항

**서버 PC**
- **운영체제**: Windows 10+ / macOS 10.15+ / Ubuntu 18.04+
- **Node.js**: v18.0.0 이상
- **메모리**: 4GB RAM 이상 권장
- **저장공간**: 1GB 이상

**클라이언트 기기**
- **스마트폰**: Android 6.0+ / iOS 12.0+
- **태블릿/PC**: 웹 브라우저 (Chrome, Safari, Edge)

### 네트워크 설정

1. **고정 IP 설정** (권장)
   - 서버 PC IP: `192.168.1.100` (고정)
   - 포트: `3000`

2. **Wi-Fi 공유기 설정**
   - SSID: 센터 전용 Wi-Fi
   - 모든 기기가 같은 네트워크에 연결

### 보안 설정

- 기본 관리자 비밀번호 변경 필수
- Wi-Fi 네트워크 보안 설정
- 정기적인 데이터 백업 권장

---

## 📖 API 문서

### 인증 (Authentication)

#### POST `/api/auth/login`
로그인

```json
{
  "phone": "admin",
  "password": "admin123"
}
```

#### GET `/api/auth/verify`
토큰 검증 (Header: `Authorization: Bearer <token>`)

### 사용자 관리

#### GET `/api/users`
사용자 목록 조회

#### POST `/api/users`
새 사용자 생성

#### GET `/api/users/:id`
특정 사용자 조회

### 스케줄 관리

#### GET `/api/schedules`
스케줄 목록 조회

#### POST `/api/schedules`
새 스케줄 생성

#### GET `/api/schedules/class-types`
수업 타입 목록

### 예약 관리

#### GET `/api/bookings`
예약 목록 조회

#### POST `/api/bookings`
새 예약 생성

#### PUT `/api/bookings/:id/cancel`
예약 취소

---

## 💼 비즈니스 모델

### 🎯 **타겟 고객**
- 소규모 필라테스/요가 스튜디오
- 개인 트레이너
- 소규모 피트니스 센터

### 💰 **수익 모델**
- **소프트웨어 라이선스**: ₩500,000 ~ ₩1,000,000
- **설치 서비스**: ₩100,000 ~ ₩300,000  
- **월 유지보수**: ₩30,000 ~ ₩50,000
- **커스터마이징**: 별도 견적

### 🏆 **경쟁 우위**
- **0원 운영비**: 클라우드 서버 비용 없음
- **데이터 보안**: 외부 유출 불가능
- **빠른 속도**: 로컬 네트워크로 초고속
- **쉬운 설치**: 더블클릭으로 설치 완료

---

## 🤝 기여 방법

1. 이슈 등록
2. 기능 제안
3. 버그 리포트
4. 코드 기여

---

## 📞 지원

- **이메일**: support@pilates-system.com
- **전화**: 02-1234-5678
- **운영시간**: 평일 09:00 ~ 18:00

---

## 📄 라이선스

이 프로젝트는 상용 소프트웨어입니다. 
라이선스 구매 없이는 상업적 사용이 제한됩니다.

---

**🏃‍♀️ 필라테스 센터의 디지털 전환, 지금 시작하세요!**