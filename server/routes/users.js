const express = require('express');
const bcrypt = require('bcrypt');
const { 
    authenticateToken, 
    requireMaster, 
    requireStaff, 
    requireMemberOwnership,
    dataFilters 
} = require('../middleware/auth');
const router = express.Router();

// 모든 라우트에 인증 적용
router.use(authenticateToken);

// 사용자 목록 조회 (권한별 필터 적용)
router.get('/', requireStaff, async (req, res) => {
    try {
        const { type, page = 1, limit = 20, search } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = 'WHERE u.is_active = 1';
        const params = [];

        // 사용자 타입 필터
        if (type && ['master', 'instructor', 'member'].includes(type)) {
            whereClause += ' AND u.user_type = ?';
            params.push(type);
        }

        // 검색 필터
        if (search) {
            whereClause += ' AND (u.name LIKE ? OR u.phone LIKE ? OR u.email LIKE ?)';
            const searchTerm = `%${search}%`;
            params.push(searchTerm, searchTerm, searchTerm);
        }

        // **핵심: 강사 권한 분리 - 본인 수업 수강생만 조회**
        const instructorFilter = dataFilters.getInstructorMembersFilter(
            req.user.userType, 
            req.user.userId
        );
        whereClause += instructorFilter;

        // 사용자 목록 조회 (프로필 정보 포함)
        const users = await req.db.getAllQuery(`
            SELECT u.id as id, u.user_type, u.name, u.phone, u.email, u.profile_image, 
                   u.is_active, u.last_login_at, u.created_at, u.updated_at,
                   mp.birth_date, mp.gender, mp.join_date, mp.status as member_status,
                   ip.specialization, ip.hourly_rate
            FROM users u
            LEFT JOIN member_profiles mp ON u.id = mp.user_id
            LEFT JOIN instructor_profiles ip ON u.id = ip.user_id
            ${whereClause}
            ORDER BY u.created_at DESC 
            LIMIT ? OFFSET ?
        `, [...params, parseInt(limit), parseInt(offset)]);

        // 총 개수 조회
        const totalResult = await req.db.getQuery(`
            SELECT COUNT(*) as total 
            FROM users u 
            ${whereClause}
        `, params);

        // 강사인 경우 추가 정보 제공
        let additionalInfo = {};
        if (req.user.userType === 'instructor') {
            // 본인이 담당하는 수업 수강생 수
            const memberCount = await req.db.getQuery(`
                SELECT COUNT(DISTINCT b.user_id) as count
                FROM bookings b
                JOIN schedules s ON b.schedule_id = s.id
                WHERE s.instructor_id = ? AND b.booking_status = 'confirmed'
            `, [req.user.userId]);

            additionalInfo = {
                message: '본인이 담당하는 수업의 수강생만 표시됩니다.',
                totalStudents: memberCount.count
            };
        }

        res.json({
            users,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalResult.total,
                totalPages: Math.ceil(totalResult.total / limit)
            },
            ...additionalInfo
        });

    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 특정 사용자 조회
router.get('/:id', async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        
        // 권한 확인 로직
        const isOwnData = req.user.userId === userId;
        const isMaster = req.user.userType === 'master';
        
        // 강사인 경우 본인 수업 수강생인지 확인
        let isInstructorStudent = false;
        if (req.user.userType === 'instructor' && !isOwnData && !isMaster) {
            const studentCheck = await req.db.getQuery(`
                SELECT COUNT(*) as count
                FROM bookings b
                JOIN schedules s ON b.schedule_id = s.id
                WHERE s.instructor_id = ? AND b.user_id = ?
            `, [req.user.userId, userId]);
            
            isInstructorStudent = studentCheck.count > 0;
        }

        if (!isOwnData && !isMaster && !isInstructorStudent) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '접근 권한이 없습니다.'
            });
        }

        // 권한에 따라 조회할 필드 결정
        let userFields = 'id, user_type, name, profile_image, is_active, created_at';
        
        // 본인 데이터이거나 마스터인 경우 전체 정보
        if (isOwnData || isMaster) {
            userFields = 'id, user_type, name, phone, email, profile_image, is_active, last_login_at, created_at, updated_at';
        }
        // 강사가 수강생을 조회하는 경우 민감한 정보 제외
        else if (isInstructorStudent) {
            userFields = 'id, user_type, name, profile_image, created_at';
        }

        const user = await req.db.getQuery(`
            SELECT ${userFields} FROM users WHERE id = ?
        `, [userId]);

        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: '사용자를 찾을 수 없습니다.'
            });
        }

        // 프로필 정보 조회
        let profile = null;
        if (user.user_type === 'member') {
            // 강사가 수강생 정보를 조회하는 경우 제한된 정보만
            const profileFields = (isOwnData || isMaster) 
                ? '*' 
                : 'user_id, birth_date, gender, join_date, status';
                
            profile = await req.db.getQuery(
                `SELECT ${profileFields} FROM member_profiles WHERE user_id = ?`,
                [userId]
            );
        } else if (user.user_type === 'instructor') {
            profile = await req.db.getQuery(
                'SELECT * FROM instructor_profiles WHERE user_id = ?',
                [userId]
            );
        }

        // 강사인 경우 수강 이력 추가
        let classHistory = null;
        if (req.user.userType === 'instructor' && user.user_type === 'member') {
            classHistory = await req.db.getAllQuery(`
                SELECT s.scheduled_at, ct.name as class_type_name, 
                       b.booking_status, b.booking_type
                FROM bookings b
                JOIN schedules s ON b.schedule_id = s.id
                JOIN class_types ct ON s.class_type_id = ct.id
                WHERE s.instructor_id = ? AND b.user_id = ?
                ORDER BY s.scheduled_at DESC
                LIMIT 10
            `, [req.user.userId, userId]);
        }

        res.json({
            user,
            profile,
            ...(classHistory && { classHistory })
        });

    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 사용자 생성 (관리자만 가능)
router.post('/', requireMaster, async (req, res) => {
    try {

        const { user_type, name, phone, email, password, profile } = req.body;

        // 필수 필드 검증
        if (!user_type || !name || !phone || !password) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '사용자 타입, 이름, 전화번호, 비밀번호는 필수입니다.'
            });
        }

        // 전화번호 중복 확인
        const existingUser = await req.db.getQuery(
            'SELECT id FROM users WHERE phone = ?',
            [phone]
        );

        if (existingUser) {
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 사용 중인 전화번호입니다.'
            });
        }

        // 비밀번호 해시화
        const password_hash = await bcrypt.hash(password, 10);

        // 사용자 생성
        const result = await req.db.runQuery(`
            INSERT INTO users (user_type, name, phone, email, password_hash) 
            VALUES (?, ?, ?, ?, ?)
        `, [user_type, name, phone, email, password_hash]);

        const newUserId = result.id;

        // 프로필 정보 추가
        if (profile && user_type === 'member') {
            await req.db.runQuery(`
                INSERT INTO member_profiles (user_id, birth_date, gender, emergency_contact, medical_notes) 
                VALUES (?, ?, ?, ?, ?)
            `, [newUserId, profile.birth_date, profile.gender, profile.emergency_contact, profile.medical_notes]);
        } else if (profile && user_type === 'instructor') {
            await req.db.runQuery(`
                INSERT INTO instructor_profiles (user_id, specialization, hourly_rate, bio, certifications) 
                VALUES (?, ?, ?, ?, ?)
            `, [newUserId, profile.specialization, profile.hourly_rate, profile.bio, JSON.stringify(profile.certifications || [])]);
        }

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'user', ?, ?)
        `, [req.user.userId, newUserId, JSON.stringify({ user_type, name, phone })]);

        // 생성된 사용자 정보 조회
        const newUser = await req.db.getQuery(`
            SELECT id, user_type, name, phone, email, profile_image, is_active, created_at
            FROM users WHERE id = ?
        `, [newUserId]);

        res.status(201).json({
            message: '사용자가 생성되었습니다.',
            user: newUser
        });

    } catch (error) {
        console.error('Create user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 생성 중 오류가 발생했습니다.'
        });
    }
});

// 사용자 정보 수정
router.put('/:id', async (req, res) => {
    try {
        const userId = parseInt(req.params.id);
        const { name, email, profile, phone, password } = req.body;

        // 권한 확인: 본인이거나 마스터만 수정 가능
        if (req.user.userId !== userId && req.user.userType !== 'master') {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 정보만 수정할 수 있습니다.'
            });
        }

        // 전화번호 중복 확인 (변경하는 경우)
        if (phone && phone !== req.user.phone) {
            const existingUser = await req.db.getQuery(
                'SELECT id FROM users WHERE phone = ? AND id != ?',
                [phone, userId]
            );

            if (existingUser) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '이미 사용 중인 전화번호입니다.'
                });
            }
        }

        // 비밀번호 해시화 (변경하는 경우)
        let updateFields = ['name = ?', 'email = ?', 'updated_at = CURRENT_TIMESTAMP'];
        let updateParams = [name, email];

        if (phone) {
            updateFields.push('phone = ?');
            updateParams.push(phone);
        }

        if (password) {
            const hashedPassword = await bcrypt.hash(password, 10);
            updateFields.push('password_hash = ?');
            updateParams.push(hashedPassword);
        }

        updateParams.push(userId);

        // 사용자 기본 정보 수정
        await req.db.runQuery(`
            UPDATE users SET ${updateFields.join(', ')} WHERE id = ?
        `, updateParams);

        // 프로필 정보 수정
        if (profile) {
            const user = await req.db.getQuery('SELECT user_type FROM users WHERE id = ?', [userId]);
            
            if (user.user_type === 'member') {
                await req.db.runQuery(`
                    INSERT OR REPLACE INTO member_profiles 
                    (user_id, birth_date, gender, emergency_contact, medical_notes) 
                    VALUES (?, ?, ?, ?, ?)
                `, [userId, profile.birth_date, profile.gender, profile.emergency_contact, profile.medical_notes]);
            } else if (user.user_type === 'instructor') {
                await req.db.runQuery(`
                    INSERT OR REPLACE INTO instructor_profiles 
                    (user_id, specialization, hourly_rate, bio, certifications) 
                    VALUES (?, ?, ?, ?, ?)
                `, [userId, profile.specialization, profile.hourly_rate, profile.bio, JSON.stringify(profile.certifications || [])]);
            }
        }

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update', 'user', ?, ?)
        `, [req.user.userId, userId, JSON.stringify({ name, email, phoneChanged: !!phone, passwordChanged: !!password })]);

        res.json({
            message: '사용자 정보가 수정되었습니다.'
        });

    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 정보 수정 중 오류가 발생했습니다.'
        });
    }
});

// 사용자 삭제(비활성화) - 마스터만 가능
router.delete('/:id', requireMaster, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        // 자기 자신은 삭제할 수 없음
        if (req.user.userId === userId) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '자기 자신은 비활성화할 수 없습니다.'
            });
        }

        const user = await req.db.getQuery('SELECT * FROM users WHERE id = ?', [userId]);
        
        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: '사용자를 찾을 수 없습니다.'
            });
        }

        // 사용자 비활성화
        await req.db.runQuery(`
            UPDATE users SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
            WHERE id = ?
        `, [userId]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'deactivate', 'user', ?, ?)
        `, [req.user.userId, userId, JSON.stringify({ 
            targetUser: { name: user.name, phone: user.phone, user_type: user.user_type }
        })]);

        res.json({
            message: '사용자가 비활성화되었습니다.'
        });

    } catch (error) {
        console.error('Deactivate user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 비활성화 중 오류가 발생했습니다.'
        });
    }
});

// 사용자 재활성화 - 마스터만 가능
router.patch('/:id/activate', requireMaster, async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        const user = await req.db.getQuery('SELECT * FROM users WHERE id = ?', [userId]);
        
        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: '사용자를 찾을 수 없습니다.'
            });
        }

        // 사용자 재활성화
        await req.db.runQuery(`
            UPDATE users SET is_active = 1, updated_at = CURRENT_TIMESTAMP 
            WHERE id = ?
        `, [userId]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'activate', 'user', ?, ?)
        `, [req.user.userId, userId, JSON.stringify({ 
            targetUser: { name: user.name, phone: user.phone, user_type: user.user_type }
        })]);

        res.json({
            message: '사용자가 재활성화되었습니다.'
        });

    } catch (error) {
        console.error('Activate user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 재활성화 중 오류가 발생했습니다.'
        });
    }
});

// 사용자 통계 - 마스터만 가능
router.get('/stats/overview', requireMaster, async (req, res) => {
    try {
        // 사용자 타입별 통계
        const userStats = await req.db.getAllQuery(`
            SELECT user_type, COUNT(*) as count, is_active
            FROM users 
            GROUP BY user_type, is_active
        `);

        // 최근 7일 가입자
        const recentSignups = await req.db.getQuery(`
            SELECT COUNT(*) as count
            FROM users 
            WHERE created_at >= datetime('now', '-7 days')
        `);

        // 최근 7일 활성 사용자 (로그인한 사용자)
        const activeUsers = await req.db.getQuery(`
            SELECT COUNT(*) as count
            FROM users 
            WHERE last_login_at >= datetime('now', '-7 days') AND is_active = 1
        `);

        res.json({
            userStats,
            recentSignups: recentSignups.count,
            activeUsers: activeUsers.count
        });

    } catch (error) {
        console.error('Get user stats error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '사용자 통계를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 내 정보 조회 (모든 인증된 사용자)
router.get('/me/profile', async (req, res) => {
    try {
        const user = await req.db.getQuery(`
            SELECT id, user_type, name, phone, email, profile_image, 
                   last_login_at, created_at, updated_at
            FROM users WHERE id = ?
        `, [req.user.userId]);

        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: '사용자를 찾을 수 없습니다.'
            });
        }

        // 프로필 정보 조회
        let profile = null;
        if (user.user_type === 'member') {
            profile = await req.db.getQuery(
                'SELECT * FROM member_profiles WHERE user_id = ?',
                [req.user.userId]
            );
        } else if (user.user_type === 'instructor') {
            profile = await req.db.getQuery(
                'SELECT * FROM instructor_profiles WHERE user_id = ?',
                [req.user.userId]
            );
        }

        res.json({
            user,
            profile
        });

    } catch (error) {
        console.error('Get my profile error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '프로필 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 회원 등록 (강사/관리자만 가능)
router.post('/register-member', requireStaff, async (req, res) => {
    try {
        const {
            name,
            phone,
            email,
            password,
            birthDate,
            gender,
            emergencyContact,
            medicalNotes,
            membershipTemplate
        } = req.body;

        // 필수 필드 검증
        if (!name || !phone || !password) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '이름, 전화번호, 비밀번호는 필수입니다.'
            });
        }

        if (!membershipTemplate || !membershipTemplate.templateId) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '회원권 정보는 필수입니다.'
            });
        }

        // 전화번호 중복 확인
        const existingUser = await req.db.getQuery(
            'SELECT id FROM users WHERE phone = ?',
            [phone]
        );

        if (existingUser) {
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 사용 중인 전화번호입니다.'
            });
        }

        // 회원권 템플릿 확인
        const template = await req.db.getQuery(
            'SELECT * FROM membership_templates WHERE id = ? AND is_active = 1',
            [membershipTemplate.templateId]
        );

        if (!template) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '유효하지 않은 회원권 템플릿입니다.'
            });
        }

        // 비밀번호 해시화
        const passwordHash = await bcrypt.hash(password, 10);

        // 트랜잭션 시작
        const db = req.db.db;
        
        return new Promise((resolve, reject) => {
            db.serialize(() => {
                db.run('BEGIN TRANSACTION');
                
                // 1. 사용자 생성
                db.run(`
                    INSERT INTO users (user_type, name, phone, email, password_hash, is_active) 
                    VALUES (?, ?, ?, ?, ?, 1)
                `, ['member', name, phone, email || null, passwordHash], function(err) {
                    if (err) {
                        db.run('ROLLBACK');
                        return reject(err);
                    }
                    
                    const userId = this.lastID;
                    
                    // 2. 회원 프로필 생성
                    db.run(`
                        INSERT INTO member_profiles (
                            user_id, birth_date, gender, emergency_contact, 
                            medical_notes, status
                        ) VALUES (?, ?, ?, ?, ?, 'active')
                    `, [userId, birthDate || null, gender || null, 
                        emergencyContact || null, medicalNotes || null], function(err) {
                        if (err) {
                            db.run('ROLLBACK');
                            return reject(err);
                        }
                        
                        // 3. 회원권 생성
                        const startDate = membershipTemplate.startDate || new Date().toISOString().split('T')[0];
                        const endDate = new Date(startDate);
                        endDate.setDate(endDate.getDate() + template.validity_days);
                        
                        db.run(`
                            INSERT INTO memberships (
                                user_id, template_id, remaining_sessions, 
                                start_date, end_date, purchase_price, status
                            ) VALUES (?, ?, ?, ?, ?, ?, 'active')
                        `, [
                            userId, 
                            template.id, 
                            template.total_sessions,
                            startDate,
                            endDate.toISOString().split('T')[0],
                            membershipTemplate.purchasePrice
                        ], function(err) {
                            if (err) {
                                db.run('ROLLBACK');
                                return reject(err);
                            }
                            
                            const membershipId = this.lastID;
                            
                            // 4. 결제 기록 생성
                            db.run(`
                                INSERT INTO payments (
                                    user_id, membership_id, amount, payment_method, 
                                    payment_status, description
                                ) VALUES (?, ?, ?, ?, 'completed', '회원권 구매')
                            `, [
                                userId, 
                                membershipId, 
                                membershipTemplate.purchasePrice,
                                membershipTemplate.paymentMethod || 'card'
                            ], function(err) {
                                if (err) {
                                    db.run('ROLLBACK');
                                    return reject(err);
                                }
                                
                                // 5. 활동 로그 기록
                                db.run(`
                                    INSERT INTO activity_logs (
                                        user_id, action, target_type, target_id, details
                                    ) VALUES (?, 'create', 'member', ?, ?)
                                `, [
                                    req.user.userId, 
                                    userId, 
                                    JSON.stringify({
                                        member_name: name,
                                        membership_template: template.name,
                                        purchase_price: membershipTemplate.purchasePrice,
                                        registered_by: req.user.name
                                    })
                                ], function(err) {
                                    if (err) {
                                        db.run('ROLLBACK');
                                        return reject(err);
                                    }
                                    
                                    db.run('COMMIT', (err) => {
                                        if (err) {
                                            db.run('ROLLBACK');
                                            return reject(err);
                                        }
                                        
                                        resolve({
                                            success: true,
                                            userId,
                                            membershipId,
                                            message: '회원이 성공적으로 등록되었습니다.',
                                            memberInfo: {
                                                name,
                                                phone,
                                                membershipTemplate: template.name,
                                                validUntil: endDate.toISOString().split('T')[0]
                                            }
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        }).then(result => {
            res.status(201).json(result);
        }).catch(error => {
            console.error('Register member error:', error);
            res.status(500).json({
                error: 'Internal Server Error',
                message: '회원 등록 중 오류가 발생했습니다.',
                details: error.message
            });
        });

    } catch (error) {
        console.error('Register member error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원 등록 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;