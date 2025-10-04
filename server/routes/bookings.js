const express = require('express');
const {
    authenticateToken,
    requireMaster,
    requireBookingOwnership,
    dataFilters
} = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 예약 목록 조회
router.get('/', async (req, res) => {
    try {
        const { user_id, schedule_id, status, date_from, date_to } = req.query;
        
        let whereClause = 'WHERE 1=1';
        const params = [];

        // 권한별 데이터 필터링
        if (req.user.userType === 'member') {
            // 회원은 자신의 예약만 볼 수 있음
            whereClause += ' AND b.user_id = ?';
            params.push(req.user.userId);
        } else if (req.user.userType === 'instructor') {
            // 강사는 본인 수업의 예약만 볼 수 있음
            whereClause += ' AND s.instructor_id = ?';
            params.push(req.user.userId);
            
            // 추가로 user_id 필터가 있다면 적용
            if (user_id) {
                whereClause += ' AND b.user_id = ?';
                params.push(user_id);
            }
        } else if (req.user.userType === 'master') {
            // 마스터는 모든 예약을 볼 수 있음, user_id 필터만 적용
            if (user_id) {
                whereClause += ' AND b.user_id = ?';
                params.push(user_id);
            }
        }

        if (schedule_id) {
            whereClause += ' AND b.schedule_id = ?';
            params.push(schedule_id);
        }

        if (status) {
            whereClause += ' AND b.booking_status = ?';
            params.push(status);
        }

        if (date_from) {
            whereClause += ' AND DATE(s.scheduled_at) >= ?';
            params.push(date_from);
        }

        if (date_to) {
            whereClause += ' AND DATE(s.scheduled_at) <= ?';
            params.push(date_to);
        }

        const bookings = await req.db.getAllQuery(`
            SELECT 
                b.*,
                u.name as user_name,
                u.phone as user_phone,
                s.scheduled_at,
                s.duration_minutes,
                ct.name as class_type_name,
                instructor.name as instructor_name
            FROM bookings b
            LEFT JOIN users u ON b.user_id = u.id
            LEFT JOIN schedules s ON b.schedule_id = s.id
            LEFT JOIN class_types ct ON s.class_type_id = ct.id
            LEFT JOIN users instructor ON s.instructor_id = instructor.id
            ${whereClause}
            ORDER BY s.scheduled_at DESC
        `, params);

        res.json({ bookings });

    } catch (error) {
        console.error('Get bookings error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '예약 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 예약 생성
router.post('/', async (req, res) => {
    try {
        const { schedule_id, membership_id, booking_type = 'regular' } = req.body;
        const user_id = req.user.userType === 'member' ? req.user.userId : req.body.user_id;

        if (!schedule_id || !user_id) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '스케줄과 사용자 정보가 필요합니다.'
            });
        }

        // 스케줄 정보 확인
        const schedule = await req.db.getQuery(
            'SELECT * FROM schedules WHERE id = ? AND status = "scheduled"',
            [schedule_id]
        );

        if (!schedule) {
            return res.status(404).json({
                error: 'Not Found',
                message: '예약 가능한 스케줄을 찾을 수 없습니다.'
            });
        }

        // 중복 예약 확인
        const existingBooking = await req.db.getQuery(
            'SELECT id FROM bookings WHERE schedule_id = ? AND user_id = ? AND booking_status != "cancelled"',
            [schedule_id, user_id]
        );

        if (existingBooking) {
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 예약된 스케줄입니다.'
            });
        }

        // 정원 확인
        if (schedule.current_capacity >= schedule.max_capacity) {
            return res.status(409).json({
                error: 'Conflict',
                message: '정원이 모두 찬 수업입니다.'
            });
        }

        // 예약 생성
        const result = await req.db.runQuery(`
            INSERT INTO bookings (schedule_id, user_id, membership_id, booking_type) 
            VALUES (?, ?, ?, ?)
        `, [schedule_id, user_id, membership_id, booking_type]);

        // 스케줄의 현재 인원 수 업데이트
        await req.db.runQuery(
            'UPDATE schedules SET current_capacity = current_capacity + 1 WHERE id = ?',
            [schedule_id]
        );

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'booking', ?, ?)
        `, [req.user.userId, result.id, JSON.stringify({ schedule_id, user_id, booking_type })]);

        res.status(201).json({
            message: '예약이 완료되었습니다.',
            booking_id: result.id
        });

    } catch (error) {
        console.error('Create booking error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '예약 생성 중 오류가 발생했습니다.'
        });
    }
});

// 예약 취소
router.put('/:id/cancel', async (req, res) => {
    const bookingId = parseInt(req.params.id);
    const { cancel_reason } = req.body;

    try {
        // 트랜잭션 시작
        await req.db.runQuery('BEGIN TRANSACTION');

        // 1. 예약 정보 조회
        const booking = await req.db.getQuery(`
            SELECT b.*, s.scheduled_at, u.name as user_name
            FROM bookings b
            LEFT JOIN schedules s ON b.schedule_id = s.id
            LEFT JOIN users u ON b.user_id = u.id
            WHERE b.id = ?
        `, [bookingId]);

        if (!booking) {
            await req.db.runQuery('ROLLBACK');
            return res.status(404).json({
                error: 'Not Found',
                message: '예약을 찾을 수 없습니다.'
            });
        }

        // 2. 권한 확인 (본인 예약이거나 관리자/강사)
        if (req.user.userType === 'member' && booking.user_id !== req.user.userId) {
            await req.db.runQuery('ROLLBACK');
            return res.status(403).json({
                error: 'Forbidden',
                message: '권한이 없습니다.'
            });
        }

        // 3. 이미 취소된 예약 확인
        if (booking.booking_status === 'cancelled') {
            await req.db.runQuery('ROLLBACK');
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 취소된 예약입니다.'
            });
        }

        // 4. 예약 상태를 취소로 변경
        await req.db.runQuery(`
            UPDATE bookings
            SET booking_status = 'cancelled', cancelled_at = CURRENT_TIMESTAMP, cancel_reason = ?
            WHERE id = ?
        `, [cancel_reason, bookingId]);

        // 5. 스케줄의 현재 인원 수 감소 (confirmed 상태였던 경우만)
        if (booking.booking_status === 'confirmed') {
            await req.db.runQuery(
                'UPDATE schedules SET current_capacity = current_capacity - 1 WHERE id = ? AND current_capacity > 0',
                [booking.schedule_id]
            );
        }

        // 6. 회원에게 예약 취소 알림 발송
        const scheduledDate = new Date(booking.scheduled_at).toLocaleString('ko-KR');
        await req.db.runQuery(`
            INSERT INTO notifications (user_id, type, title, message, related_entity_type, related_entity_id)
            VALUES (?, 'CLASS_CANCELLATION', '예약이 취소되었습니다', ?, 'booking', ?)
        `, [
            booking.user_id,
            `${scheduledDate} 수업 예약이 취소되었습니다.${cancel_reason ? '\n사유: ' + cancel_reason : ''}`,
            bookingId
        ]);

        // 7. 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details)
            VALUES (?, 'cancel', 'booking', ?, ?)
        `, [req.user.userId, bookingId, JSON.stringify({ cancel_reason, cancelled_user: booking.user_name })]);

        // 트랜잭션 커밋
        await req.db.runQuery('COMMIT');

        res.json({
            message: '예약이 취소되었습니다.'
        });

    } catch (error) {
        // 트랜잭션 롤백
        await req.db.runQuery('ROLLBACK');
        console.error('Cancel booking error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '예약 취소 중 오류가 발생했습니다.'
        });
    }
});

// 예약 삭제 (관리자 전용)
router.delete('/:id', requireMaster, async (req, res) => {
    const bookingId = parseInt(req.params.id);

    try {
        // 트랜잭션 시작
        await req.db.runQuery('BEGIN TRANSACTION');

        // 1. 예약 정보 조회
        const booking = await req.db.getQuery(`
            SELECT b.*, u.name as user_name
            FROM bookings b
            LEFT JOIN users u ON b.user_id = u.id
            WHERE b.id = ?
        `, [bookingId]);

        if (!booking) {
            await req.db.runQuery('ROLLBACK');
            return res.status(404).json({
                error: 'Not Found',
                message: '예약을 찾을 수 없습니다.'
            });
        }

        // 2. 예약이 취소되지 않은 상태라면 스케줄 인원 수 조정
        if (booking.booking_status === 'confirmed') {
            await req.db.runQuery(
                'UPDATE schedules SET current_capacity = current_capacity - 1 WHERE id = ? AND current_capacity > 0',
                [booking.schedule_id]
            );
        }

        // 3. 예약 삭제
        await req.db.runQuery('DELETE FROM bookings WHERE id = ?', [bookingId]);

        // 4. 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details)
            VALUES (?, 'delete', 'booking', ?, ?)
        `, [req.user.userId, bookingId, JSON.stringify({
            deleted_user: booking.user_name,
            schedule_id: booking.schedule_id
        })]);

        // 트랜잭션 커밋
        await req.db.runQuery('COMMIT');

        res.json({
            message: '예약이 삭제되었습니다.'
        });

    } catch (error) {
        // 트랜잭션 롤백
        await req.db.runQuery('ROLLBACK');
        console.error('Delete booking error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '예약 삭제 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;