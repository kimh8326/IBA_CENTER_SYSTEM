const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

class AdminManager {
    constructor() {
        this.adminConfigPath = path.join(__dirname, '../config/admin.json');
        this.ensureAdminConfig();
    }

    // 관리자 설정 파일 존재 확인 및 생성
    ensureAdminConfig() {
        try {
            if (!fs.existsSync(this.adminConfigPath)) {
                console.log('⚠️ 관리자 설정 파일이 없습니다. 기본 관리자 계정을 생성합니다.');
                this.createDefaultAdmin();
            }
        } catch (error) {
            console.error('관리자 설정 파일 확인 오류:', error);
        }
    }

    // 기본 관리자 계정 생성
    async createDefaultAdmin() {
        try {
            const defaultPassword = 'admin123';
            const passwordHash = await bcrypt.hash(defaultPassword, 10);
            
            const adminConfig = {
                username: 'admin',
                password_hash: passwordHash,
                name: '센터 관리자',
                email: 'admin@center.com',
                created_at: new Date().toISOString(),
                last_updated: new Date().toISOString(),
                note: '관리자 계정은 DB 초기화와 무관하게 별도 관리됩니다'
            };

            // config 디렉토리가 없으면 생성
            const configDir = path.dirname(this.adminConfigPath);
            if (!fs.existsSync(configDir)) {
                fs.mkdirSync(configDir, { recursive: true });
            }

            fs.writeFileSync(this.adminConfigPath, JSON.stringify(adminConfig, null, 2));
            console.log('✅ 기본 관리자 계정이 생성되었습니다.');
            console.log(`   아이디: ${adminConfig.username}`);
            console.log(`   비밀번호: ${defaultPassword}`);
            
        } catch (error) {
            console.error('기본 관리자 계정 생성 실패:', error);
            throw error;
        }
    }

    // 관리자 정보 조회
    getAdminConfig() {
        try {
            const configData = fs.readFileSync(this.adminConfigPath, 'utf8');
            return JSON.parse(configData);
        } catch (error) {
            console.error('관리자 설정 읽기 오류:', error);
            return null;
        }
    }

    // 관리자 로그인 검증
    async validateAdmin(username, password) {
        try {
            const adminConfig = this.getAdminConfig();
            if (!adminConfig) {
                return null;
            }

            // 사용자명 확인
            if (username !== adminConfig.username) {
                return null;
            }

            // 비밀번호 확인
            const isValidPassword = await bcrypt.compare(password, adminConfig.password_hash);
            if (!isValidPassword) {
                return null;
            }

            // 관리자 정보 반환 (비밀번호 해시 제외)
            const { password_hash, ...adminInfo } = adminConfig;
            return {
                id: 1, // 고정 ID (DB와의 호환성을 위해)
                user_type: 'master',
                name: adminInfo.name,
                phone: adminInfo.username,
                email: adminInfo.email,
                profile_image: null,
                is_active: 1,
                last_login_at: null,
                created_at: adminInfo.created_at,
                updated_at: adminInfo.last_updated
            };

        } catch (error) {
            console.error('관리자 로그인 검증 오류:', error);
            return null;
        }
    }

    // 관리자 비밀번호 변경
    async changeAdminPassword(newPassword) {
        try {
            const adminConfig = this.getAdminConfig();
            if (!adminConfig) {
                throw new Error('관리자 설정을 찾을 수 없습니다.');
            }

            const newPasswordHash = await bcrypt.hash(newPassword, 10);
            adminConfig.password_hash = newPasswordHash;
            adminConfig.last_updated = new Date().toISOString();

            fs.writeFileSync(this.adminConfigPath, JSON.stringify(adminConfig, null, 2));
            console.log('✅ 관리자 비밀번호가 변경되었습니다.');
            return true;

        } catch (error) {
            console.error('관리자 비밀번호 변경 오류:', error);
            throw error;
        }
    }

    // 마지막 로그인 시간 업데이트
    updateLastLogin() {
        try {
            const adminConfig = this.getAdminConfig();
            if (adminConfig) {
                adminConfig.last_login_at = new Date().toISOString();
                adminConfig.last_updated = new Date().toISOString();
                fs.writeFileSync(this.adminConfigPath, JSON.stringify(adminConfig, null, 2));
            }
        } catch (error) {
            console.error('관리자 마지막 로그인 업데이트 오류:', error);
        }
    }
}

module.exports = AdminManager;