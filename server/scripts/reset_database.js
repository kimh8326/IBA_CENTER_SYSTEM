const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');

const dbPath = path.join(__dirname, '../database/pilates_center.db');
const schemaPath = path.join(__dirname, '../database/schema.sql');

class DatabaseResetter {
  constructor() {
    this.db = new sqlite3.Database(dbPath);
  }

  async resetDatabase() {
    console.log('🗑️  데이터베이스 초기화 시작...\n');

    try {
      // 1. 기존 데이터베이스 파일 삭제 및 재생성
      await this.recreateDatabase();
      
      // 2. 스키마 생성
      await this.createSchema();
      
      // 3. 기본 데이터 삽입
      await this.insertBasicData();
      
      // 4. 샘플 데이터 삽입 (개발용 - 프로덕션에서는 비활성화)
      // await this.insertSampleData();
      
      console.log('\n🎉 데이터베이스 초기화 완료!');
      console.log('📊 생성된 데이터:');
      await this.showDataSummary();
      
    } catch (error) {
      console.error('❌ 데이터베이스 초기화 실패:', error);
      throw error;
    } finally {
      this.db.close();
    }
  }

  async recreateDatabase() {
    return new Promise((resolve, reject) => {
      this.db.close(() => {
        // 기존 DB 파일 삭제
        if (fs.existsSync(dbPath)) {
          fs.unlinkSync(dbPath);
          console.log('✅ 기존 데이터베이스 파일 삭제');
        }
        
        // 새 DB 생성
        this.db = new sqlite3.Database(dbPath, (err) => {
          if (err) reject(err);
          else {
            console.log('✅ 새 데이터베이스 파일 생성');
            
            // 파일 권한 설정 (읽기/쓰기 가능)
            try {
              fs.chmodSync(dbPath, 0o664);
              console.log('✅ 데이터베이스 파일 권한 설정');
            } catch (chmodErr) {
              console.warn('⚠️ 파일 권한 설정 실패:', chmodErr.message);
            }
            
            resolve();
          }
        });
      });
    });
  }

  async createSchema() {
    return new Promise((resolve, reject) => {
      const schema = fs.readFileSync(schemaPath, 'utf8');
      this.db.exec(schema, (err) => {
        if (err) reject(err);
        else {
          console.log('✅ 데이터베이스 스키마 생성 완료');
          resolve();
        }
      });
    });
  }

  async insertBasicData() {
    console.log('\n📝 기본 데이터 삽입...');

    // 1. 센터 정보
    await this.runQuery(`
      INSERT INTO centers (name, address, phone, email, business_number)
      VALUES (?, ?, ?, ?, ?)
    `, ['럭셔리 필라테스', '서울시 강남구 테헤란로 123', '02-1234-5678', 'info@luxury-pilates.com', '123-45-67890']);
    console.log('✅ 센터 정보 생성');

    // 2. 관리자 계정은 별도 파일로 관리 (DB 초기화와 독립적)
    console.log('✅ 관리자 계정은 별도 관리 (config/admin.json)');

    // 3. 기본 수업 타입 (관리자가 직접 추가하도록 비활성화)
    // const classTypes = [...];
    // 필요시 관리자가 수업 타입 관리에서 직접 추가
    console.log('ℹ️ 수업 타입은 관리자가 직접 추가해주세요');

    // 4. 회원권 템플릿 (관리자가 직접 추가하도록 비활성화)
    // 필요시 관리자가 회원권 관리에서 직접 추가
    console.log('ℹ️ 회원권 템플릿은 관리자가 직접 추가해주세요');

    // 5. 센터 설정 (관리자가 직접 추가하도록 비활성화)
    // 필요시 관리자가 설정에서 직접 추가
    console.log('ℹ️ 센터 설정은 관리자가 직접 추가해주세요');
    
    console.log('✅ 필수 데이터 생성 완료 (센터 정보)');
  }

  async insertSampleData() {
    console.log('\n🎯 샘플 데이터 생성...');

    // 1. 강사 계정들
    const instructors = [
      { name: '김필라테스', phone: '010-1111-1111', email: 'kim@center.com', spec: '매트, 기구 전문', years: 5, rate: 50000 },
      { name: '이요가', phone: '010-2222-2222', email: 'lee@center.com', spec: '재활, 개인레슨 전문', years: 8, rate: 60000 },
      { name: '박바디', phone: '010-3333-3333', email: 'park@center.com', spec: '그룹수업, 매트 전문', years: 3, rate: 40000 }
    ];

    const instructorIds = [];
    for (const inst of instructors) {
      const password = await bcrypt.hash('instructor123', 10);
      const result = await this.runQuery(`
        INSERT INTO users (user_type, name, phone, email, password_hash, is_active)
        VALUES (?, ?, ?, ?, ?, 1)
      `, ['instructor', inst.name, inst.phone, inst.email, password]);
      
      instructorIds.push(result.id);
      
      await this.runQuery(`
        INSERT INTO instructor_profiles (user_id, specialization, experience_years, hourly_rate, bio, certifications)
        VALUES (?, ?, ?, ?, ?, ?)
      `, [result.id, inst.spec, inst.years, inst.rate, `${inst.name} 강사입니다.`, '["PMA 자격증", "국제 요가 자격증"]']);
    }
    console.log('✅ 강사 계정 3개 생성');

    // 2. 회원 계정들  
    const members = [
      { name: '홍길동', phone: '010-1000-0001', email: 'hong@test.com', gender: 'male', birth: '1990-01-01' },
      { name: '김영희', phone: '010-1000-0002', email: 'kim@test.com', gender: 'female', birth: '1985-05-15' },
      { name: '이철수', phone: '010-1000-0003', email: 'lee@test.com', gender: 'male', birth: '1992-08-20' },
      { name: '박미영', phone: '010-1000-0004', email: 'park@test.com', gender: 'female', birth: '1988-12-03' },
      { name: '최수진', phone: '010-1000-0005', email: 'choi@test.com', gender: 'female', birth: '1995-03-10' }
    ];

    const memberIds = [];
    for (const member of members) {
      const password = await bcrypt.hash('member123', 10);
      const result = await this.runQuery(`
        INSERT INTO users (user_type, name, phone, email, password_hash, is_active)
        VALUES (?, ?, ?, ?, ?, 1)
      `, ['member', member.name, member.phone, member.email, password]);
      
      memberIds.push(result.id);
      
      await this.runQuery(`
        INSERT INTO member_profiles (user_id, birth_date, gender, emergency_contact, medical_notes, status)
        VALUES (?, ?, ?, ?, ?, 'active')
      `, [result.id, member.birth, member.gender, '010-9999-9999', '특이사항 없음']);
    }
    console.log('✅ 회원 계정 5개 생성');

    // 3. 회원권 구매 내역
    for (let i = 0; i < memberIds.length; i++) {
      const memberId = memberIds[i];
      const templateId = Math.floor(Math.random() * 6) + 1; // 1-6 랜덤
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - Math.floor(Math.random() * 30)); // 최근 30일 내 시작
      
      const membershipResult = await this.runQuery(`
        INSERT INTO memberships (user_id, template_id, remaining_sessions, start_date, end_date, purchase_price, status)
        VALUES (?, ?, ?, ?, ?, ?, 'active')
      `, [memberId, templateId, 10 - Math.floor(Math.random() * 5), startDate.toISOString().split('T')[0], 
          new Date(startDate.getTime() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], 
          Math.floor(Math.random() * 500000) + 200000]);

      // 결제 내역도 생성
      await this.runQuery(`
        INSERT INTO payments (user_id, membership_id, amount, payment_method, payment_status, description)
        VALUES (?, ?, ?, ?, 'completed', '회원권 구매')
      `, [memberId, membershipResult.id, Math.floor(Math.random() * 500000) + 200000, 
          ['card', 'cash', 'transfer'][Math.floor(Math.random() * 3)]]);
    }
    console.log('✅ 회원권 구매 내역 5개 생성');

    // 4. 2주간의 스케줄 생성
    const today = new Date();
    const scheduleIds = [];
    
    for (let day = 0; day < 14; day++) {
      const scheduleDate = new Date(today);
      scheduleDate.setDate(today.getDate() + day);
      
      // 주말 제외
      if (scheduleDate.getDay() === 0 || scheduleDate.getDay() === 6) continue;
      
      // 하루에 4-8개 수업
      const classCount = Math.floor(Math.random() * 5) + 4;
      const usedTimes = new Set();
      
      for (let c = 0; c < classCount; c++) {
        let hour;
        do {
          hour = Math.floor(Math.random() * 12) + 8; // 8시-19시
        } while (usedTimes.has(hour));
        usedTimes.add(hour);
        
        const classTypeId = Math.floor(Math.random() * 6) + 1;
        const instructorId = instructorIds[Math.floor(Math.random() * instructorIds.length)];
        const scheduledAt = new Date(scheduleDate);
        scheduledAt.setHours(hour, 0, 0, 0);
        
        const result = await this.runQuery(`
          INSERT INTO schedules (class_type_id, instructor_id, scheduled_at, duration_minutes, max_capacity, current_capacity, status)
          VALUES (?, ?, ?, ?, ?, ?, 'scheduled')
        `, [classTypeId, instructorId, scheduledAt.toISOString(), 
            [50, 60][Math.floor(Math.random() * 2)], 
            [1, 2, 4, 8][Math.floor(Math.random() * 4)], 0]);
        
        scheduleIds.push(result.id);
      }
    }
    console.log(`✅ 2주간 스케줄 ${scheduleIds.length}개 생성`);

    // 5. 예약 생성 (스케줄의 50% 정도 예약)
    const bookingCount = Math.floor(scheduleIds.length * 0.5);
    for (let i = 0; i < bookingCount; i++) {
      const scheduleId = scheduleIds[Math.floor(Math.random() * scheduleIds.length)];
      const memberId = memberIds[Math.floor(Math.random() * memberIds.length)];
      
      try {
        await this.runQuery(`
          INSERT INTO bookings (schedule_id, user_id, booking_status, booking_type)
          VALUES (?, ?, 'confirmed', 'regular')
        `, [scheduleId, memberId]);

        // 스케줄의 current_capacity 업데이트
        await this.runQuery(`
          UPDATE schedules SET current_capacity = current_capacity + 1 WHERE id = ?
        `, [scheduleId]);
      } catch (err) {
        // 중복 예약 무시
      }
    }
    console.log(`✅ 예약 ${bookingCount}개 생성`);
  }

  async showDataSummary() {
    const queries = [
      { name: '센터', query: 'SELECT COUNT(*) as count FROM centers' },
      { name: '사용자', query: 'SELECT COUNT(*) as count FROM users' },
      { name: '강사', query: 'SELECT COUNT(*) as count FROM users WHERE user_type = "instructor"' },
      { name: '회원', query: 'SELECT COUNT(*) as count FROM users WHERE user_type = "member"' },
      { name: '수업타입', query: 'SELECT COUNT(*) as count FROM class_types' },
      { name: '회원권템플릿', query: 'SELECT COUNT(*) as count FROM membership_templates' },
      { name: '구매한회원권', query: 'SELECT COUNT(*) as count FROM memberships' },
      { name: '스케줄', query: 'SELECT COUNT(*) as count FROM schedules' },
      { name: '예약', query: 'SELECT COUNT(*) as count FROM bookings' },
      { name: '결제내역', query: 'SELECT COUNT(*) as count FROM payments' }
    ];

    for (const q of queries) {
      const result = await this.getQuery(q.query);
      console.log(`   ${q.name}: ${result.count}개`);
    }
  }

  runQuery(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err) {
        if (err) reject(err);
        else resolve({ id: this.lastID, changes: this.changes });
      });
    });
  }

  getQuery(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }
}

// 모듈 내보내기
module.exports = DatabaseResetter;

// 직접 실행시에만 실행
if (require.main === module) {
  const resetter = new DatabaseResetter();
  resetter.resetDatabase()
    .then(() => {
      console.log('\n✅ 데이터베이스 초기화가 완료되었습니다.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('데이터베이스 초기화 실패:', error);
      process.exit(1);
    });
}