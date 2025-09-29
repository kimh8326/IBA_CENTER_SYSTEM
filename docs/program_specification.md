# 필라테스 센터 관리 시스템 프로그램 명세서

## 문서 정보
- **시스템명**: 필라테스 센터 관리 시스템 (Pilates Center Management System)
- **버전**: 1.0.0
- **작성일**: 2025-09-03
- **작성자**: Claude AI
- **문서 목적**: 개발된 프로그램 모듈의 상세 명세 정의

---

## 1. 프로그램 목록 개요

| 프로그램 ID | 프로그램명 | 화면 ID | 파일 위치 | 개발자 | 완료일 |
|------------|-----------|--------|----------|--------|--------|
| PG-PC-001 | 로그인 관리 | SCR-PC-001 | `/features/auth/login_screen.dart` | Claude | 2025-09-03 |
| PG-PC-002 | 대시보드 | SCR-PC-002 | `/features/dashboard/dashboard_screen.dart` | Claude | 2025-09-03 |
| PG-PC-003 | 스케줄 관리 | SCR-PC-003 | `/features/schedules/schedule_list_screen.dart` | Claude | 2025-09-03 |
| PG-PC-004 | 예약 관리 | SCR-PC-004 | `/features/bookings/booking_list_screen.dart` | Claude | 2025-09-03 |
| PG-PC-005 | 회원 관리 | SCR-PC-005 | `/features/users/user_list_screen.dart` | Claude | 2025-09-03 |
| PG-PC-006 | 인증 API | API-PC-001 | `/server/routes/auth.js` | Claude | 2025-09-03 |
| PG-PC-007 | 사용자 API | API-PC-002 | `/server/routes/users.js` | Claude | 2025-09-03 |
| PG-PC-008 | 스케줄 API | API-PC-003 | `/server/routes/schedules.js` | Claude | 2025-09-03 |
| PG-PC-009 | 예약 API | API-PC-004 | `/server/routes/bookings.js` | Claude | 2025-09-03 |
| PG-PC-010 | 데이터베이스 관리 | DB-PC-001 | `/server/database/init.js` | Claude | 2025-09-03 |

---

## 2. 프로그램 상세 명세

### 2.1 클라이언트 프로그램

#### **PG-PC-001: 로그인 관리**
- **프로그램명**: 로그인 화면 (Login Screen)
- **개요**: JWT 토큰 기반 사용자 인증 처리
- **처리 로직**:
  1. 사용자 전화번호/비밀번호 입력 받기
  2. API 클라이언트를 통해 서버에 로그인 요청
  3. JWT 토큰 수신 시 로컬 스토리지에 저장
  4. 인증 성공 시 대시보드로 화면 전환
  5. 실패 시 오류 메시지 표시
- **관련 테이블**: users
- **입력 데이터**: phone (전화번호), password (비밀번호)
- **출력 데이터**: JWT token, 사용자 정보
- **프로그램 위치**: `lib/features/auth/login_screen.dart`

#### **PG-PC-002: 대시보드**
- **프로그램명**: 메인 대시보드 (Dashboard Screen)
- **개요**: 시스템 전체 현황 및 빠른 액션 제공
- **처리 로직**:
  1. 로그인된 사용자 정보 표시
  2. 오늘의 스케줄 목록 조회 및 표시
  3. 사용자 역할에 따른 빠른 액션 버튼 제공
  4. 하단 탭 네비게이션을 통한 화면 전환
  5. 로그아웃 기능 제공
- **관련 테이블**: schedules, class_types, users
- **입력 데이터**: 현재 날짜, 사용자 정보
- **출력 데이터**: 오늘의 스케줄, 사용자 현황
- **프로그램 위치**: `lib/features/dashboard/dashboard_screen.dart`

#### **PG-PC-003: 스케줄 관리**
- **프로그램명**: 스케줄 목록 화면 (Schedule List Screen)
- **개요**: 수업 스케줄 조회 및 예약 현황 관리
- **처리 로직**:
  1. 날짜 선택을 통한 스케줄 필터링
  2. 선택된 날짜의 스케줄 목록 조회
  3. 각 스케줄별 예약 현황 표시
  4. 회원은 예약 가능한 수업에 예약 요청
  5. 관리자/강사는 예약 현황 상세 조회
- **관련 테이블**: schedules, class_types, users, bookings
- **입력 데이터**: 선택 날짜, 필터 조건
- **출력 데이터**: 스케줄 목록, 예약 현황
- **프로그램 위치**: `lib/features/schedules/schedule_list_screen.dart`

#### **PG-PC-004: 예약 관리**
- **프로그램명**: 예약 목록 화면 (Booking List Screen)
- **개요**: 예약 현황 조회 및 취소 처리
- **처리 로직**:
  1. 사용자 역할에 따른 예약 목록 조회 (회원: 본인, 관리자/강사: 전체)
  2. 예약 상태별 필터링 (전체, 확정, 취소)
  3. 활성 예약에 대한 취소 처리
  4. 취소 사유 입력 및 서버 전송
  5. 예약 정보 상세 표시
- **관련 테이블**: bookings, schedules, class_types, users
- **입력 데이터**: 사용자 ID, 필터 조건, 취소 사유
- **출력 데이터**: 예약 목록, 예약 상세 정보
- **프로그램 위치**: `lib/features/bookings/booking_list_screen.dart`

#### **PG-PC-005: 회원 관리**
- **프로그램명**: 회원 목록 화면 (User List Screen)
- **개요**: 회원/강사 정보 조회 및 관리 (관리자/강사 전용)
- **처리 로직**:
  1. 사용자 타입별 필터링 (전체, 회원, 강사)
  2. 사용자 목록 조회 및 표시
  3. 각 사용자의 기본 정보 및 상태 표시
  4. 관리자는 사용자 수정/비활성화 가능
  5. 사용자 상세 정보 조회
- **관련 테이블**: users, member_profiles, instructor_profiles
- **입력 데이터**: 필터 조건, 사용자 타입
- **출력 데이터**: 사용자 목록, 사용자 상세 정보
- **프로그램 위치**: `lib/features/users/user_list_screen.dart`

---

### 2.2 서버 API 프로그램

#### **PG-PC-006: 인증 API**
- **프로그램명**: 사용자 인증 API (Authentication API)
- **개요**: JWT 기반 로그인/인증 처리
- **처리 로직**:
  1. 로그인 요청 시 전화번호/비밀번호 검증
  2. bcrypt를 통한 비밀번호 해시 검증
  3. JWT 토큰 생성 및 반환
  4. 토큰 검증 미들웨어 제공
  5. 로그인 활동 로그 기록
- **관련 테이블**: users, activity_logs
- **API 엔드포인트**: 
  - `POST /api/auth/login`
  - `GET /api/auth/verify`
- **프로그램 위치**: `server/routes/auth.js`

#### **PG-PC-007: 사용자 API**
- **프로그램명**: 사용자 관리 API (User Management API)
- **개요**: 사용자 CRUD 및 프로필 관리
- **처리 로직**:
  1. 권한별 사용자 목록 조회 (페이징 지원)
  2. 사용자 타입별 필터링 (관리자, 강사, 회원)
  3. 새 사용자 생성 (관리자 전용)
  4. 사용자 정보 수정 (본인 또는 관리자)
  5. 프로필 정보 연동 관리
- **관련 테이블**: users, member_profiles, instructor_profiles, activity_logs
- **API 엔드포인트**:
  - `GET /api/users`
  - `GET /api/users/:id`
  - `POST /api/users`
  - `PUT /api/users/:id`
- **프로그램 위치**: `server/routes/users.js`

#### **PG-PC-008: 스케줄 API**
- **프로그램명**: 스케줄 관리 API (Schedule Management API)
- **개요**: 수업 스케줄 조회 및 생성
- **처리 로직**:
  1. 날짜/강사/수업타입별 스케줄 조회
  2. 스케줄과 관련 정보 조인 조회
  3. 새 스케줄 생성 (관리자/강사 전용)
  4. 수업 타입 목록 조회
  5. 현재 예약 인원 실시간 반영
- **관련 테이블**: schedules, class_types, users, activity_logs
- **API 엔드포인트**:
  - `GET /api/schedules`
  - `POST /api/schedules`
  - `GET /api/schedules/class-types`
- **프로그램 위치**: `server/routes/schedules.js`

#### **PG-PC-009: 예약 API**
- **프로그램명**: 예약 관리 API (Booking Management API)
- **개요**: 수업 예약 생성, 조회, 취소 처리
- **처리 로직**:
  1. 사용자별/스케줄별 예약 목록 조회
  2. 새 예약 생성 및 정원 확인
  3. 중복 예약 방지 검증
  4. 예약 취소 및 정원 업데이트
  5. 예약 관련 활동 로그 기록
- **관련 테이블**: bookings, schedules, users, class_types, activity_logs
- **API 엔드포인트**:
  - `GET /api/bookings`
  - `POST /api/bookings`
  - `PUT /api/bookings/:id/cancel`
- **프로그램 위치**: `server/routes/bookings.js`

#### **PG-PC-010: 데이터베이스 관리**
- **프로그램명**: 데이터베이스 초기화 관리 (Database Initialization)
- **개요**: SQLite 데이터베이스 연결 및 스키마 관리
- **처리 로직**:
  1. SQLite 데이터베이스 연결 설정
  2. 스키마 파일 기반 테이블 생성
  3. 기본 데이터 삽입 (관리자 계정, 수업 타입 등)
  4. 데이터베이스 쿼리 실행 메서드 제공
  5. 연결 종료 및 리소스 해제
- **관련 테이블**: 전체 테이블 (13개)
- **주요 메서드**:
  - `initialize()`: DB 초기화
  - `getQuery()`: 단일 레코드 조회
  - `getAllQuery()`: 다중 레코드 조회
  - `runQuery()`: DML 실행
- **프로그램 위치**: `server/database/init.js`

---

## 3. 프로그램 간 연관관계

```
┌─────────────────┐    JWT 토큰    ┌─────────────────┐
│   로그인 화면    │ ──────────────→ │   인증 API      │
│   (PG-PC-001)   │               │   (PG-PC-006)   │
└─────────────────┘               └─────────────────┘
         │                                 │
         ▼                                 ▼
┌─────────────────┐                ┌─────────────────┐
│   대시보드       │                │ 데이터베이스 관리 │
│   (PG-PC-002)   │                │   (PG-PC-010)   │
└─────────────────┘                └─────────────────┘
         │                                 ▲
         ▼                                 │
┌─────────────────┐    API 호출     ┌─────────────────┐
│ 스케줄/예약/회원 │ ──────────────→ │ 각종 API 모듈    │
│ 관리 화면들      │               │ (PG-PC-007~009) │
└─────────────────┘               └─────────────────┘
```

---

## 4. 개발 환경 및 기술 스택

### 클라이언트 (Flutter)
- **언어**: Dart
- **프레임워크**: Flutter 3.x
- **상태 관리**: Provider
- **HTTP 클라이언트**: http package
- **로컬 저장소**: shared_preferences

### 서버 (Node.js)
- **언어**: JavaScript (ES6+)
- **런타임**: Node.js v18+
- **프레임워크**: Express.js
- **데이터베이스**: SQLite
- **인증**: JWT (jsonwebtoken)
- **암호화**: bcrypt

---

## 5. 배포 및 운영

### 시스템 요구사항
- **서버**: Node.js 18.0+ 설치 필요
- **데이터베이스**: SQLite (파일 기반, 별도 설치 불요)
- **네트워크**: 로컬 Wi-Fi 환경 (192.168.1.x)
- **클라이언트**: 웹 브라우저 (Chrome, Safari, Edge 권장)

### 실행 방법
1. **서버 실행**: `npm start` (포트 3000)
2. **클라이언트 실행**: `flutter run -d web-server` (포트 8080)
3. **기본 계정**: admin / admin123

---

*본 명세서는 필라테스 센터 관리 시스템의 프로그램 구조와 기능을 상세히 기술하여, 향후 유지보수 및 기능 개선 시 참고 자료로 활용하기 위해 작성되었습니다.*