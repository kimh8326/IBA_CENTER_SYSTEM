const express = require('express');
const bcrypt = require('bcrypt');
const { 
    authenticateToken, 
    requireMaster, 
    requireInstructorOwnership,
    requireStaff
} = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 강사 목록 조회 (마스터 전용)
router.get('/', requireMaster, async (req, res) => {
    try {
        const { status = 'active', search } = req.query;
        
        let whereClause = 'WHERE u.user_type = "instructor"';
        const params = [];

        if (status === 'active') {
            whereClause += ' AND u.is_active = 1';
        } else if (status === 'inactive') {
            whereClause += ' AND u.is_active = 0';
        }

        if (search) {
            whereClause += ' AND (u.name LIKE ? OR u.phone LIKE ? OR u.email LIKE ?)';
            const searchTerm = `%${search}%`;
            params.push(searchTerm, searchTerm, searchTerm);
        }

        const instructors = await req.db.getAllQuery(`
            SELECT 
                u.id as id, u.user_type, u.name, u.phone, u.email, u.profile_image,
                u.is_active, u.last_login_at, u.created_at, u.updated_at,
                ip.specialization as specializations,
                ip.hourly_rate,
                ip.bio,
                ip.certifications,
                ip.experience_years
            FROM users u
            LEFT JOIN instructor_profiles ip ON u.id = ip.user_id
            ${whereClause}
            ORDER BY u.created_at DESC
        `, params);

        // 각 강사별 통계 정보 추가
        for (let instructor of instructors) {
            // 이번 달 수업 수
            const thisMonthClasses = await req.db.getQuery(`
                SELECT COUNT(*) as count 
                FROM schedules 
                WHERE instructor_id = ? 
                AND DATE(scheduled_at) >= DATE('now', 'start of month')
                AND DATE(scheduled_at) < DATE('now', 'start of month', '+1 month')
                AND status != 'cancelled'
            `, [instructor.id]);

            // 총 수강생 수 (중복 제거)
            const totalStudents = await req.db.getQuery(`
                SELECT COUNT(DISTINCT b.user_id) as count
                FROM bookings b
                JOIN schedules s ON b.schedule_id = s.id
                WHERE s.instructor_id = ?
                AND b.booking_status != 'cancelled'
            `, [instructor.id]);

            instructor.thisMonthClasses = thisMonthClasses.count || 0;
            instructor.totalStudents = totalStudents.count || 0;
        }

        res.json({ instructors });

    } catch (error) {
        console.error('Get instructors error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 특정 강사 정보 조회 (강사 본인 또는 마스터)
router.get('/:id', requireStaff, async (req, res) => {
    try {
        const instructorId = parseInt(req.params.id);

        // 강사는 본인 정보만 조회 가능
        if (req.user.userType === 'instructor' && req.user.userId !== instructorId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 정보만 조회할 수 있습니다.'
            });
        }

        const instructor = await req.db.getQuery(`
            SELECT 
                u.id as id, u.user_type, u.name, u.phone, u.email, u.profile_image,
                u.is_active, u.last_login_at, u.created_at, u.updated_at,
                ip.specialization as specializations,
                ip.experience_years,
                ip.certifications,
                ip.hourly_rate,
                ip.bio
            FROM users u
            LEFT JOIN instructor_profiles ip ON u.id = ip.user_id
            WHERE u.id = ? AND u.user_type = 'instructor'
        `, [instructorId]);

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '강사를 찾을 수 없습니다.'
            });
        }

        // 강사 통계 정보 추가
        const stats = await req.db.getAllQuery(`
            SELECT 
                COUNT(DISTINCT s.id) as total_classes,
                COUNT(DISTINCT b.user_id) as total_students,
                COUNT(DISTINCT CASE WHEN DATE(s.scheduled_at) >= DATE('now', 'start of month') 
                    AND DATE(s.scheduled_at) < DATE('now', 'start of month', '+1 month') 
                    THEN s.id END) as this_month_classes
            FROM schedules s
            LEFT JOIN bookings b ON s.id = b.schedule_id AND b.booking_status != 'cancelled'
            WHERE s.instructor_id = ? AND s.status != 'cancelled'
        `, [instructorId]);

        instructor.stats = stats[0] || {
            total_classes: 0,
            total_students: 0,
            this_month_classes: 0
        };

        res.json({ instructor });

    } catch (error) {
        console.error('Get instructor error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 강사 생성 (마스터 전용)
router.post('/', requireMaster, async (req, res) => {
    try {
        const { 
            name, phone, email, password,
            specializations, experience_years, certifications,
            hourly_rate, bio 
        } = req.body;

        if (!name || !phone || !password) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '이름, 전화번호, 비밀번호는 필수입니다.'
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
                message: '이미 등록된 전화번호입니다.'
            });
        }

        // 이메일 중복 확인 (있는 경우)
        if (email) {
            const existingEmail = await req.db.getQuery(
                'SELECT id FROM users WHERE email = ?',
                [email]
            );

            if (existingEmail) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '이미 등록된 이메일입니다.'
                });
            }
        }

        // 비밀번호 해시화
        const passwordHash = await bcrypt.hash(password, 10);

        // 강사 기본 정보 생성
        const result = await req.db.runQuery(`
            INSERT INTO users (
                user_type, name, phone, email, password_hash, is_active
            ) VALUES (?, ?, ?, ?, ?, 1)
        `, [
            'instructor', name, phone, email, passwordHash
        ]);

        // 강사 상세 정보 생성
        if (specializations || experience_years || certifications || hourly_rate || bio) {
            await req.db.runQuery(`
                INSERT INTO instructor_profiles (
                    user_id, specialization, experience_years, certifications, hourly_rate, bio
                ) VALUES (?, ?, ?, ?, ?, ?)
            `, [
                result.id, specializations, experience_years, certifications, hourly_rate, bio
            ]);
        }

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'instructor', ?, ?)
        `, [
            req.user.userId, 
            result.id, 
            JSON.stringify({ name, phone, email })
        ]);

        res.status(201).json({
            message: '강사가 생성되었습니다.',
            instructor_id: result.id
        });

    } catch (error) {
        console.error('Create instructor error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 생성 중 오류가 발생했습니다.'
        });
    }
});

// 강사 정보 수정 (마스터 또는 강사 본인)
router.put('/:id', requireStaff, async (req, res) => {
    try {
        const instructorId = parseInt(req.params.id);

        // 강사는 본인 정보만 수정 가능
        if (req.user.userType === 'instructor' && req.user.userId !== instructorId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 정보만 수정할 수 있습니다.'
            });
        }

        const instructor = await req.db.getQuery(
            'SELECT id FROM users WHERE id = ? AND user_type = "instructor"',
            [instructorId]
        );

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '강사를 찾을 수 없습니다.'
            });
        }

        const { 
            name, email, 
            specializations, experience_years, certifications,
            hourly_rate, bio 
        } = req.body;

        // 기본 정보 업데이트 (users 테이블)
        const userUpdateFields = [];
        const userUpdateParams = [];

        if (name) {
            userUpdateFields.push('name = ?');
            userUpdateParams.push(name);
        }

        if (email !== undefined) {
            // 이메일 중복 확인 (다른 사용자)
            if (email) {
                const existingEmail = await req.db.getQuery(
                    'SELECT id FROM users WHERE email = ? AND id != ?',
                    [email, instructorId]
                );

                if (existingEmail) {
                    return res.status(409).json({
                        error: 'Conflict',
                        message: '이미 등록된 이메일입니다.'
                    });
                }
            }

            userUpdateFields.push('email = ?');
            userUpdateParams.push(email);
        }

        // 기본 정보 업데이트 실행
        if (userUpdateFields.length > 0) {
            userUpdateParams.push(instructorId);
            await req.db.runQuery(`
                UPDATE users 
                SET ${userUpdateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            `, userUpdateParams);
        }

        // 강사 상세 정보 업데이트 (instructor_profiles 테이블)
        if (specializations !== undefined || experience_years !== undefined || 
            certifications !== undefined || hourly_rate !== undefined || bio !== undefined) {
            
            // 기존 프로필 확인
            const existingProfile = await req.db.getQuery(
                'SELECT id FROM instructor_profiles WHERE user_id = ?',
                [instructorId]
            );

            if (existingProfile) {
                // 기존 프로필 업데이트
                const profileUpdateFields = [];
                const profileUpdateParams = [];

                if (specializations !== undefined) {
                    profileUpdateFields.push('specialization = ?');
                    profileUpdateParams.push(specializations);
                }

                if (experience_years !== undefined) {
                    profileUpdateFields.push('experience_years = ?');
                    profileUpdateParams.push(experience_years);
                }

                if (certifications !== undefined) {
                    profileUpdateFields.push('certifications = ?');
                    profileUpdateParams.push(certifications);
                }

                if (hourly_rate !== undefined) {
                    profileUpdateFields.push('hourly_rate = ?');
                    profileUpdateParams.push(hourly_rate);
                }

                if (bio !== undefined) {
                    profileUpdateFields.push('bio = ?');
                    profileUpdateParams.push(bio);
                }

                if (profileUpdateFields.length > 0) {
                    profileUpdateParams.push(instructorId);
                    await req.db.runQuery(`
                        UPDATE instructor_profiles 
                        SET ${profileUpdateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
                        WHERE user_id = ?
                    `, profileUpdateParams);
                }
            } else {
                // 새 프로필 생성
                await req.db.runQuery(`
                    INSERT INTO instructor_profiles (
                        user_id, specialization, experience_years, certifications, hourly_rate, bio
                    ) VALUES (?, ?, ?, ?, ?, ?)
                `, [instructorId, specializations, experience_years, certifications, hourly_rate, bio]);
            }
        }

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update', 'instructor', ?, ?)
        `, [
            req.user.userId, 
            instructorId, 
            JSON.stringify({ updatedFields: Object.keys(req.body) })
        ]);

        res.json({
            message: '강사 정보가 수정되었습니다.'
        });

    } catch (error) {
        console.error('Update instructor error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 정보 수정 중 오류가 발생했습니다.'
        });
    }
});

// 강사 비활성화/활성화 (마스터 전용)
router.put('/:id/status', requireMaster, async (req, res) => {
    try {
        const instructorId = parseInt(req.params.id);
        const { is_active } = req.body;

        if (typeof is_active !== 'boolean') {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'is_active 값이 필요합니다.'
            });
        }

        const instructor = await req.db.getQuery(
            'SELECT id, name FROM users WHERE id = ? AND user_type = "instructor"',
            [instructorId]
        );

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '강사를 찾을 수 없습니다.'
            });
        }

        await req.db.runQuery(
            'UPDATE users SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [is_active ? 1 : 0, instructorId]
        );

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, ?, 'instructor', ?, ?)
        `, [
            req.user.userId, 
            is_active ? 'activate' : 'deactivate',
            instructorId, 
            JSON.stringify({ instructor_name: instructor.name })
        ]);

        res.json({
            message: `강사가 ${is_active ? '활성화' : '비활성화'}되었습니다.`
        });

    } catch (error) {
        console.error('Update instructor status error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 상태 변경 중 오류가 발생했습니다.'
        });
    }
});

// 강사 비밀번호 변경 (강사 본인 또는 마스터)
router.put('/:id/password', requireStaff, async (req, res) => {
    try {
        const instructorId = parseInt(req.params.id);
        const { current_password, new_password } = req.body;

        // 강사는 본인 비밀번호만 변경 가능
        if (req.user.userType === 'instructor' && req.user.userId !== instructorId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 비밀번호만 변경할 수 있습니다.'
            });
        }

        if (!new_password) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '새 비밀번호를 입력해주세요.'
            });
        }

        const instructor = await req.db.getQuery(
            'SELECT id, password_hash FROM users WHERE id = ? AND user_type = "instructor"',
            [instructorId]
        );

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '강사를 찾을 수 없습니다.'
            });
        }

        // 강사가 본인 비밀번호를 변경하는 경우 현재 비밀번호 확인
        if (req.user.userType === 'instructor') {
            if (!current_password) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '현재 비밀번호를 입력해주세요.'
                });
            }

            const isValidPassword = await bcrypt.compare(current_password, instructor.password_hash);
            if (!isValidPassword) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '현재 비밀번호가 올바르지 않습니다.'
                });
            }
        }

        // 새 비밀번호 해시화
        const newPasswordHash = await bcrypt.hash(new_password, 10);

        await req.db.runQuery(
            'UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [newPasswordHash, instructorId]
        );

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update_password', 'instructor', ?, ?)
        `, [
            req.user.userId, 
            instructorId, 
            JSON.stringify({ changedBy: req.user.userType })
        ]);

        res.json({
            message: '비밀번호가 변경되었습니다.'
        });

    } catch (error) {
        console.error('Change instructor password error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '비밀번호 변경 중 오류가 발생했습니다.'
        });
    }
});

// 강사별 수업 통계 (마스터 전용)
router.get('/:id/stats', requireMaster, async (req, res) => {
    try {
        const instructorId = parseInt(req.params.id);
        const { year = new Date().getFullYear(), month } = req.query;

        const instructor = await req.db.getQuery(
            'SELECT id, name FROM users WHERE id = ? AND user_type = "instructor"',
            [instructorId]
        );

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '강사를 찾을 수 없습니다.'
            });
        }

        let dateFilter = '';
        const params = [instructorId];

        if (month) {
            dateFilter = 'AND strftime("%Y", s.scheduled_at) = ? AND strftime("%m", s.scheduled_at) = ?';
            params.push(year.toString(), month.toString().padStart(2, '0'));
        } else {
            dateFilter = 'AND strftime("%Y", s.scheduled_at) = ?';
            params.push(year.toString());
        }

        // 월별 수업 통계
        const monthlyStats = await req.db.getAllQuery(`
            SELECT 
                strftime("%Y-%m", s.scheduled_at) as month,
                COUNT(s.id) as total_classes,
                COUNT(DISTINCT b.user_id) as unique_students,
                COUNT(b.id) as total_bookings,
                AVG(s.current_capacity) as avg_capacity
            FROM schedules s
            LEFT JOIN bookings b ON s.id = b.schedule_id AND b.booking_status != 'cancelled'
            WHERE s.instructor_id = ? ${dateFilter} AND s.status != 'cancelled'
            GROUP BY strftime("%Y-%m", s.scheduled_at)
            ORDER BY month
        `, params);

        // 수업 유형별 통계
        const classTypeStats = await req.db.getAllQuery(`
            SELECT 
                ct.name as class_type,
                COUNT(s.id) as class_count,
                COUNT(b.id) as total_bookings,
                AVG(s.current_capacity) as avg_capacity
            FROM schedules s
            LEFT JOIN class_types ct ON s.class_type_id = ct.id
            LEFT JOIN bookings b ON s.id = b.schedule_id AND b.booking_status != 'cancelled'
            WHERE s.instructor_id = ? ${dateFilter} AND s.status != 'cancelled'
            GROUP BY ct.id, ct.name
            ORDER BY class_count DESC
        `, params);

        res.json({
            instructor: instructor.name,
            period: month ? `${year}-${month}` : year.toString(),
            monthlyStats,
            classTypeStats
        });

    } catch (error) {
        console.error('Get instructor stats error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '강사 통계를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;