const express = require('express');
const { authenticateToken, requireMaster } = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 1. 내 알림 목록 조회 (읽음/안읽음 필터 포함)
router.get('/', async (req, res) => {
    try {
        const { is_read, limit = 20, page = 1 } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = 'WHERE user_id = ?';
        const params = [req.user.userId];

        if (is_read !== undefined) {
            whereClause += ' AND is_read = ?';
            params.push(is_read === 'true' ? 1 : 0);
        }

        const notifications = await req.db.getAllQuery(`
            SELECT * FROM notifications
            ${whereClause}
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        `, [...params, parseInt(limit), parseInt(offset)]);

        const totalCount = await req.db.getQuery(`
            SELECT COUNT(*) as count FROM notifications ${whereClause}
        `, params);

        res.json({
            notifications,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalCount.count,
                totalPages: Math.ceil(totalCount.count / limit)
            }
        });
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '알림 조회 중 오류 발생'
        });
    }
});

// 2. 안 읽은 알림 개수 조회
router.get('/unread-count', async (req, res) => {
    try {
        const result = await req.db.getQuery(
            'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
            [req.user.userId]
        );
        res.json({ unreadCount: result.count });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '안 읽은 알림 개수 조회 중 오류 발생'
        });
    }
});

// 3. 특정 알림 읽음 처리
router.put('/:id/read', async (req, res) => {
    try {
        const notificationId = parseInt(req.params.id);
        const result = await req.db.runQuery(
            'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
            [notificationId, req.user.userId]
        );

        if (result.changes === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: '알림을 찾을 수 없거나 권한이 없습니다.'
            });
        }
        res.json({ message: '알림을 읽음 처리했습니다.' });
    } catch (error) {
        console.error('Mark notification as read error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '알림 읽음 처리 중 오류 발생'
        });
    }
});

// 4. 모든 알림 읽음 처리
router.put('/read-all', async (req, res) => {
    try {
        await req.db.runQuery(
            'UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0',
            [req.user.userId]
        );
        res.json({ message: '모든 알림을 읽음 처리했습니다.' });
    } catch (error) {
        console.error('Mark all as read error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '알림 처리 중 오류 발생'
        });
    }
});

// 5. 관리자 메시지 발송 (Master 전용)
router.post('/admin-message', requireMaster, async (req, res) => {
    try {
        const { target, title, message } = req.body;

        if (!target || !title || !message) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'target, title, message는 필수입니다.'
            });
        }

        let userIds = [];

        if (target === 'all_members') {
            userIds = await req.db.getAllQuery(
                "SELECT id FROM users WHERE user_type = 'member' AND is_active = 1"
            );
        } else if (target === 'all_instructors') {
            userIds = await req.db.getAllQuery(
                "SELECT id FROM users WHERE user_type = 'instructor' AND is_active = 1"
            );
        } else if (Number.isInteger(parseInt(target))) {
            userIds = [{ id: parseInt(target) }];
        } else {
            return res.status(400).json({
                error: 'Bad Request',
                message: '잘못된 target입니다.'
            });
        }

        if (userIds.length === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: '알림을 보낼 사용자를 찾을 수 없습니다.'
            });
        }

        // 각 사용자에게 알림 생성
        for (const { id } of userIds) {
            await req.db.runQuery(`
                INSERT INTO notifications (user_id, type, title, message, related_entity_type, related_entity_id)
                VALUES (?, 'ADMIN_MESSAGE', ?, ?, 'message', ?)
            `, [id, title, message, req.user.userId]);
        }

        res.status(201).json({
            message: `${userIds.length}명에게 메시지를 성공적으로 발송했습니다.`,
            count: userIds.length
        });

    } catch (error) {
        console.error('Send admin message error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '관리자 메시지 발송 중 오류 발생'
        });
    }
});

module.exports = router;
