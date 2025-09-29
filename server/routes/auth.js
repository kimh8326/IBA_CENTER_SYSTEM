const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { authenticateToken } = require('../middleware/auth');
const AdminManager = require('../utils/admin-manager');
const router = express.Router();

// 관리자 매니저 인스턴스 생성
const adminManager = new AdminManager();

const JWT_SECRET = process.env.JWT_SECRET || 'pilates-center-secret-key-2024';

// 로그인
router.post('/login', async (req, res) => {
    try {
        const { phone, password } = req.body;

        if (!phone || !password) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '전화번호와 비밀번호를 입력해주세요.'
            });
        }

        let user = null;

        // 1. 먼저 관리자 계정인지 확인 (파일 기반)
        const adminUser = await adminManager.validateAdmin(phone, password);
        if (adminUser) {
            user = adminUser;
            // 관리자 마지막 로그인 시간 업데이트
            adminManager.updateLastLogin();
            console.log('✅ 관리자 계정으로 로그인 (파일 기반 인증)');
        } else {
            // 2. 일반 사용자 계정 확인 (데이터베이스 기반)
            user = await req.db.getQuery(
                'SELECT * FROM users WHERE phone = ? AND is_active = 1',
                [phone]
            );

            if (!user) {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: '전화번호 또는 비밀번호가 올바르지 않습니다.'
                });
            }

            // 비밀번호 확인
            const isValidPassword = await bcrypt.compare(password, user.password_hash);
            if (!isValidPassword) {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: '전화번호 또는 비밀번호가 올바르지 않습니다.'
                });
            }

            // 마지막 로그인 시간 업데이트 (DB 사용자만)
            await req.db.runQuery(
                'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?',
                [user.id]
            );
        }

        // JWT 토큰 생성
        const token = jwt.sign(
            { 
                userId: user.id, 
                userType: user.user_type,
                phone: user.phone 
            },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        // 활동 로그 기록 (관리자는 파일 기반이므로 DB 로그 생략)
        if (user.user_type !== 'master' || !adminUser) {
            await req.db.runQuery(`
                INSERT INTO activity_logs (user_id, action, target_type, details, ip_address) 
                VALUES (?, 'login', 'auth', ?, ?)
            `, [
                user.id, 
                JSON.stringify({ loginTime: new Date().toISOString() }),
                req.ip
            ]);
        }

        // 비밀번호 제거 후 응답
        const { password_hash, ...userWithoutPassword } = user;

        res.json({
            message: '로그인 성공',
            token,
            user: userWithoutPassword
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '로그인 중 오류가 발생했습니다.'
        });
    }
});

// 토큰 검증
router.get('/verify', authenticateToken, async (req, res) => {
    try {
        // 사용자 정보 조회
        const user = await req.db.getQuery(
            'SELECT id, user_type, name, phone, email, profile_image, is_active, last_login_at, created_at FROM users WHERE id = ?',
            [req.user.userId]
        );

        if (!user || !user.is_active) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: '유효하지 않은 사용자입니다.'
            });
        }

        res.json({
            message: '토큰이 유효합니다.',
            user
        });

    } catch (error) {
        console.error('Token verification error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '토큰 검증 중 오류가 발생했습니다.'
        });
    }
});

// 로그아웃 (클라이언트에서 토큰 삭제)
router.post('/logout', authenticateToken, async (req, res) => {
    try {
        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, details, ip_address) 
            VALUES (?, 'logout', 'auth', ?, ?)
        `, [
            req.user.userId, 
            JSON.stringify({ logoutTime: new Date().toISOString() }),
            req.ip
        ]);

        res.json({
            message: '로그아웃되었습니다.'
        });

    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '로그아웃 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;