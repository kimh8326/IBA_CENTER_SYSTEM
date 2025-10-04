# 변경 로그

모든 주요 변경사항은 이 파일에 문서화됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/)를 기반으로 하며,
이 프로젝트는 [Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다.

## [Unreleased]

## [1.0.3] - 2025-10-04

### Added
- ✨ **회원 예약 취소 시 강사 알림 기능**
  - 회원이 수업 예약을 취소하면 해당 수업의 강사에게 자동으로 알림 발송
  - 알림 메시지에 회원명, 수업 일시, 수업 타입, 취소 사유 포함
  - 강사가 회원의 예약 취소를 즉시 확인 가능

### Fixed
- 🐛 **예약 재예약 오류 수정**
  - 취소된 예약을 다시 예약할 때 UNIQUE 제약 조건 오류 발생 문제 해결
  - 취소된 예약이 존재하는 경우 자동으로 삭제 후 새 예약 생성
  - `server/routes/bookings.js`: 예약 생성 로직 개선

- 🐛 **예약 생성 후 화면 업데이트 문제 해결**
  - 예약 생성 후 스케줄 탭에서 예약 정보가 즉시 반영되지 않던 문제 수정
  - 예약 탭 진입 시 "이미 예약된 스케쥴입니다" 오류 메시지 표시 문제 해결
  - `ScheduleProvider.loadSchedules()` 호출로 스케줄 데이터 자동 새로고침
  - `BookingProvider` 오류 상태 관리 개선

### Changed
- 🔧 **예약 관리 UI/UX 개선**
  - 예약 필터 버튼 순서 변경: 전체 → 확정 → 취소 에서 **확정 → 취소 → 전체** 로 변경
  - 기본 필터를 '전체'에서 '확정'으로 변경하여 사용자 편의성 향상
  - `client/lib/features/bookings/booking_list_screen.dart`

- 🔄 **스케줄 화면 자동 새로고침**
  - `WidgetsBindingObserver` 추가로 앱이 재활성화될 때 자동 새로고침
  - 다른 앱에서 돌아왔을 때 스케줄 데이터가 자동으로 업데이트
  - `client/lib/features/schedules/schedule_calendar_screen.dart`

### Technical Details
- **API Optimization**: 예약 취소 API 쿼리에 강사 ID 및 수업 타입 정보 포함
- **Database**: UNIQUE 제약 조건 충돌 처리 로직 개선
- **State Management**: Provider 패턴 오류 처리 및 상태 관리 최적화
- **Lifecycle Management**: Flutter 앱 라이프사이클 이벤트 활용한 자동 새로고침 구현

## [1.0.2] - 2025-09-30

### Fixed
- 🐛 **회원 상세 화면 회원권 정보 표시 문제 해결**
  - Membership 모델의 JSON 파싱 오류 수정
  - `user_id` 필드 null safety 처리 추가 (`json['user_id'] as int? ?? 0`)
  - 회원 등록 시 선택한 회원권 정보가 상세 화면에서 정상 표시되도록 개선

### Technical Details
- **Model Improvement**: Membership.fromJson() 메서드 null 처리 강화
- **API Compatibility**: API 응답 구조와 클라이언트 모델 간 호환성 개선
- **Data Parsing**: 회원권 데이터 파싱 안정성 향상
- **Error Handling**: null 값 처리로 앱 크래시 방지

## [1.0.1] - 2025-09-30

### Added
- ✨ **회원 관리 기능 완전 구현**
  - 데이터베이스 스키마 완성 (users, member_profiles, memberships 테이블)
  - 서버 API 완성 (회원 등록, 목록 조회, 상세 조회, 수정, 삭제)
  - 클라이언트 UI 완성 (회원 등록 화면, 회원 목록 화면)
  - 관리자/강사 전용 인증 및 권한 관리 적용
  - 회원권 템플릿 시스템과 완전 연동

### Changed  
- 🔧 **관리자/강사 접근성 개선**: 대시보드에서 '회원' 탭으로 직접 접근 가능
- 🔄 **통합 회원 등록**: 회원 정보와 회원권 정보를 함께 처리
- 📊 **향상된 회원 목록**: 상태, 가입일, 최근 로그인 정보 표시
- ⚡ **API 성능 최적화**: 응답 속도 향상 및 에러 처리 개선

### Technical Details
- **Member Management**: 완전한 CRUD 기능 구현
- **Database Integration**: 기존 시스템과 완벽 호환
- **UI/UX**: Material Design 3 기반 직관적 인터페이스
- **Security**: 역할 기반 접근 제어 적용

## [1.0.0] - 2025-09-29

### Added
- 🎉 **필라테스 센터 관리 시스템 첫 번째 릴리스**
- 👤 **사용자 관리 시스템**
  - Master, Instructor, Member 3단계 권한 시스템
  - JWT 기반 인증 및 토큰 관리
  - 사용자 프로필 관리 (개인정보, 프로필 이미지)
- 📅 **스케줄 관리 시스템**
  - 수업 일정 생성, 수정, 삭제
  - 강사별 스케줄 관리
  - 수업 타입별 분류 시스템
- 📋 **예약 관리 시스템**
  - 실시간 예약/취소 기능
  - 예약 상태 관리 (확정/대기/취소)
  - 사용자별 예약 내역 조회
- 💳 **회원권 관리 시스템**
  - 템플릿 기반 회원권 생성
  - 회원권 구매 및 잔여 횟수 관리
  - 결제 방식별 관리 (카드/현금/계좌이체)
- 📊 **대시보드**
  - 실시간 현황 모니터링
  - 사용자별 맞춤 대시보드
  - 주요 통계 정보 표시
- 🌐 **로컬 네트워크 지원**
  - Wi-Fi 기반 로컬 서버 운영
  - 0원 서버 운영비 달성
  - 외부 인터넷 없이도 동작
- 📱 **크로스플랫폼 지원**
  - Flutter 기반 멀티플랫폼 앱
  - Android, iOS, Web, macOS 지원
  - 반응형 UI 디자인

### Changed
- 🔧 **강사 권한 개선**: 전체 회원 목록 조회 가능하도록 수정
- 🔄 **자동 새로고침**: 회원 등록 후 목록 자동 업데이트
- 🎨 **UI/UX 개선**: Material Design 3 적용

### Fixed
- ✅ **한글 입력 지원**: 이름 필드에서 한글 입력 정상화
- ✅ **권한 관리**: 강사-회원 데이터 접근 권한 최적화
- ✅ **데이터 동기화**: 실시간 데이터 갱신 문제 해결

### Technical Details
- **Backend**: Node.js 18+, Express 5, SQLite 5, JWT
- **Frontend**: Flutter 3.x, Material Design 3
- **Database**: SQLite (파일 기반, 백업 용이)
- **Authentication**: JWT Token 기반 인증
- **Network**: HTTP REST API
- **Platform Support**: Android, iOS, Web, macOS, Linux, Windows

### Security
- 🔐 JWT 토큰 기반 보안 인증
- 🛡️ 사용자 권한별 데이터 접근 제어
- 🔒 로컬 네트워크 환경으로 외부 접근 차단
- 🗝️ 비밀번호 bcrypt 해싱 처리

---

## [계획된 버전]

### [1.1.0] - 계획 중
#### 예정 기능
- 📊 고급 통계 및 리포트 시스템
- 📧 SMS/푸시 알림 시스템
- 💳 PG사 연동 결제 시스템
- 📸 프로필 이미지 업로드/관리
- 🔄 자동 데이터 백업 시스템
- 🎨 테마 및 브랜딩 커스터마이징

### [1.2.0] - 계획 중
#### 예정 기능  
- 📱 모바일 앱 스토어 배포
- 🔗 외부 시스템 연동 API
- 📈 비즈니스 인텔리전스 대시보드
- 🌍 다국어 지원
- 🔧 고급 관리자 도구