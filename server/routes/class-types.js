const express = require('express');
const { authenticateToken, requireMaster } = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 모든 수업 타입 조회 (관리자 전용)
router.get('/', requireMaster, async (req, res) => {
    try {
        const { include_inactive = 'false' } = req.query;
        
        let whereClause = '';
        if (include_inactive !== 'true') {
            whereClause = 'WHERE ct.is_active = 1';
        }
        
        const classTypes = await req.db.getAllQuery(`
            SELECT 
                ct.id, ct.name, ct.description, ct.duration_minutes, ct.max_capacity, 
                ct.price, ct.color, ct.is_active, ct.created_at,
                COUNT(s.id) as schedule_count,
                COUNT(CASE WHEN s.status = 'scheduled' THEN 1 END) as active_schedules
            FROM class_types ct
            LEFT JOIN schedules s ON ct.id = s.class_type_id
            ${whereClause}
            GROUP BY ct.id
            ORDER BY ct.is_active DESC, ct.name ASC
        `);

        res.json({
            classTypes,
            totalCount: classTypes.length
        });

    } catch (error) {
        console.error('Get class types error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 특정 수업 타입 조회
router.get('/:id', requireMaster, async (req, res) => {
    try {
        const classTypeId = parseInt(req.params.id);
        
        const classType = await req.db.getQuery(`
            SELECT 
                ct.id, ct.name, ct.description, ct.duration_minutes, ct.max_capacity, 
                ct.price, ct.color, ct.is_active, ct.created_at,
                COUNT(s.id) as total_schedules,
                COUNT(CASE WHEN s.status = 'scheduled' THEN 1 END) as active_schedules,
                COUNT(CASE WHEN s.status = 'completed' THEN 1 END) as completed_schedules
            FROM class_types ct
            LEFT JOIN schedules s ON ct.id = s.class_type_id
            WHERE ct.id = ?
            GROUP BY ct.id
        `, [classTypeId]);

        if (!classType) {
            return res.status(404).json({
                error: 'Not Found',
                message: '수업 타입을 찾을 수 없습니다.'
            });
        }

        // 최근 스케줄 정보
        const recentSchedules = await req.db.getAllQuery(`
            SELECT 
                s.id, s.scheduled_at, s.status, s.current_capacity, s.max_capacity,
                u.name as instructor_name
            FROM schedules s
            LEFT JOIN users u ON s.instructor_id = u.id
            WHERE s.class_type_id = ?
            ORDER BY s.scheduled_at DESC
            LIMIT 10
        `, [classTypeId]);

        res.json({
            classType,
            recentSchedules
        });

    } catch (error) {
        console.error('Get class type error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 수업 타입 생성
router.post('/', requireMaster, async (req, res) => {
    try {
        const {
            name,
            description,
            durationMinutes,
            maxCapacity,
            price,
            color,
            isActive
        } = req.body;

        // 필수 필드 검증
        if (!name || !durationMinutes || !maxCapacity) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '수업 이름, 수업 시간, 최대 인원은 필수입니다.'
            });
        }

        // 수업 이름 중복 확인
        const existingClassType = await req.db.getQuery(
            'SELECT id FROM class_types WHERE name = ?',
            [name]
        );

        if (existingClassType) {
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 존재하는 수업 타입 이름입니다.'
            });
        }

        // 유효성 검증
        if (durationMinutes < 10 || durationMinutes > 300) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '수업 시간은 10분에서 300분 사이여야 합니다.'
            });
        }

        if (maxCapacity < 1 || maxCapacity > 50) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '최대 인원은 1명에서 50명 사이여야 합니다.'
            });
        }

        if (price !== null && price < 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '가격은 0 이상이어야 합니다.'
            });
        }

        // 수업 타입 생성
        const result = await req.db.runQuery(`
            INSERT INTO class_types (
                name, description, duration_minutes, max_capacity, 
                price, color, is_active
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        `, [
            name.trim(),
            description ? description.trim() : null,
            durationMinutes,
            maxCapacity,
            price,
            color || '#6B4EFF',
            isActive !== false ? 1 : 0
        ]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'class_type', ?, ?)
        `, [req.user.userId, result.id, JSON.stringify({
            name,
            duration_minutes: durationMinutes,
            max_capacity: maxCapacity,
            price,
            created_by: req.user.name
        })]);

        // 생성된 수업 타입 정보 조회
        const newClassType = await req.db.getQuery(`
            SELECT id, name, description, duration_minutes, max_capacity, 
                   price, color, is_active, created_at
            FROM class_types WHERE id = ?
        `, [result.id]);

        res.status(201).json({
            message: '수업 타입이 생성되었습니다.',
            classType: newClassType
        });

    } catch (error) {
        console.error('Create class type error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 생성 중 오류가 발생했습니다.'
        });
    }
});

// 수업 타입 수정
router.put('/:id', requireMaster, async (req, res) => {
    try {
        const classTypeId = parseInt(req.params.id);
        const {
            name,
            description,
            durationMinutes,
            maxCapacity,
            price,
            color,
            isActive
        } = req.body;

        // 기존 수업 타입 확인
        const existingClassType = await req.db.getQuery(
            'SELECT * FROM class_types WHERE id = ?',
            [classTypeId]
        );

        if (!existingClassType) {
            return res.status(404).json({
                error: 'Not Found',
                message: '수업 타입을 찾을 수 없습니다.'
            });
        }

        // 이름 중복 확인 (자신 제외)
        if (name && name !== existingClassType.name) {
            const duplicateCheck = await req.db.getQuery(
                'SELECT id FROM class_types WHERE name = ? AND id != ?',
                [name, classTypeId]
            );

            if (duplicateCheck) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '이미 존재하는 수업 타입 이름입니다.'
                });
            }
        }

        // 유효성 검증
        if (durationMinutes && (durationMinutes < 10 || durationMinutes > 300)) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '수업 시간은 10분에서 300분 사이여야 합니다.'
            });
        }

        if (maxCapacity && (maxCapacity < 1 || maxCapacity > 50)) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '최대 인원은 1명에서 50명 사이여야 합니다.'
            });
        }

        if (price !== null && price !== undefined && price < 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '가격은 0 이상이어야 합니다.'
            });
        }

        // 최대 인원 축소 시 기존 스케줄 확인
        if (maxCapacity && maxCapacity < existingClassType.max_capacity) {
            const conflictingSchedules = await req.db.getQuery(`
                SELECT COUNT(*) as count 
                FROM schedules 
                WHERE class_type_id = ? AND max_capacity > ? AND status = 'scheduled'
            `, [classTypeId, maxCapacity]);

            if (conflictingSchedules.count > 0) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '현재 설정된 정원보다 많은 인원으로 예약된 스케줄이 있습니다.'
                });
            }
        }

        // 업데이트할 필드 동적 생성
        let updateFields = [];
        let updateParams = [];
        const changes = {};

        if (name !== undefined && name !== existingClassType.name) {
            updateFields.push('name = ?');
            updateParams.push(name.trim());
            changes.name = { from: existingClassType.name, to: name.trim() };
        }

        if (description !== undefined && description !== existingClassType.description) {
            updateFields.push('description = ?');
            updateParams.push(description ? description.trim() : null);
            changes.description = { from: existingClassType.description, to: description };
        }

        if (durationMinutes !== undefined && durationMinutes !== existingClassType.duration_minutes) {
            updateFields.push('duration_minutes = ?');
            updateParams.push(durationMinutes);
            changes.duration_minutes = { from: existingClassType.duration_minutes, to: durationMinutes };
        }

        if (maxCapacity !== undefined && maxCapacity !== existingClassType.max_capacity) {
            updateFields.push('max_capacity = ?');
            updateParams.push(maxCapacity);
            changes.max_capacity = { from: existingClassType.max_capacity, to: maxCapacity };
        }

        if (price !== undefined && price !== existingClassType.price) {
            updateFields.push('price = ?');
            updateParams.push(price);
            changes.price = { from: existingClassType.price, to: price };
        }

        if (color !== undefined && color !== existingClassType.color) {
            updateFields.push('color = ?');
            updateParams.push(color);
            changes.color = { from: existingClassType.color, to: color };
        }

        if (isActive !== undefined && (isActive ? 1 : 0) !== existingClassType.is_active) {
            updateFields.push('is_active = ?');
            updateParams.push(isActive ? 1 : 0);
            changes.is_active = { from: existingClassType.is_active, to: isActive };
        }

        // 변경사항이 없는 경우
        if (updateFields.length === 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '변경할 내용이 없습니다.'
            });
        }

        updateParams.push(classTypeId);

        // 수업 타입 수정
        await req.db.runQuery(`
            UPDATE class_types 
            SET ${updateFields.join(', ')} 
            WHERE id = ?
        `, updateParams);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update', 'class_type', ?, ?)
        `, [req.user.userId, classTypeId, JSON.stringify({
            changes,
            updated_by: req.user.name
        })]);

        // 수정된 수업 타입 정보 조회
        const updatedClassType = await req.db.getQuery(`
            SELECT id, name, description, duration_minutes, max_capacity, 
                   price, color, is_active, created_at
            FROM class_types WHERE id = ?
        `, [classTypeId]);

        res.json({
            message: '수업 타입이 수정되었습니다.',
            classType: updatedClassType
        });

    } catch (error) {
        console.error('Update class type error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 수정 중 오류가 발생했습니다.'
        });
    }
});

// 수업 타입 삭제
router.delete('/:id', requireMaster, async (req, res) => {
    try {
        const classTypeId = parseInt(req.params.id);

        // 기존 수업 타입 확인
        const existingClassType = await req.db.getQuery(
            'SELECT * FROM class_types WHERE id = ?',
            [classTypeId]
        );

        if (!existingClassType) {
            return res.status(404).json({
                error: 'Not Found',
                message: '수업 타입을 찾을 수 없습니다.'
            });
        }

        // 관련 스케줄 확인
        const relatedSchedules = await req.db.getQuery(`
            SELECT COUNT(*) as count 
            FROM schedules 
            WHERE class_type_id = ? AND status IN ('scheduled', 'in_progress')
        `, [classTypeId]);

        if (relatedSchedules.count > 0) {
            return res.status(409).json({
                error: 'Conflict',
                message: '진행 중이거나 예정된 스케줄이 있는 수업 타입은 삭제할 수 없습니다. 먼저 관련 스케줄을 처리해주세요.'
            });
        }

        // 관련 회원권 템플릿 확인
        const relatedMemberships = await req.db.getQuery(`
            SELECT COUNT(*) as count 
            FROM membership_templates 
            WHERE class_type_id = ? AND is_active = 1
        `, [classTypeId]);

        if (relatedMemberships.count > 0) {
            return res.status(409).json({
                error: 'Conflict',
                message: '활성화된 회원권 템플릿이 있는 수업 타입은 삭제할 수 없습니다. 먼저 관련 회원권 템플릿을 비활성화해주세요.'
            });
        }

        // 수업 타입 삭제
        await req.db.runQuery('DELETE FROM class_types WHERE id = ?', [classTypeId]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'delete', 'class_type', ?, ?)
        `, [req.user.userId, classTypeId, JSON.stringify({
            deleted_class_type: {
                name: existingClassType.name,
                duration_minutes: existingClassType.duration_minutes
            },
            deleted_by: req.user.name
        })]);

        res.json({
            message: '수업 타입이 삭제되었습니다.',
            deletedClassType: {
                id: classTypeId,
                name: existingClassType.name
            }
        });

    } catch (error) {
        console.error('Delete class type error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 삭제 중 오류가 발생했습니다.'
        });
    }
});

// 수업 타입 통계
router.get('/:id/stats', requireMaster, async (req, res) => {
    try {
        const classTypeId = parseInt(req.params.id);
        const { start_date, end_date } = req.query;

        let dateFilter = '';
        const params = [classTypeId];

        if (start_date && end_date) {
            dateFilter = 'AND DATE(s.scheduled_at) BETWEEN ? AND ?';
            params.push(start_date, end_date);
        } else {
            // 기본: 최근 30일
            dateFilter = 'AND s.scheduled_at >= date("now", "-30 days")';
        }

        // 기본 통계
        const basicStats = await req.db.getQuery(`
            SELECT 
                COUNT(s.id) as total_schedules,
                COUNT(CASE WHEN s.status = 'completed' THEN 1 END) as completed_schedules,
                COUNT(CASE WHEN s.status = 'cancelled' THEN 1 END) as cancelled_schedules,
                AVG(s.current_capacity * 100.0 / s.max_capacity) as avg_capacity_rate,
                SUM(s.current_capacity) as total_bookings
            FROM schedules s
            WHERE s.class_type_id = ? ${dateFilter}
        `, params);

        // 월별 통계
        const monthlyStats = await req.db.getAllQuery(`
            SELECT 
                strftime('%Y-%m', s.scheduled_at) as month,
                COUNT(s.id) as schedule_count,
                SUM(s.current_capacity) as booking_count,
                AVG(s.current_capacity * 100.0 / s.max_capacity) as capacity_rate
            FROM schedules s
            WHERE s.class_type_id = ? ${dateFilter}
            GROUP BY strftime('%Y-%m', s.scheduled_at)
            ORDER BY month DESC
        `, params);

        // 강사별 통계
        const instructorStats = await req.db.getAllQuery(`
            SELECT 
                u.name as instructor_name,
                COUNT(s.id) as schedule_count,
                SUM(s.current_capacity) as booking_count,
                AVG(s.current_capacity * 100.0 / s.max_capacity) as capacity_rate
            FROM schedules s
            LEFT JOIN users u ON s.instructor_id = u.id
            WHERE s.class_type_id = ? ${dateFilter}
            GROUP BY s.instructor_id, u.name
            ORDER BY schedule_count DESC
        `, params);

        res.json({
            basicStats,
            monthlyStats,
            instructorStats,
            period: { start_date, end_date }
        });

    } catch (error) {
        console.error('Get class type stats error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 통계를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;