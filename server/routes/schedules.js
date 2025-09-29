const express = require('express');
const { 
    authenticateToken, 
    requireMaster, 
    requireStaff, 
    requireScheduleOwnership,
    dataFilters 
} = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 스케줄 목록 조회 (권한별 필터 적용)
router.get('/', async (req, res) => {
    try {
        const { date, instructor_id, class_type_id, status, start_date, end_date, view_type = 'week' } = req.query;
        
        let whereClause = 'WHERE 1=1';
        const params = [];

        // **핵심: 권한별 데이터 접근 제한**
        const instructorFilter = dataFilters.getInstructorSchedulesFilter(
            req.user.userType, 
            req.user.userId
        );
        whereClause += instructorFilter;

        // 날짜 범위 필터
        if (start_date && end_date) {
            whereClause += ' AND DATE(s.scheduled_at) BETWEEN ? AND ?';
            params.push(start_date, end_date);
        } else if (date) {
            whereClause += ' AND DATE(s.scheduled_at) = ?';
            params.push(date);
        } else {
            // 기본값: 모든 스케줄 조회 (회원도 전체 보기)
            // 필요시 클라이언트에서 날짜 필터링 가능
            // const today = new Date().toISOString().split('T')[0];
            // if (view_type === 'month') {
            //     whereClause += ' AND strftime("%Y-%m", s.scheduled_at) = strftime("%Y-%m", ?)';
            //     params.push(today);
            // } else {
            //     whereClause += ' AND DATE(s.scheduled_at) BETWEEN date(?, "-30 days") AND date(?, "+30 days")';
            //     params.push(today, today);
            // }
        }

        // 추가 필터들
        if (instructor_id && req.user.userType === 'master') {
            whereClause += ' AND s.instructor_id = ?';
            params.push(instructor_id);
        }

        if (class_type_id) {
            whereClause += ' AND s.class_type_id = ?';
            params.push(class_type_id);
        }

        if (status) {
            whereClause += ' AND s.status = ?';
            params.push(status);
        }

        // 회원도 모든 스케줄 조회 가능 (과거 스케줄 포함)
        // 예약은 별도 로직에서 과거 스케줄 제한

        const schedules = await req.db.getAllQuery(`
            SELECT 
                s.id as id, s.class_type_id, s.instructor_id, s.scheduled_at, s.duration_minutes,
                s.max_capacity, s.current_capacity, s.status, s.notes, s.created_at, s.updated_at,
                u.name as instructor_name,
                u.phone as instructor_phone,
                ct.name as class_type_name,
                ct.color as class_color,
                ct.price,
                -- 예약 현황
                (SELECT COUNT(*) FROM bookings WHERE schedule_id = s.id AND booking_status = 'confirmed') as booked_count,
                (SELECT COUNT(*) FROM waiting_list WHERE schedule_id = s.id) as waiting_count,
                -- 내 예약 여부 (회원인 경우)
                CASE 
                    WHEN ? = 'member' THEN 
                        (SELECT COUNT(*) FROM bookings WHERE schedule_id = s.id AND user_id = ? AND booking_status IN ('confirmed', 'cancelled'))
                    ELSE 0 
                END as my_booking_status
            FROM schedules s
            LEFT JOIN users u ON s.instructor_id = u.id
            LEFT JOIN class_types ct ON s.class_type_id = ct.id
            ${whereClause}
            ORDER BY s.scheduled_at ASC
        `, [req.user.userType, req.user.userId, ...params]);

        // 강사/마스터인 경우 추가 정보 제공
        let additionalInfo = {};
        if (req.user.userType === 'instructor') {
            additionalInfo.message = '본인이 담당하는 스케줄만 표시됩니다.';
            
            // 오늘의 수업 현황
            const todaySchedules = schedules.filter(s => 
                s.scheduled_at.startsWith(new Date().toISOString().split('T')[0])
            );
            additionalInfo.todaySchedules = todaySchedules.length;
            additionalInfo.todayBookings = todaySchedules.reduce((sum, s) => sum + s.booked_count, 0);
        }

        res.json({
            schedules,
            totalCount: schedules.length,
            filters: {
                userType: req.user.userType,
                dateRange: { start_date, end_date, date },
                viewType: view_type
            },
            ...additionalInfo
        });

    } catch (error) {
        console.error('Get schedules error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 스케줄 생성 (권한 기반)
router.post('/', requireStaff, async (req, res) => {
    try {
        const {
            class_type_id,
            instructor_id,
            scheduled_at,
            duration_minutes,
            max_capacity,
            notes
        } = req.body;

        // 필수 필드 검증
        if (!class_type_id || !instructor_id || !scheduled_at) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '수업 타입, 강사, 예약 시간은 필수입니다.'
            });
        }

        // **핵심: 강사 권한 검증 - 본인 스케줄만 생성 가능**
        if (req.user.userType === 'instructor' && instructor_id !== req.user.userId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 스케줄만 생성할 수 있습니다.'
            });
        }

        // 날짜 시간 검증
        const scheduleDate = new Date(scheduled_at);
        if (scheduleDate <= new Date()) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '과거 시간에는 스케줄을 생성할 수 없습니다.'
            });
        }

        // 수업 타입 정보 가져오기
        const classType = await req.db.getQuery(
            'SELECT duration_minutes, max_capacity, name FROM class_types WHERE id = ? AND is_active = 1',
            [class_type_id]
        );

        if (!classType) {
            return res.status(404).json({
                error: 'Not Found',
                message: '유효한 수업 타입을 찾을 수 없습니다.'
            });
        }

        // 강사 정보 확인
        const instructor = await req.db.getQuery(
            'SELECT id, name FROM users WHERE id = ? AND user_type = "instructor" AND is_active = 1',
            [instructor_id]
        );

        if (!instructor) {
            return res.status(404).json({
                error: 'Not Found',
                message: '유효한 강사를 찾을 수 없습니다.'
            });
        }

        // **스케줄 충돌 검사**
        const finalDuration = duration_minutes || classType.duration_minutes;
        const endTime = new Date(scheduleDate.getTime() + finalDuration * 60000).toISOString();

        const conflictCheck = await req.db.getQuery(`
            SELECT COUNT(*) as count
            FROM schedules 
            WHERE instructor_id = ? 
            AND status != 'cancelled'
            AND (
                (scheduled_at <= ? AND datetime(scheduled_at, '+' || duration_minutes || ' minutes') > ?) OR
                (scheduled_at < ? AND datetime(scheduled_at, '+' || duration_minutes || ' minutes') >= ?)
            )
        `, [instructor_id, scheduled_at, scheduled_at, endTime, endTime]);

        if (conflictCheck.count > 0) {
            return res.status(409).json({
                error: 'Conflict',
                message: '해당 시간에 이미 다른 스케줄이 있습니다.'
            });
        }

        // 스케줄 생성
        const result = await req.db.runQuery(`
            INSERT INTO schedules (
                class_type_id, instructor_id, scheduled_at, 
                duration_minutes, max_capacity, current_capacity, notes
            ) VALUES (?, ?, ?, ?, ?, 0, ?)
        `, [
            class_type_id,
            instructor_id,
            scheduled_at,
            finalDuration,
            max_capacity || classType.max_capacity,
            notes
        ]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'schedule', ?, ?)
        `, [req.user.userId, result.id, JSON.stringify({ 
            scheduled_at, 
            class_type_name: classType.name,
            instructor_name: instructor.name,
            created_by: req.user.userType
        })]);

        // 생성된 스케줄 정보 조회
        const newSchedule = await req.db.getQuery(`
            SELECT 
                s.id as id, s.class_type_id, s.instructor_id, s.scheduled_at, s.duration_minutes,
                s.max_capacity, s.current_capacity, s.status, s.notes, s.created_at, s.updated_at,
                u.name as instructor_name,
                ct.name as class_type_name,
                ct.color as class_color
            FROM schedules s
            LEFT JOIN users u ON s.instructor_id = u.id
            LEFT JOIN class_types ct ON s.class_type_id = ct.id
            WHERE s.id = ?
        `, [result.id]);

        res.status(201).json({
            message: '스케줄이 생성되었습니다.',
            schedule: newSchedule
        });

    } catch (error) {
        console.error('Create schedule error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 생성 중 오류가 발생했습니다.'
        });
    }
});

// 특정 스케줄 조회
router.get('/:id', async (req, res) => {
    try {
        const scheduleId = parseInt(req.params.id);
        
        // 권한 확인을 위한 스케줄 기본 정보 조회
        const scheduleCheck = await req.db.getQuery(
            'SELECT instructor_id FROM schedules WHERE id = ?',
            [scheduleId]
        );

        if (!scheduleCheck) {
            return res.status(404).json({
                error: 'Not Found',
                message: '스케줄을 찾을 수 없습니다.'
            });
        }

        // 권한 확인: 강사는 본인 스케줄만, 회원은 예약 가능한 스케줄만
        if (req.user.userType === 'instructor' && scheduleCheck.instructor_id !== req.user.userId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 스케줄만 조회할 수 있습니다.'
            });
        }

        // 스케줄 상세 정보 조회
        const schedule = await req.db.getQuery(`
            SELECT 
                s.id as id, s.class_type_id, s.instructor_id, s.scheduled_at, s.duration_minutes,
                s.max_capacity, s.current_capacity, s.status, s.notes, s.created_at, s.updated_at,
                u.name as instructor_name,
                u.phone as instructor_phone,
                ct.name as class_type_name,
                ct.color as class_color,
                ct.price,
                ct.description as class_description
            FROM schedules s
            LEFT JOIN users u ON s.instructor_id = u.id
            LEFT JOIN class_types ct ON s.class_type_id = ct.id
            WHERE s.id = ?
        `, [scheduleId]);

        // 예약 목록 조회 (권한별 필터링)
        let bookings = [];
        if (req.user.userType === 'master' || req.user.userType === 'instructor') {
            bookings = await req.db.getAllQuery(`
                SELECT 
                    b.*,
                    u.name as member_name,
                    u.phone as member_phone
                FROM bookings b
                LEFT JOIN users u ON b.user_id = u.id
                WHERE b.schedule_id = ? AND b.booking_status != 'cancelled'
                ORDER BY b.booked_at ASC
            `, [scheduleId]);
        }

        // 대기자 목록
        const waitingList = await req.db.getAllQuery(`
            SELECT 
                w.*,
                u.name as member_name
            FROM waiting_list w
            LEFT JOIN users u ON w.user_id = u.id
            WHERE w.schedule_id = ?
            ORDER BY w.position ASC
        `, [scheduleId]);

        res.json({
            schedule,
            bookings,
            waitingList,
            summary: {
                totalBookings: bookings.length,
                totalWaiting: waitingList.length,
                availableSlots: schedule.max_capacity - bookings.length
            }
        });

    } catch (error) {
        console.error('Get schedule error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 스케줄 수정 (소유권 기반)
router.put('/:id', requireScheduleOwnership, async (req, res) => {
    try {
        const scheduleId = parseInt(req.params.id);
        const {
            scheduled_at,
            duration_minutes,
            max_capacity,
            notes,
            status
        } = req.body;

        // 기존 스케줄 정보 조회
        const existingSchedule = await req.db.getQuery(
            'SELECT * FROM schedules WHERE id = ?',
            [scheduleId]
        );

        // 시간 변경 시 충돌 검사
        if (scheduled_at && scheduled_at !== existingSchedule.scheduled_at) {
            const scheduleDate = new Date(scheduled_at);
            if (scheduleDate <= new Date()) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '과거 시간으로는 변경할 수 없습니다.'
                });
            }

            const finalDuration = duration_minutes || existingSchedule.duration_minutes;
            const endTime = new Date(scheduleDate.getTime() + finalDuration * 60000).toISOString();

            const conflictCheck = await req.db.getQuery(`
                SELECT COUNT(*) as count
                FROM schedules 
                WHERE instructor_id = ? 
                AND id != ?
                AND status != 'cancelled'
                AND (
                    (scheduled_at <= ? AND datetime(scheduled_at, '+' || duration_minutes || ' minutes') > ?) OR
                    (scheduled_at < ? AND datetime(scheduled_at, '+' || duration_minutes || ' minutes') >= ?)
                )
            `, [existingSchedule.instructor_id, scheduleId, scheduled_at, scheduled_at, endTime, endTime]);

            if (conflictCheck.count > 0) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '해당 시간에 이미 다른 스케줄이 있습니다.'
                });
            }
        }

        // 정원 축소 시 기존 예약 확인
        if (max_capacity && max_capacity < existingSchedule.current_capacity) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '현재 예약자 수보다 정원을 줄일 수 없습니다.'
            });
        }

        // 업데이트할 필드 동적 생성
        let updateFields = [];
        let updateParams = [];

        if (scheduled_at) {
            updateFields.push('scheduled_at = ?');
            updateParams.push(scheduled_at);
        }
        if (duration_minutes) {
            updateFields.push('duration_minutes = ?');
            updateParams.push(duration_minutes);
        }
        if (max_capacity) {
            updateFields.push('max_capacity = ?');
            updateParams.push(max_capacity);
        }
        if (notes !== undefined) {
            updateFields.push('notes = ?');
            updateParams.push(notes);
        }
        if (status) {
            updateFields.push('status = ?');
            updateParams.push(status);
        }

        updateFields.push('updated_at = CURRENT_TIMESTAMP');
        updateParams.push(scheduleId);

        // 스케줄 업데이트
        await req.db.runQuery(`
            UPDATE schedules SET ${updateFields.join(', ')} WHERE id = ?
        `, updateParams);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update', 'schedule', ?, ?)
        `, [req.user.userId, scheduleId, JSON.stringify({
            changes: { scheduled_at, duration_minutes, max_capacity, notes, status },
            updated_by: req.user.userType
        })]);

        res.json({
            message: '스케줄이 수정되었습니다.'
        });

    } catch (error) {
        console.error('Update schedule error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 수정 중 오류가 발생했습니다.'
        });
    }
});

// 스케줄 삭제/취소 (소유권 기반)
router.delete('/:id', requireScheduleOwnership, async (req, res) => {
    try {
        const scheduleId = parseInt(req.params.id);

        // 기존 예약 확인
        const bookingCount = await req.db.getQuery(
            'SELECT COUNT(*) as count FROM bookings WHERE schedule_id = ? AND booking_status = "confirmed"',
            [scheduleId]
        );

        if (bookingCount.count > 0) {
            // 예약자가 있는 경우 취소로 처리
            await req.db.runQuery(
                'UPDATE schedules SET status = "cancelled", updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [scheduleId]
            );

            // 예약자들에게 알림을 위한 로그 (실제 알림 시스템에서 사용)
            await req.db.runQuery(`
                INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
                VALUES (?, 'cancel', 'schedule', ?, ?)
            `, [req.user.userId, scheduleId, JSON.stringify({
                reason: '스케줄 취소',
                affected_bookings: bookingCount.count
            })]);

            res.json({
                message: '예약자가 있어 스케줄이 취소 처리되었습니다.',
                affectedBookings: bookingCount.count
            });
        } else {
            // 예약자가 없는 경우 완전 삭제
            await req.db.runQuery('DELETE FROM schedules WHERE id = ?', [scheduleId]);

            await req.db.runQuery(`
                INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
                VALUES (?, 'delete', 'schedule', ?, ?)
            `, [req.user.userId, scheduleId, JSON.stringify({
                reason: '스케줄 삭제'
            })]);

            res.json({
                message: '스케줄이 삭제되었습니다.'
            });
        }

    } catch (error) {
        console.error('Delete schedule error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 삭제 중 오류가 발생했습니다.'
        });
    }
});

// 수업 타입 목록 조회
router.get('/class-types/list', async (req, res) => {
    try {
        const classTypes = await req.db.getAllQuery(`
            SELECT 
                ct.id as id, ct.name, ct.description, ct.duration_minutes, ct.max_capacity, 
                ct.price, ct.color, ct.is_active, ct.created_at,
                COUNT(s.id) as schedule_count
            FROM class_types ct
            LEFT JOIN schedules s ON ct.id = s.class_type_id AND s.status != 'cancelled'
            WHERE ct.is_active = 1
            GROUP BY ct.id
            ORDER BY ct.name
        `);

        res.json({ classTypes });

    } catch (error) {
        console.error('Get class types error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 수업 타입 생성 (마스터 전용)
router.post('/class-types', requireMaster, async (req, res) => {
    try {
        const {
            name,
            description,
            duration_minutes,
            max_capacity,
            price,
            color
        } = req.body;

        if (!name || !duration_minutes || !max_capacity || !price) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '이름, 수업 시간, 정원, 가격은 필수입니다.'
            });
        }

        const result = await req.db.runQuery(`
            INSERT INTO class_types (name, description, duration_minutes, max_capacity, price, color)
            VALUES (?, ?, ?, ?, ?, ?)
        `, [name, description, duration_minutes, max_capacity, price, color || '#6B4EFF']);

        res.status(201).json({
            message: '수업 타입이 생성되었습니다.',
            class_type_id: result.id
        });

    } catch (error) {
        console.error('Create class type error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '수업 타입 생성 중 오류가 발생했습니다.'
        });
    }
});

// 스케줄 통계 (강사/마스터 전용)
router.get('/stats/overview', requireStaff, async (req, res) => {
    try {
        const { start_date, end_date } = req.query;
        let dateFilter = '';
        const params = [];

        // 권한별 필터
        const instructorFilter = dataFilters.getInstructorSchedulesFilter(
            req.user.userType,
            req.user.userId
        );

        if (start_date && end_date) {
            dateFilter = 'AND DATE(s.scheduled_at) BETWEEN ? AND ?';
            params.push(start_date, end_date);
        } else {
            // 기본: 현재 월
            dateFilter = 'AND strftime("%Y-%m", s.scheduled_at) = strftime("%Y-%m", "now")';
        }

        // 스케줄 통계
        const scheduleStats = await req.db.getAllQuery(`
            SELECT 
                s.status,
                COUNT(*) as count,
                SUM(s.current_capacity) as total_bookings
            FROM schedules s
            WHERE 1=1 ${instructorFilter} ${dateFilter}
            GROUP BY s.status
        `, params);

        // 수업별 통계
        const classStats = await req.db.getAllQuery(`
            SELECT 
                ct.name,
                ct.color,
                COUNT(s.id) as schedule_count,
                SUM(s.current_capacity) as total_bookings,
                AVG(s.current_capacity * 100.0 / s.max_capacity) as avg_capacity_rate
            FROM schedules s
            JOIN class_types ct ON s.class_type_id = ct.id
            WHERE 1=1 ${instructorFilter} ${dateFilter}
            GROUP BY ct.id, ct.name
            ORDER BY schedule_count DESC
        `, params);

        res.json({
            scheduleStats,
            classStats,
            period: { start_date, end_date },
            userType: req.user.userType
        });

    } catch (error) {
        console.error('Get schedule stats error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '스케줄 통계를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;