# 필라테스 센터 관리 시스템 코드 명세서

## 문서 정보
- **시스템명**: 필라테스 센터 관리 시스템 (Pilates Center Management System)
- **버전**: 1.0.0
- **작성일**: 2025-09-03
- **작성자**: Claude AI
- **문서 목적**: 시스템 코드의 상세 구조 및 구현 명세

---

## 1. 코드 구조 개요

### 1.1 전체 프로젝트 구조
```
pilates_center_system/
├── server/                     # Node.js 백엔드 서버
│   ├── database/              # 데이터베이스 관련
│   ├── routes/                # API 라우트
│   ├── uploads/               # 파일 업로드 저장소
│   └── index.js               # 서버 메인 파일
├── client/                    # Flutter 클라이언트
│   ├── lib/                   # Flutter 소스 코드
│   │   ├── core/              # 핵심 기능 (API, 인증 등)
│   │   ├── features/          # 기능별 페이지
│   │   ├── shared/            # 공통 컴포넌트
│   │   └── main.dart          # Flutter 메인
│   └── pubspec.yaml           # Flutter 의존성
└── docs/                      # 문서화
```

### 1.2 코딩 규칙 및 스타일

#### Node.js/JavaScript
- **명명 규칙**: camelCase (함수, 변수), snake_case (DB 컬럼)
- **파일명**: kebab-case (예: auth-routes.js)
- **들여쓰기**: 2 spaces
- **문자열**: single quotes 사용
- **세미콜론**: 필수 사용

#### Flutter/Dart
- **명명 규칙**: camelCase (변수, 메서드), PascalCase (클래스)
- **파일명**: snake_case (예: login_screen.dart)
- **들여쓰기**: 2 spaces
- **위젯 네이밍**: Widget 접미사 사용

---

## 2. 백엔드 코드 명세

### 2.1 서버 메인 파일 (index.js)

#### 주요 구성 요소
```javascript
// 의존성 모듈
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// 커스텀 모듈
const Database = require('./database/init');
const authRoutes = require('./routes/auth');
```

#### 미들웨어 구성
1. **보안 미들웨어**
   - `helmet()`: HTTP 헤더 보안 설정
   - `cors()`: 로컬 네트워크 CORS 허용

2. **로깅 미들웨어**
   - `morgan('combined')`: HTTP 요청 로깅

3. **파싱 미들웨어**
   - `express.json({ limit: '10mb' })`: JSON 파싱
   - `express.urlencoded()`: URL 인코딩 파싱

4. **데이터베이스 미들웨어**
   ```javascript
   app.use((req, res, next) => {
     req.db = db;
     next();
   });
   ```

### 2.2 데이터베이스 관리 클래스 (database/init.js)

#### 클래스 구조
```javascript
class Database {
  constructor() {
    this.db = null;
  }

  async initialize() {
    // SQLite 연결 초기화
    // 스키마 생성
    // 기본 데이터 삽입
  }

  async getQuery(query, params = []) {
    // 단일 레코드 조회
  }

  async getAllQuery(query, params = []) {
    // 다중 레코드 조회
  }

  async runQuery(query, params = []) {
    // DML 실행 (INSERT, UPDATE, DELETE)
  }
}
```

#### 주요 메서드 상세

**initialize() 메서드**
```javascript
async initialize() {
  try {
    // 1. SQLite 연결
    this.db = new sqlite3.Database('./pilates_center.db');
    
    // 2. 스키마 생성
    const schema = await fs.readFile('./database/schema.sql', 'utf8');
    await this.runQuery(schema);
    
    // 3. 기본 데이터 삽입
    await this.insertInitialData();
    
    console.log('✅ Database initialized successfully');
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
}
```

### 2.3 API 라우트 구조

#### 인증 라우트 (routes/auth.js)

**로그인 엔드포인트**
```javascript
router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;
    
    // 1. 입력 검증
    if (!phone || !password) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '전화번호와 비밀번호는 필수입니다.'
      });
    }
    
    // 2. 사용자 조회
    const user = await req.db.getQuery(
      'SELECT * FROM users WHERE phone = ? AND is_active = 1',
      [phone]
    );
    
    // 3. 비밀번호 검증
    const isValid = await bcrypt.compare(password, user.password_hash);
    
    // 4. JWT 토큰 생성
    const token = jwt.sign(
      { userId: user.id, userType: user.user_type },
      process.env.JWT_SECRET || 'pilates-center-secret',
      { expiresIn: '24h' }
    );
    
    // 5. 로그인 시간 업데이트
    await req.db.runQuery(
      'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?',
      [user.id]
    );
    
    res.json({ token, user, message: '로그인 성공' });
  } catch (error) {
    // 에러 처리 로직
  }
});
```

**토큰 검증 미들웨어**
```javascript
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: '액세스 토큰이 필요합니다.'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'pilates-center-secret', (err, user) => {
    if (err) {
      return res.status(403).json({
        error: 'Forbidden',
        message: '유효하지 않은 토큰입니다.'
      });
    }

    req.user = user;
    next();
  });
}
```

---

## 3. 프론트엔드 코드 명세

### 3.1 Flutter 앱 구조

#### 메인 애플리케이션 (main.dart)
```dart
class PilatesCenterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: '필라테스 센터 관리',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
```

### 3.2 API 클라이언트 (core/api/api_client.dart)

#### 싱글톤 패턴 구현
```dart
class ApiClient {
  static const String _baseUrl = 'http://192.168.1.100:3000/api';
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _authToken;
}
```

#### HTTP 요청 메서드
```dart
Future<Map<String, dynamic>> post(
  String endpoint,
  Map<String, dynamic> data, {
  bool includeAuth = true,
}) async {
  try {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _getHeaders(includeAuth: includeAuth),
      body: json.encode(data),
    );

    return await _handleResponse(response);
  } on SocketException {
    throw ApiException('No internet connection', 0);
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Request failed: $e', 0);
  }
}
```

### 3.3 상태 관리 (Provider 패턴)

#### AuthProvider 클래스
```dart
class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  
  Future<bool> login(String phone, String password) async {
    try {
      final response = await _apiClient.login(phone, password);
      final loginResponse = LoginResponse.fromJson(response);
      
      _status = AuthStatus.authenticated;
      _user = loginResponse.user;
      
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }
}
```

### 3.4 모델 클래스 (JSON Serialization)

#### User 모델
```dart
@JsonSerializable()
class User {
  final int id;
  @JsonKey(name: 'user_type')
  final String userType;
  final String name;
  final String phone;
  final String? email;

  User({
    required this.id,
    required this.userType,
    required this.name,
    required this.phone,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isMaster => userType == 'master';
  bool get isInstructor => userType == 'instructor';
  bool get isMember => userType == 'member';
}
```

---

## 4. 데이터베이스 스키마 명세

### 4.1 핵심 테이블 구조

#### users 테이블
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_type TEXT NOT NULL CHECK (user_type IN ('master', 'instructor', 'member')),
    name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    email TEXT,
    password_hash TEXT NOT NULL,
    profile_image TEXT,
    is_active BOOLEAN DEFAULT 1,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### schedules 테이블
```sql
CREATE TABLE schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_type_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    max_capacity INTEGER NOT NULL DEFAULT 10,
    current_capacity INTEGER DEFAULT 0,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_type_id) REFERENCES class_types (id),
    FOREIGN KEY (instructor_id) REFERENCES users (id)
);
```

### 4.2 인덱스 설정
```sql
-- 성능 최적화를 위한 인덱스
CREATE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_users_type_active ON users (user_type, is_active);
CREATE INDEX idx_schedules_date ON schedules (scheduled_at);
CREATE INDEX idx_bookings_user_schedule ON bookings (user_id, schedule_id);
```

---

## 5. 에러 처리 및 로깅

### 5.1 백엔드 에러 처리
```javascript
// 전역 에러 핸들러
app.use((err, req, res, next) => {
  console.error('❌ Server Error:', err);
  
  res.status(err.status || 500).json({
    error: err.name || 'Internal Server Error',
    message: err.message || '서버에서 오류가 발생했습니다.',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});
```

### 5.2 프론트엔드 에러 처리
```dart
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
```

---

## 6. 보안 구현

### 6.1 비밀번호 암호화
```javascript
// 비밀번호 해시화
const password_hash = await bcrypt.hash(password, 10);

// 비밀번호 검증
const isValid = await bcrypt.compare(password, user.password_hash);
```

### 6.2 JWT 토큰 관리
```javascript
// 토큰 생성
const token = jwt.sign(
  { userId: user.id, userType: user.user_type },
  process.env.JWT_SECRET,
  { expiresIn: '24h' }
);

// 토큰 검증
jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
  if (err) return res.status(403).json({ error: 'Invalid token' });
  req.user = user;
  next();
});
```

---

## 7. 성능 최적화

### 7.1 데이터베이스 최적화
- **인덱스 활용**: 자주 조회되는 컬럼에 인덱스 설정
- **쿼리 최적화**: JOIN 사용으로 N+1 문제 방지
- **페이지네이션**: LIMIT, OFFSET 활용

### 7.2 프론트엔드 최적화
- **상태 관리**: Provider 패턴으로 효율적 상태 관리
- **이미지 캐싱**: Flutter 기본 캐싱 활용
- **지연 로딩**: 필요 시점에 데이터 로드

---

## 8. 코드 리뷰 체크리스트

### 8.1 백엔드 체크포인트
- [ ] 모든 API 엔드포인트에 인증 미들웨어 적용
- [ ] SQL Injection 방지 (Parameterized Query 사용)
- [ ] 에러 처리 및 적절한 HTTP 상태 코드 반환
- [ ] 로깅 및 활동 추적 구현
- [ ] 데이터 검증 (입력값 검증)

### 8.2 프론트엔드 체크포인트
- [ ] 모든 위젯에 key 속성 적용
- [ ] 상태 변경 시 notifyListeners() 호출
- [ ] 메모리 누수 방지 (dispose 메서드 구현)
- [ ] 사용자 경험 고려 (로딩, 에러 처리)
- [ ] 접근성 고려 (Semantics 위젯 활용)

---

*본 코드 명세서는 시스템의 코드 구조와 구현 세부사항을 상세히 기술하여, 개발자들이 코드를 이해하고 유지보수할 수 있도록 작성되었습니다.*