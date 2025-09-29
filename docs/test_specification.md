# 필라테스 센터 관리 시스템 테스트 명세서

## 문서 정보
- **시스템명**: 필라테스 센터 관리 시스템 (Pilates Center Management System)
- **버전**: 1.0.0
- **작성일**: 2025-09-03
- **작성자**: Claude AI
- **문서 목적**: 시스템 테스트 계획 및 테스트 케이스 정의

---

## 1. 테스트 개요

### 1.1 테스트 목적
- **품질 보증**: 시스템이 요구사항을 충족하는지 검증
- **결함 발견**: 개발 단계에서 놓친 버그 및 오류 발견
- **안정성 확인**: 다양한 환경에서의 시스템 안정성 검증
- **사용자 만족도**: 실제 사용 환경에서의 사용성 검증

### 1.2 테스트 범위
- **포함 범위**:
  - 기능 테스트 (로그인, 예약, 회원관리 등)
  - 통합 테스트 (API-클라이언트 연동)
  - 성능 테스트 (응답시간, 동시접속)
  - 보안 테스트 (인증, 권한)
  - 사용성 테스트 (UI/UX)

- **제외 범위**:
  - 외부 시스템 연동 테스트
  - 대용량 데이터 스트레스 테스트
  - 모바일 네이티브 앱 테스트

### 1.3 테스트 환경
- **서버 환경**: 
  - OS: macOS 14.5
  - Node.js: v18+
  - 데이터베이스: SQLite
  - 네트워크: 로컬 네트워크 (192.168.1.x)

- **클라이언트 환경**:
  - 웹 브라우저: Chrome 90+, Safari 14+
  - 해상도: 1920x1080 (데스크톱), 375x667 (모바일)
  - Flutter: 3.x

---

## 2. 테스트 전략

### 2.1 테스트 레벨

#### 단위 테스트 (Unit Test)
- **범위**: 개별 함수, 메서드 단위
- **도구**: Jest (Node.js), Flutter Test Framework
- **목표**: 코드 커버리지 80% 이상

#### 통합 테스트 (Integration Test)
- **범위**: API와 클라이언트 간 연동
- **도구**: Postman, Flutter Integration Test
- **목표**: 모든 API 엔드포인트 검증

#### 시스템 테스트 (System Test)
- **범위**: 전체 시스템 종단간 테스트
- **도구**: 수동 테스트, 자동화 스크립트
- **목표**: 실제 사용 시나리오 검증

### 2.2 테스트 유형

#### 기능 테스트 (Functional Testing)
- 요구사항 명세서의 모든 기능 검증
- 정상/비정상 케이스 모두 테스트
- 경계값 테스트 포함

#### 비기능 테스트 (Non-Functional Testing)
- 성능 테스트: 응답시간, 처리량
- 보안 테스트: 인증, 권한, 데이터 보호
- 사용성 테스트: UI/UX, 접근성

---

## 3. 기능 테스트 케이스

### 3.1 로그인 기능 테스트

#### TC-001: 정상 로그인
- **목적**: 올바른 계정 정보로 로그인 성공 여부 확인
- **전제 조건**: 유효한 사용자 계정이 존재함
- **테스트 데이터**: 
  - 전화번호: "admin"
  - 비밀번호: "admin123"
- **테스트 단계**:
  1. 로그인 화면 접속
  2. 전화번호 입력란에 "admin" 입력
  3. 비밀번호 입력란에 "admin123" 입력
  4. 로그인 버튼 클릭
- **예상 결과**: 
  - 대시보드 화면으로 이동
  - 상단에 사용자 정보 표시
  - JWT 토큰 로컬 스토리지 저장

#### TC-002: 잘못된 비밀번호 로그인
- **목적**: 잘못된 비밀번호 입력 시 로그인 실패 확인
- **전제 조건**: 유효한 사용자 계정이 존재함
- **테스트 데이터**:
  - 전화번호: "admin"
  - 비밀번호: "wrongpassword"
- **테스트 단계**:
  1. 로그인 화면 접속
  2. 올바른 전화번호 입력
  3. 잘못된 비밀번호 입력
  4. 로그인 버튼 클릭
- **예상 결과**:
  - 로그인 실패 메시지 표시
  - 로그인 화면에 머물기
  - 토큰 저장되지 않음

#### TC-003: 빈 값 로그인 시도
- **목적**: 필수 입력값 누락 시 검증 확인
- **테스트 데이터**: 빈 값
- **테스트 단계**:
  1. 로그인 화면 접속
  2. 전화번호, 비밀번호 모두 빈 값으로 유지
  3. 로그인 버튼 클릭
- **예상 결과**:
  - 입력 필드 검증 오류 메시지 표시
  - 로그인 처리되지 않음

### 3.2 회원 관리 기능 테스트

#### TC-004: 신규 회원 등록
- **목적**: 새로운 회원 등록 기능 검증
- **전제 조건**: 관리자로 로그인되어 있음
- **테스트 데이터**:
  - 이름: "홍길동"
  - 전화번호: "01012345678"
  - 이메일: "hong@test.com"
  - 비밀번호: "test1234"
- **테스트 단계**:
  1. 회원 관리 메뉴 선택
  2. 새 회원 추가 버튼 클릭
  3. 회원 정보 입력
  4. 저장 버튼 클릭
- **예상 결과**:
  - 회원 등록 성공 메시지
  - 회원 목록에 새 회원 표시
  - 데이터베이스에 정보 저장 확인

#### TC-005: 중복 전화번호 회원 등록
- **목적**: 중복 전화번호 등록 시 오류 처리 확인
- **전제 조건**: 
  - 관리자로 로그인되어 있음
  - "01012345678" 전화번호로 등록된 회원 존재
- **테스트 데이터**:
  - 전화번호: "01012345678" (기존과 동일)
- **테스트 단계**:
  1. 신규 회원 등록 화면 접속
  2. 기존과 동일한 전화번호 입력
  3. 나머지 정보 입력 후 저장
- **예상 결과**:
  - 중복 전화번호 오류 메시지
  - 회원 등록 처리되지 않음

### 3.3 스케줄 관리 기능 테스트

#### TC-006: 새 스케줄 등록
- **목적**: 새로운 수업 스케줄 등록 기능 검증
- **전제 조건**: 
  - 강사 또는 관리자로 로그인
  - 수업 타입과 강사 데이터 존재
- **테스트 데이터**:
  - 수업 타입: "필라테스 기초"
  - 강사: "김강사"
  - 일시: "2025-09-04 10:00"
  - 소요 시간: 60분
  - 최대 인원: 8명
- **테스트 단계**:
  1. 스케줄 관리 메뉴 선택
  2. 새 스케줄 추가 버튼 클릭
  3. 스케줄 정보 입력
  4. 저장 버튼 클릭
- **예상 결과**:
  - 스케줄 등록 성공 메시지
  - 스케줄 목록에 새 일정 표시
  - 예약 가능 상태로 표시

#### TC-007: 강사 중복 스케줄 등록 시도
- **목적**: 동일 시간대 강사 중복 스케줄 방지 확인
- **전제 조건**: 
  - 특정 시간에 특정 강사의 스케줄이 이미 존재
- **테스트 단계**:
  1. 기존 스케줄과 동일한 시간에
  2. 동일한 강사로 새 스케줄 등록 시도
- **예상 결과**:
  - 강사 중복 스케줄 오류 메시지
  - 스케줄 등록 처리되지 않음

### 3.4 예약 시스템 기능 테스트

#### TC-008: 정상 예약 등록
- **목적**: 일반적인 수업 예약 기능 검증
- **전제 조건**:
  - 회원으로 로그인
  - 예약 가능한 스케줄 존재
- **테스트 단계**:
  1. 스케줄 목록에서 예약 가능한 수업 선택
  2. 예약하기 버튼 클릭
  3. 예약 확인
- **예상 결과**:
  - 예약 성공 메시지
  - 예약 목록에 새 예약 표시
  - 스케줄 현재 인원 수 증가

#### TC-009: 정원 초과 예약 시도
- **목적**: 정원 초과 시 대기자 등록 기능 확인
- **전제 조건**:
  - 최대 인원이 모두 찬 스케줄 존재
- **테스트 단계**:
  1. 정원이 찬 수업에 예약 시도
- **예상 결과**:
  - 대기자로 등록됨
  - 대기 상태 표시
  - 대기 순번 안내

#### TC-010: 예약 취소
- **목적**: 기존 예약 취소 기능 검증
- **전제 조건**:
  - 유효한 예약이 존재함
- **테스트 단계**:
  1. 예약 목록에서 취소할 예약 선택
  2. 취소 버튼 클릭
  3. 취소 사유 입력
  4. 확인 버튼 클릭
- **예상 결과**:
  - 예약 취소 완료 메시지
  - 예약 상태가 '취소됨'으로 변경
  - 대기자가 있는 경우 자동 승급

---

## 4. API 테스트 케이스

### 4.1 인증 API 테스트

#### API-TC-001: POST /api/auth/login
```bash
# 정상 로그인 테스트
curl -X POST http://192.168.1.100:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "admin",
    "password": "admin123"
  }'

# 예상 응답 (200)
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "user_type": "master",
    "name": "관리자",
    "phone": "admin"
  },
  "message": "로그인 성공"
}
```

#### API-TC-002: GET /api/auth/verify
```bash
# 토큰 검증 테스트
curl -X GET http://192.168.1.100:3000/api/auth/verify \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# 예상 응답 (200)
{
  "user": {
    "id": 1,
    "user_type": "master",
    "name": "관리자"
  },
  "message": "유효한 토큰입니다"
}
```

### 4.2 사용자 관리 API 테스트

#### API-TC-003: GET /api/users
```bash
# 사용자 목록 조회
curl -X GET http://192.168.1.100:3000/api/users \
  -H "Authorization: Bearer [token]"

# 예상 응답 (200)
{
  "users": [
    {
      "id": 1,
      "user_type": "master",
      "name": "관리자",
      "phone": "admin",
      "email": null,
      "is_active": true,
      "created_at": "2025-09-03T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

### 4.3 스케줄 관리 API 테스트

#### API-TC-004: POST /api/schedules
```bash
# 새 스케줄 생성
curl -X POST http://192.168.1.100:3000/api/schedules \
  -H "Authorization: Bearer [token]" \
  -H "Content-Type: application/json" \
  -d '{
    "class_type_id": 1,
    "instructor_id": 1,
    "scheduled_at": "2025-09-04T10:00:00Z",
    "duration_minutes": 60,
    "max_capacity": 8,
    "notes": "초보자 환영"
  }'

# 예상 응답 (201)
{
  "message": "스케줄이 생성되었습니다.",
  "schedule_id": 1
}
```

---

## 5. 성능 테스트

### 5.1 응답 시간 테스트

#### PERF-TC-001: API 응답 시간 측정
```bash
# Apache Bench를 사용한 성능 테스트
ab -n 1000 -c 10 http://192.168.1.100:3000/api/health

# 목표 기준
# - 평균 응답 시간: 500ms 이하
# - 95% 응답 시간: 1000ms 이하
# - 최대 응답 시간: 2000ms 이하
```

#### PERF-TC-002: 동시 사용자 테스트
```bash
# 동시 로그인 사용자 테스트
for i in {1..20}; do
  curl -X POST http://192.168.1.100:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"phone":"admin","password":"admin123"}' &
done
wait

# 목표 기준
# - 20명 동시 로그인 성공
# - 응답 시간 3초 이내
# - 에러율 5% 이하
```

### 5.2 부하 테스트

#### PERF-TC-003: 지속적 부하 테스트
- **도구**: Artillery.io 또는 JMeter
- **시나리오**: 
  - 동시 사용자: 30명
  - 테스트 시간: 10분
  - 주요 API 골고루 호출
- **성공 기준**:
  - 에러율 5% 이하
  - 평균 응답시간 1초 이하
  - 서버 메모리 사용량 80% 이하

---

## 6. 보안 테스트

### 6.1 인증/권한 테스트

#### SEC-TC-001: 무효한 토큰 접근 시도
```bash
# 잘못된 토큰으로 API 접근
curl -X GET http://192.168.1.100:3000/api/users \
  -H "Authorization: Bearer invalid_token"

# 예상 응답 (403)
{
  "error": "Forbidden",
  "message": "유효하지 않은 토큰입니다."
}
```

#### SEC-TC-002: 권한 없는 기능 접근 시도
```bash
# 회원 계정으로 관리자 기능 접근 시도
curl -X POST http://192.168.1.100:3000/api/users \
  -H "Authorization: Bearer [member_token]" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","phone":"test"}'

# 예상 응답 (403)
{
  "error": "Forbidden",
  "message": "권한이 없습니다."
}
```

### 6.2 SQL Injection 테스트

#### SEC-TC-003: 로그인 SQL Injection 시도
```bash
# 악의적인 SQL 코드 삽입 시도
curl -X POST http://192.168.1.100:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "admin\" OR 1=1--",
    "password": "anything"
  }'

# 예상 결과: 로그인 실패, SQL Injection 방어 확인
```

---

## 7. 사용성 테스트

### 7.1 UI/UX 테스트 체크리스트

#### UX-TC-001: 반응형 디자인
- [ ] 데스크톱 (1920x1080) 정상 표시
- [ ] 태블릿 (768x1024) 정상 표시  
- [ ] 모바일 (375x667) 정상 표시
- [ ] 가로/세로 모드 전환 정상 동작

#### UX-TC-002: 접근성
- [ ] 키보드만으로 모든 기능 접근 가능
- [ ] 스크린 리더 지원 (기본 수준)
- [ ] 색상 대비 적절성
- [ ] 폰트 크기 가독성

#### UX-TC-003: 사용자 경험
- [ ] 3클릭 이내 모든 주요 기능 접근
- [ ] 로딩 상태 적절한 표시
- [ ] 오류 메시지 명확성
- [ ] 성공/실패 피드백 제공

---

## 8. 테스트 자동화

### 8.1 백엔드 단위 테스트 (Jest)

```javascript
// tests/auth.test.js
const request = require('supertest');
const app = require('../index');

describe('Authentication API', () => {
  test('POST /api/auth/login - 정상 로그인', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        phone: 'admin',
        password: 'admin123'
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('user');
    expect(response.body.user.phone).toBe('admin');
  });

  test('POST /api/auth/login - 잘못된 비밀번호', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        phone: 'admin',
        password: 'wrongpassword'
      });

    expect(response.status).toBe(401);
    expect(response.body).toHaveProperty('error');
  });
});
```

### 8.2 프론트엔드 위젯 테스트 (Flutter)

```dart
// test/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilates_center_client/features/auth/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('로그인 화면 렌더링 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('필라테스 센터'), findsOneWidget);
      expect(find.text('전화번호'), findsOneWidget);
      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('로그인'), findsOneWidget);
    });

    testWidgets('빈 값으로 로그인 시도', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // 로그인 버튼 클릭 (빈 값 상태)
      await tester.tap(find.text('로그인'));
      await tester.pump();

      // 검증 오류 메시지 확인
      expect(find.text('전화번호를 입력해주세요'), findsOneWidget);
      expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
    });
  });
}
```

---

## 9. 테스트 실행 계획

### 9.1 테스트 단계별 일정

#### 1단계: 단위 테스트 (1일차)
- 백엔드 API 단위 테스트 실행
- 프론트엔드 위젯 테스트 실행
- 코드 커버리지 측정 및 분석

#### 2단계: 통합 테스트 (2일차)
- API-클라이언트 연동 테스트
- 데이터베이스 연동 테스트
- 시나리오 기반 기능 테스트

#### 3단계: 시스템 테스트 (3일차)
- 전체 시스템 종단간 테스트
- 성능 테스트 실행
- 보안 테스트 실행
- 사용성 테스트 실행

#### 4단계: 사용자 수락 테스트 (4일차)
- 실제 사용자 시나리오 테스트
- 피드백 수집 및 개선사항 도출

### 9.2 테스트 실행 명령어

#### 백엔드 테스트
```bash
# 서버 디렉토리에서
cd server
npm test                    # 모든 테스트 실행
npm run test:coverage      # 커버리지 포함 테스트
npm run test:watch         # 변경사항 감지 테스트
```

#### 프론트엔드 테스트
```bash
# 클라이언트 디렉토리에서
cd client
flutter test              # 단위 테스트 실행
flutter test --coverage   # 커버리지 포함 테스트
flutter drive --target=test_driver/app.dart  # 통합 테스트
```

---

## 10. 테스트 결과 보고서 템플릿

### 10.1 테스트 실행 결과

| 테스트 유형 | 총 케이스 | 통과 | 실패 | 통과율 | 비고 |
|------------|-----------|------|------|--------|------|
| 단위 테스트 | 50 | 48 | 2 | 96% | - |
| 통합 테스트 | 25 | 24 | 1 | 96% | API 연동 이슈 |
| 기능 테스트 | 30 | 28 | 2 | 93% | UI 개선 필요 |
| 성능 테스트 | 10 | 9 | 1 | 90% | 동시접속 한계 |
| 보안 테스트 | 15 | 15 | 0 | 100% | - |

### 10.2 발견된 결함

#### 결함 #001: 로그인 시 네트워크 오류 처리
- **심각도**: 중간
- **설명**: 네트워크 연결 불안정 시 적절한 오류 메시지 부재
- **재현 단계**: 네트워크 연결을 끊고 로그인 시도
- **수정 방안**: 네트워크 오류 감지 및 사용자 친화적 메시지 표시

#### 결함 #002: 모바일 UI 레이아웃 깨짐
- **심각도**: 낮음
- **설명**: 특정 화면에서 모바일 레이아웃 최적화 부족
- **수정 방안**: 반응형 디자인 개선

### 10.3 성능 테스트 결과

| 항목 | 목표 | 측정값 | 결과 |
|------|------|--------|------|
| 평균 응답시간 | 500ms | 320ms | ✅ 통과 |
| 95% 응답시간 | 1000ms | 850ms | ✅ 통과 |
| 동시 접속자 | 20명 | 25명 | ✅ 통과 |
| 에러율 | < 5% | 2.1% | ✅ 통과 |

---

*본 테스트 명세서는 시스템의 품질을 보장하기 위한 체계적인 테스트 방법론을 제시하며, 개발 완료 후 안정적인 서비스 제공을 위한 검증 기준을 정의합니다.*