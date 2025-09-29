# 필라테스 센터 관리 시스템 프로그램 설계서

## 문서 정보
- **시스템명**: 필라테스 센터 관리 시스템 (Pilates Center Management System)
- **버전**: 1.0.0
- **작성일**: 2025-09-03
- **작성자**: Claude AI
- **문서 목적**: 시스템의 전체적인 설계 구조 및 아키텍처 정의

---

## 1. 시스템 개요

### 1.1 시스템 목적
- **목적**: 필라테스/요가 센터의 통합 관리 시스템 구축
- **범위**: 회원 관리, 스케줄 관리, 예약 시스템, 결제 관리
- **특징**: 로컬 네트워크 기반 0원 운영비 시스템

### 1.2 시스템 특성
- **배포 모델**: On-Premise (로컬 네트워크)
- **아키텍처**: Client-Server 모델
- **데이터베이스**: SQLite (파일 기반)
- **플랫폼**: 크로스 플랫폼 (Web, Mobile)

---

## 2. 시스템 아키텍처

### 2.1 전체 시스템 구조도

```
┌─────────────────────────────────────────────────────────────┐
│                  로컬 네트워크 (192.168.1.x)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐         ┌─────────────────────┐    │
│  │    클라이언트 기기    │◄──────►│    서버 PC (메인)    │    │
│  │                     │   HTTP  │                     │    │
│  │ ┌─────────────────┐ │         │ ┌─────────────────┐ │    │
│  │ │ Flutter Web App │ │         │ │   Node.js API   │ │    │
│  │ │   (포트 8080)    │ │         │ │   (포트 3000)    │ │    │
│  │ └─────────────────┘ │         │ └─────────────────┘ │    │
│  │                     │         │          │          │    │
│  │ ┌─────────────────┐ │         │ ┌─────────────────┐ │    │
│  │ │ Android/iOS App │ │         │ │ SQLite Database │ │    │
│  │ │   (Flutter)     │ │         │ │  (파일 저장소)   │ │    │
│  │ └─────────────────┘ │         │ └─────────────────┘ │    │
│  └─────────────────────┘         └─────────────────────┘    │
│                                                             │
│  ┌─────────────────────┐         ┌─────────────────────┐    │
│  │   추가 클라이언트    │◄──────►│     파일 스토리지    │    │
│  │  (태블릿, 데스크톱)  │   API   │   (uploads 폴더)    │    │
│  └─────────────────────┘         └─────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 계층별 아키텍처

```
┌──────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │  Login Screen  │  │  Dashboard     │  │   Settings  │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │ Schedule Mgmt  │  │  Booking Mgmt  │  │  User Mgmt  │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
├──────────────────────────────────────────────────────────┤
│                     Business Layer                       │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │  AuthProvider  │  │ScheduleProvider│  │BookingProv. │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │   API Client   │  │     Models     │  │ Validators  │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
├──────────────────────────────────────────────────────────┤
│                      Service Layer                       │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │   Auth Routes  │  │  User Routes   │  │Schedule Rts.│ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │ Booking Routes │  │  Middlewares   │  │ Controllers │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
├──────────────────────────────────────────────────────────┤
│                       Data Layer                         │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │ Database Init  │  │  Query Builder │  │   Models    │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │ SQLite Driver  │  │ File Storage   │  │ Migrations  │ │
│  └────────────────┘  └────────────────┘  └─────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 3. 데이터베이스 설계

### 3.1 ERD (Entity Relationship Diagram)

```
┌─────────────────┐    1:N    ┌─────────────────┐    N:1    ┌─────────────────┐
│      users      │◄──────────│    schedules    │──────────►│   class_types   │
│                 │           │                 │           │                 │
│ id (PK)         │           │ id (PK)         │           │ id (PK)         │
│ user_type       │           │ class_type_id   │           │ name            │
│ name            │           │ instructor_id   │           │ description     │
│ phone           │           │ scheduled_at    │           │ duration_min    │
│ email           │           │ duration_min    │           │ max_capacity    │
│ password_hash   │           │ max_capacity    │           │ color           │
│ profile_image   │           │ current_cap.    │           │ is_active       │
│ is_active       │           │ status          │           └─────────────────┘
│ last_login_at   │           │ notes           │                    │
│ created_at      │           │ created_at      │                    │
│ updated_at      │           │ updated_at      │                    │
└─────────────────┘           └─────────────────┘                    │
         │                             │                             │
         │ 1:1                        │ 1:N                         │
         ▼                             ▼                             │
┌─────────────────┐           ┌─────────────────┐                    │
│member_profiles  │           │    bookings     │                    │
│                 │           │                 │                    │
│ user_id (FK)    │           │ id (PK)         │                    │
│ birth_date      │           │ schedule_id (FK)│                    │
│ gender          │           │ user_id (FK)    │                    │
│ emergency_cont. │           │ membership_id   │                    │
│ medical_notes   │           │ booking_type    │                    │
│ created_at      │           │ booking_status  │                    │
│ updated_at      │           │ booked_at       │                    │
└─────────────────┘           │ cancelled_at    │                    │
                              │ cancel_reason   │                    │
┌─────────────────┐           │ created_at      │                    │
│instructor_prof. │           │ updated_at      │                    │
│                 │           └─────────────────┘                    │
│ user_id (FK)    │                    │                             │
│ specialization  │                    │ N:1                         │
│ hourly_rate     │                    ▼                             │
│ bio             │           ┌─────────────────┐                    │
│ certifications  │           │   memberships   │                    │
│ created_at      │           │                 │                    │
│ updated_at      │           │ id (PK)         │                    │
└─────────────────┘           │ user_id (FK)    │                    │
                              │ membership_type │                    │
                              │ start_date      │                    │
                              │ end_date        │                    │
                              │ total_sessions  │                    │
                              │ remaining_sess. │                    │
                              │ is_active       │                    │
                              │ created_at      │                    │
                              │ updated_at      │                    │
                              └─────────────────┘                    │
                                       │                             │
                                       │ 1:N                         │
                                       ▼                             │
                              ┌─────────────────┐                    │
                              │    payments     │                    │
                              │                 │                    │
                              │ id (PK)         │                    │
                              │ membership_id   │                    │
                              │ amount          │                    │
                              │ payment_method  │                    │
                              │ payment_status  │                    │
                              │ payment_date    │                    │
                              │ created_at      │                    │
                              └─────────────────┘                    │
                                                                     │
┌─────────────────┐                                                 │
│ activity_logs   │◄────────────────────────────────────────────────┘
│                 │
│ id (PK)         │
│ user_id (FK)    │
│ action          │
│ target_type     │
│ target_id       │
│ details         │
│ created_at      │
└─────────────────┘
```

### 3.2 데이터베이스 제약조건

#### 기본키 (Primary Key)
- 모든 테이블: `id` (AUTO_INCREMENT)

#### 외래키 (Foreign Key)
```sql
-- schedules 테이블
FOREIGN KEY (class_type_id) REFERENCES class_types (id)
FOREIGN KEY (instructor_id) REFERENCES users (id)

-- bookings 테이블  
FOREIGN KEY (schedule_id) REFERENCES schedules (id)
FOREIGN KEY (user_id) REFERENCES users (id)
FOREIGN KEY (membership_id) REFERENCES memberships (id)

-- member_profiles 테이블
FOREIGN KEY (user_id) REFERENCES users (id)

-- instructor_profiles 테이블
FOREIGN KEY (user_id) REFERENCES users (id)
```

#### 체크 제약조건
```sql
-- users 테이블
CHECK (user_type IN ('master', 'instructor', 'member'))

-- schedules 테이블
CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled'))

-- bookings 테이블
CHECK (booking_status IN ('confirmed', 'waiting', 'cancelled', 'completed', 'no_show'))
CHECK (booking_type IN ('regular', 'trial', 'drop_in'))
```

---

## 4. API 설계

### 4.1 RESTful API 설계 원칙
- **HTTP 메서드**: GET(조회), POST(생성), PUT(수정), DELETE(삭제)
- **응답 형식**: JSON
- **상태 코드**: 표준 HTTP 상태 코드 사용
- **인증**: Bearer Token (JWT)

### 4.2 API 엔드포인트 명세

#### 인증 관련 API
```
POST   /api/auth/login           # 로그인
GET    /api/auth/verify          # 토큰 검증
POST   /api/auth/logout          # 로그아웃
POST   /api/auth/refresh         # 토큰 갱신
```

#### 사용자 관리 API  
```
GET    /api/users               # 사용자 목록 조회
GET    /api/users/:id           # 특정 사용자 조회
POST   /api/users               # 새 사용자 생성
PUT    /api/users/:id           # 사용자 정보 수정
DELETE /api/users/:id           # 사용자 삭제
```

#### 스케줄 관리 API
```
GET    /api/schedules           # 스케줄 목록 조회
GET    /api/schedules/:id       # 특정 스케줄 조회
POST   /api/schedules           # 새 스케줄 생성
PUT    /api/schedules/:id       # 스케줄 수정
DELETE /api/schedules/:id       # 스케줄 삭제
GET    /api/schedules/class-types # 수업 타입 목록
```

#### 예약 관리 API
```
GET    /api/bookings            # 예약 목록 조회
GET    /api/bookings/:id        # 특정 예약 조회
POST   /api/bookings            # 새 예약 생성
PUT    /api/bookings/:id/cancel # 예약 취소
```

### 4.3 API 응답 형식

#### 성공 응답
```json
{
  "success": true,
  "data": {
    // 실제 데이터
  },
  "message": "성공 메시지",
  "timestamp": "2025-09-03T12:00:00Z"
}
```

#### 에러 응답
```json
{
  "success": false,
  "error": "Error Type",
  "message": "에러 메시지",
  "statusCode": 400,
  "timestamp": "2025-09-03T12:00:00Z"
}
```

---

## 5. 사용자 인터페이스 설계

### 5.1 화면 구성도

```
┌─────────────────────────────────────────────────────────────┐
│                        앱 구조                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐                                    │
│  │    로그인 화면       │                                    │
│  │   (LoginScreen)     │                                    │
│  └─────────────┬───────┘                                    │
│                │                                            │
│                ▼                                            │
│  ┌─────────────────────┐                                    │
│  │      인증 래퍼       │                                    │
│  │   (AuthWrapper)     │                                    │
│  └─────────────┬───────┘                                    │
│                │                                            │
│                ▼                                            │
│  ┌─────────────────────┐                                    │
│  │    메인 대시보드     │                                    │
│  │ (DashboardScreen)   │                                    │
│  └─────────────┬───────┘                                    │
│                │                                            │
│       ┌────────┼────────┬────────────┐                     │
│       │        │        │            │                     │
│       ▼        ▼        ▼            ▼                     │
│  ┌────────┐┌────────┐┌────────┐┌─────────┐                 │
│  │스케줄  ││예약관리││회원관리││ 설정    │                 │
│  │관리    ││        ││        ││         │                 │
│  └────────┘└────────┘└────────┘└─────────┘                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 사용자 권한별 화면 접근

#### 회원 (Member)
- ✅ 로그인 화면
- ✅ 대시보드 (개인 정보)
- ✅ 스케줄 조회 (예약 가능)
- ✅ 본인 예약 관리
- ❌ 회원 관리
- ❌ 시스템 설정

#### 강사 (Instructor)  
- ✅ 로그인 화면
- ✅ 대시보드 (담당 수업)
- ✅ 스케줄 관리 (생성, 수정)
- ✅ 전체 예약 조회
- ✅ 회원 조회 (읽기 전용)
- ❌ 시스템 설정

#### 관리자 (Master)
- ✅ 모든 화면 접근
- ✅ 사용자 생성/수정/삭제
- ✅ 스케줄 전체 관리
- ✅ 결제 및 매출 관리
- ✅ 시스템 설정

---

## 6. 보안 설계

### 6.1 인증 및 권한 관리

#### JWT 토큰 구조
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "userId": 1,
    "userType": "master",
    "iat": 1693747200,
    "exp": 1693833600
  },
  "signature": "..."
}
```

#### 권한 체계
```javascript
const permissions = {
  master: ['*'],                    // 모든 권한
  instructor: [                     // 강사 권한
    'schedules:read',
    'schedules:create',
    'schedules:update',
    'bookings:read',
    'users:read'
  ],
  member: [                         // 회원 권한
    'schedules:read',
    'bookings:read:own',
    'bookings:create:own',
    'bookings:cancel:own'
  ]
};
```

### 6.2 데이터 보안

#### 비밀번호 보안
- **해싱**: bcrypt (라운드 10)
- **솔트**: 자동 생성
- **저장**: 해시값만 데이터베이스에 저장

#### 데이터 검증
```javascript
// 입력 데이터 검증 예시
const userValidation = {
  phone: /^[0-9]{10,11}$/,          // 전화번호 형식
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/, // 이메일 형식
  password: /^.{8,}$/               // 최소 8자 이상
};
```

### 6.3 네트워크 보안

#### HTTPS 설정 (프로덕션)
```javascript
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('private-key.pem'),
  cert: fs.readFileSync('certificate.pem')
};

https.createServer(options, app).listen(3443);
```

#### CORS 설정
```javascript
const corsOptions = {
  origin: [
    'http://localhost:8080',
    'http://127.0.0.1:8080', 
    'http://192.168.1.100:3000'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
```

---

## 7. 성능 설계

### 7.1 데이터베이스 최적화

#### 인덱스 전략
```sql
-- 자주 조회되는 컬럼에 인덱스 설정
CREATE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_users_type_active ON users (user_type, is_active);
CREATE INDEX idx_schedules_date ON schedules (scheduled_at);
CREATE INDEX idx_schedules_instructor ON schedules (instructor_id, scheduled_at);
CREATE INDEX idx_bookings_user_schedule ON bookings (user_id, schedule_id);
CREATE INDEX idx_bookings_status ON bookings (booking_status);
```

#### 쿼리 최적화
- **JOIN 사용**: N+1 문제 방지
- **LIMIT/OFFSET**: 페이징 처리
- **WHERE 절 최적화**: 인덱스 활용

### 7.2 캐싱 전략

#### 애플리케이션 레벨 캐싱
```javascript
// 메모리 캐시 (단순 구현)
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5분

function getCachedData(key) {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }
  return null;
}
```

#### HTTP 캐싱
```javascript
// 정적 리소스 캐싱
app.use('/uploads', express.static('uploads', {
  maxAge: '1h',
  etag: true
}));
```

---

## 8. 배포 설계

### 8.1 배포 구조도

```
┌─────────────────────────────────────────────────────────────┐
│                    센터 내부 네트워크                        │
│                   (192.168.1.0/24)                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐                                    │
│  │    서버 PC (메인)    │ IP: 192.168.1.100                 │
│  │                     │                                    │
│  │ ┌─────────────────┐ │                                    │
│  │ │   Node.js App   │ │ 포트: 3000                          │
│  │ │                 │ │                                    │
│  │ │ ├─ API Server   │ │                                    │
│  │ │ ├─ Static Files │ │                                    │
│  │ │ └─ File Upload  │ │                                    │
│  │ └─────────────────┘ │                                    │
│  │                     │                                    │
│  │ ┌─────────────────┐ │                                    │
│  │ │ SQLite Database │ │                                    │
│  │ │ pilates_center  │ │                                    │
│  │ │     .db         │ │                                    │
│  │ └─────────────────┘ │                                    │
│  └─────────────────────┘                                    │
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │   클라이언트 기기    │  │   클라이언트 기기    │          │
│  │                     │  │                     │          │
│  │ IP: 192.168.1.101   │  │ IP: 192.168.1.102   │    ...   │
│  │ (강사 태블릿)        │  │ (관리자 데스크톱)    │          │
│  └─────────────────────┘  └─────────────────────┘          │
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │   클라이언트 기기    │  │   클라이언트 기기    │          │
│  │                     │  │                     │          │
│  │ IP: 192.168.1.103   │  │ IP: 192.168.1.104   │    ...   │
│  │ (회원 스마트폰)       │  │ (회원 스마트폰)       │          │
│  └─────────────────────┘  └─────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 배포 스크립트

#### 서버 시작 스크립트 (start.sh)
```bash
#!/bin/bash

# 환경 변수 설정
export NODE_ENV=production
export PORT=3000
export JWT_SECRET=pilates-center-production-secret

# 프로세스 매니저로 실행 (PM2)
pm2 start index.js --name pilates-server

# 또는 직접 실행
# node index.js
```

#### Flutter 웹 빌드 스크립트
```bash
#!/bin/bash

# Flutter 웹 빌드
flutter build web --release

# 빌드 파일을 서버 static 폴더로 복사
cp -r build/web/* ../server/public/

echo "Flutter web build completed!"
```

---

## 9. 모니터링 및 유지보수

### 9.1 로깅 설계

#### 로그 레벨
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});
```

#### 활동 로그
```sql
-- 사용자 활동 추적
INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
VALUES (?, 'login', 'auth', NULL, '{"ip": "192.168.1.101"}');
```

### 9.2 백업 전략

#### 데이터베이스 백업
```bash
#!/bin/bash

# 일일 백업 스크립트
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/db"

# SQLite 파일 백업
cp pilates_center.db "${BACKUP_DIR}/pilates_center_${DATE}.db"

# 파일 업로드 백업
tar -czf "${BACKUP_DIR}/uploads_${DATE}.tar.gz" uploads/

echo "Backup completed: ${DATE}"
```

---

## 10. 확장성 고려사항

### 10.1 향후 확장 계획

#### 추가 기능 모듈
1. **결제 시스템**: 온라인 결제 연동
2. **알림 시스템**: Push 알림, SMS 발송
3. **리포트 시스템**: 매출 분석, 회원 통계
4. **모바일 앱**: Android/iOS 네이티브 앱
5. **API 외부 연동**: 카카오페이, PG사 연동

#### 스케일링 전략
```
단계 1: 단일 센터 (현재)
┌─────────────┐
│ 센터 A      │
│ - 서버 1대   │
│ - 사용자 ~50 │
└─────────────┘

단계 2: 다중 센터
┌─────────────┐  ┌─────────────┐
│ 센터 A      │  │ 센터 B      │
│ - 서버 1대   │  │ - 서버 1대   │
│ - 사용자 ~50 │  │ - 사용자 ~50 │
└─────────────┘  └─────────────┘

단계 3: 클라우드 확장
┌─────────────────────────────────┐
│        클라우드 서버              │
│ ┌─────────────┐ ┌─────────────┐ │
│ │ API Server  │ │  Database   │ │
│ └─────────────┘ └─────────────┘ │
└─────────────────────────────────┘
         │
    ┌────┴────┬────────┐
    │         │        │
┌─────────┐┌─────────┐┌─────────┐
│ 센터 A  ││ 센터 B  ││ 센터 C  │
└─────────┘└─────────┘└─────────┘
```

---

*본 프로그램 설계서는 시스템의 전체적인 구조와 설계 원칙을 정의하여, 개발 팀이 일관된 방향으로 시스템을 구축할 수 있도록 가이드라인을 제시합니다.*