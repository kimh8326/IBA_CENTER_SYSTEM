const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

class Database {
    constructor() {
        this.db = null;
    }

    async initialize() {
        try {
            // 데이터베이스 파일 경로
            const dbPath = path.join(__dirname, 'pilates_center.db');
            
            // 데이터베이스 연결
            this.db = new sqlite3.Database(dbPath, (err) => {
                if (err) {
                    console.error('Database connection error:', err);
                } else {
                    console.log('✅ Connected to SQLite database');
                }
            });

            // 외래 키 제약조건 활성화
            await this.runQuery('PRAGMA foreign_keys = ON');

            // 스키마 생성
            await this.createTables();
            
            // 초기 데이터 삽입
            await this.insertInitialData();

            console.log('🚀 Database initialized successfully');
            
        } catch (error) {
            console.error('❌ Database initialization failed:', error);
            throw error;
        }
    }

    async createTables() {
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');
        
        // SQL 문을 개별적으로 실행
        const statements = schema.split(';').filter(stmt => stmt.trim());
        
        for (const statement of statements) {
            if (statement.trim()) {
                await this.runQuery(statement);
            }
        }
    }

    async insertInitialData() {
        // 기본 센터 정보
        await this.runQuery(`
            INSERT OR IGNORE INTO centers (id, name, address, phone) 
            VALUES (1, '데모 필라테스 스튜디오', '서울시 강남구', '02-1234-5678')
        `);

        // 기본 관리자 계정 생성 (비밀번호: admin123)
        const hashedPassword = await bcrypt.hash('admin123', 10);
        await this.runQuery(`
            INSERT OR IGNORE INTO users (id, user_type, name, phone, password_hash) 
            VALUES (1, 'master', '관리자', 'admin', ?)
        `, [hashedPassword]);

        // 기본 수업 타입 (관리자가 직접 추가하도록 비활성화)
        // await this.runQuery(`
        //     INSERT OR IGNORE INTO class_types (name, description, duration_minutes, max_capacity, price, color) 
        //     VALUES 
        //         ('1:1 필라테스', '개인 레슨', 50, 1, 80000, '#6B4EFF'),
        //         ('그룹 필라테스', '소그룹 레슨', 50, 4, 25000, '#00BCD4'),
        //         ('요가', '요가 클래스', 60, 6, 20000, '#4CAF50')
        // `);

        // 기본 회원권 템플릿 (관리자가 직접 추가하도록 비활성화)
        // await this.runQuery(`
        //     INSERT OR IGNORE INTO membership_templates (name, description, class_type_id, total_sessions, validity_days, price) 
        //     VALUES 
        //         ('1:1 10회권', '개인 레슨 10회', 1, 10, 90, 750000),
        //         ('1:1 20회권', '개인 레슨 20회', 1, 20, 180, 1400000),
        //         ('그룹 10회권', '소그룹 레슨 10회', 2, 10, 60, 220000),
        //         ('그룹 20회권', '소그룹 레슨 20회', 2, 20, 90, 400000)
        // `);

        // 기본 설정 (관리자가 직접 추가하도록 비활성화)
        // const defaultSettings = [
        //     ['business_hours_start', '06:00', '영업 시작 시간'],
        //     ['business_hours_end', '22:00', '영업 종료 시간'],
        //     ['booking_advance_days', '30', '최대 예약 가능 일수'],
        //     ['cancellation_hours', '24', '최소 취소 가능 시간'],
        //     ['allow_waiting_list', 'true', '대기자 명단 허용 여부'],
        //     ['auto_confirm_past_sessions', 'true', '과거 세션 자동 확정']
        // ];

        // for (const [key, value, description] of defaultSettings) {
        //     await this.runQuery(`
        //         INSERT OR IGNORE INTO settings (setting_key, setting_value, description) 
        //         VALUES (?, ?, ?)
        //     `, [key, value, description]);
        // }

        console.log('📝 Initial data inserted successfully');
        console.log('👤 Admin account initialized');
    }

    runQuery(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.run(sql, params, function(err) {
                if (err) {
                    console.error('SQL Error:', err);
                    reject(err);
                } else {
                    resolve({ id: this.lastID, changes: this.changes });
                }
            });
        });
    }

    getQuery(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.get(sql, params, (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    getAllQuery(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.all(sql, params, (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    // 데이터베이스 연결 재설정 (DB 초기화 후 사용)
    async reconnect() {
        try {
            // 기존 연결이 있다면 닫기
            if (this.db) {
                await this.close();
            }

            // 새 연결 생성
            const dbPath = path.join(__dirname, 'pilates_center.db');
            
            this.db = new sqlite3.Database(dbPath, (err) => {
                if (err) {
                    console.error('Database reconnection error:', err);
                } else {
                    console.log('✅ Database reconnected successfully');
                }
            });

            // 외래 키 제약조건 다시 활성화
            await this.runQuery('PRAGMA foreign_keys = ON');
            
            return true;
        } catch (error) {
            console.error('Database reconnection failed:', error);
            return false;
        }
    }

    close() {
        return new Promise((resolve) => {
            if (this.db) {
                this.db.close((err) => {
                    if (err) {
                        console.error('Error closing database:', err);
                    } else {
                        console.log('Database connection closed');
                    }
                    this.db = null;
                    resolve();
                });
            } else {
                resolve();
            }
        });
    }
}

module.exports = Database;