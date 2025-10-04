-- Pilates Center Management System Database Schema
-- SQLite Database

-- 1. 센터 기본 정보
CREATE TABLE IF NOT EXISTS centers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    business_number TEXT,
    logo_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. 사용자 (통합 테이블)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_type TEXT NOT NULL CHECK (user_type IN ('master', 'instructor', 'member')),
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    email TEXT,
    password_hash TEXT NOT NULL,
    profile_image TEXT,
    is_active BOOLEAN DEFAULT 1,
    last_login_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. 회원 상세 정보
CREATE TABLE IF NOT EXISTS member_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    birth_date DATE,
    gender TEXT CHECK (gender IN ('male', 'female')),
    emergency_contact TEXT,
    medical_notes TEXT,
    join_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. 강사 상세 정보
CREATE TABLE IF NOT EXISTS instructor_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    specialization TEXT,
    experience_years INTEGER,
    hourly_rate DECIMAL(10,2),
    bio TEXT,
    certifications TEXT, -- JSON 형태로 저장
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4.1. 강사-수업타입 연결 테이블
CREATE TABLE IF NOT EXISTS instructor_class_types (
    instructor_id INTEGER NOT NULL,
    class_type_id INTEGER NOT NULL,
    PRIMARY KEY (instructor_id, class_type_id),
    FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (class_type_id) REFERENCES class_types(id) ON DELETE CASCADE
);

-- 5. 수업 타입 (필라테스, 요가 등)
CREATE TABLE IF NOT EXISTS class_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    duration_minutes INTEGER DEFAULT 50,
    max_capacity INTEGER DEFAULT 1,
    price DECIMAL(10,2),
    color TEXT DEFAULT '#6B4EFF',
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 6. 회원권/패키지 템플릿
CREATE TABLE IF NOT EXISTS membership_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    class_type_id INTEGER,
    total_sessions INTEGER NOT NULL,
    validity_days INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_type_id) REFERENCES class_types(id)
);

-- 7. 회원권 (실제 구매한 패키지)
CREATE TABLE IF NOT EXISTS memberships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    template_id INTEGER NOT NULL,
    remaining_sessions INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'suspended')),
    purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES membership_templates(id)
);

-- 8. 스케줄/예약
CREATE TABLE IF NOT EXISTS schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_type_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    scheduled_at DATETIME NOT NULL,
    duration_minutes INTEGER DEFAULT 50,
    max_capacity INTEGER DEFAULT 1,
    current_capacity INTEGER DEFAULT 0,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    cancelled_at DATETIME,
    cancel_reason TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_type_id) REFERENCES class_types(id),
    FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- 9. 예약 (회원-스케줄 관계)
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    membership_id INTEGER,
    booking_status TEXT DEFAULT 'confirmed' CHECK (booking_status IN ('confirmed', 'cancelled', 'completed', 'no_show')),
    booking_type TEXT DEFAULT 'regular' CHECK (booking_type IN ('regular', 'trial', 'makeup')),
    booked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    cancelled_at DATETIME,
    cancel_reason TEXT,
    FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    UNIQUE(schedule_id, user_id)
);

-- 10. 대기자 명단
CREATE TABLE IF NOT EXISTS waiting_list (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(schedule_id, user_id)
);

-- 11. 결제 내역
CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    membership_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'transfer', 'other')),
    payment_status TEXT DEFAULT 'completed' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    description TEXT,
    receipt_image TEXT,
    paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (membership_id) REFERENCES memberships(id)
);

-- 12. 활동 로그 (시스템 로그)
CREATE TABLE IF NOT EXISTS activity_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    action TEXT NOT NULL,
    target_type TEXT, -- 'schedule', 'booking', 'user' 등
    target_id INTEGER,
    details TEXT, -- JSON 형태로 상세 정보
    ip_address TEXT,
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    -- FOREIGN KEY 제거: 관리자 계정은 파일로 관리되어 DB에 없음
);

-- 13. 센터 설정
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setting_key TEXT NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 14. 알림
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('CLASS_REMINDER', 'CLASS_CANCELLATION', 'MEMBERSHIP_EXPIRING', 'ADMIN_MESSAGE', 'SYSTEM')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT 0,
    related_entity_type TEXT,
    related_entity_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_schedules_instructor ON schedules(instructor_id);
CREATE INDEX IF NOT EXISTS idx_bookings_schedule ON bookings(schedule_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_date ON activity_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read_status ON notifications(user_id, is_read);