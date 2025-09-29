const express = require('express');
const { authenticateToken, requireMaster } = require('../middleware/auth');
const DatabaseResetter = require('../scripts/reset_database');
const router = express.Router();

router.use(authenticateToken);

// 데이터베이스 초기화 (마스터 전용)
router.post('/reset-database', requireMaster, async (req, res) => {
    try {
        console.log(`🔄 Database reset requested by user ${req.user.userId} (${req.user.name})`);
        
        const resetter = new DatabaseResetter();
        await resetter.resetDatabase();
        
        // 데이터베이스 연결 재설정
        console.log('🔄 Reconnecting database connection...');
        const reconnected = await req.db.reconnect();
        
        if (reconnected) {
            console.log('✅ Database connection successfully reestablished');
        } else {
            console.log('⚠️ Database reconnection failed - server restart may be needed');
        }
        
        console.log(`✅ Database reset completed by user ${req.user.userId}`);
        
        res.json({
            success: true,
            message: '데이터베이스가 성공적으로 초기화되었습니다.',
            adminLogin: {
                username: 'admin',
                password: 'admin123',
                note: '관리자 계정은 별도 관리되어 DB 초기화에 영향받지 않습니다.'
            },
            info: '✅ 관리자 계정은 보존되었습니다. 서버 재시작 없이 바로 사용 가능합니다.',
            timestamp: new Date().toISOString(),
            resetBy: req.user.name,
            restartRequired: false
        });

    } catch (error) {
        console.error('Database reset error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal Server Error',
            message: '데이터베이스 초기화 중 오류가 발생했습니다.',
            details: error.message
        });
    }
});

// 시스템 정보 조회 (마스터 전용)
router.get('/system-info', requireMaster, async (req, res) => {
    try {
        // 데이터베이스 통계
        const stats = await req.db.getAllQuery(`
            SELECT 
                'users' as table_name, COUNT(*) as count FROM users
            UNION ALL
            SELECT 'schedules' as table_name, COUNT(*) as count FROM schedules
            UNION ALL
            SELECT 'bookings' as table_name, COUNT(*) as count FROM bookings
            UNION ALL
            SELECT 'class_types' as table_name, COUNT(*) as count FROM class_types
            UNION ALL
            SELECT 'memberships' as table_name, COUNT(*) as count FROM memberships
            UNION ALL
            SELECT 'payments' as table_name, COUNT(*) as count FROM payments
        `);

        // 최근 활동 로그
        const recentLogs = await req.db.getAllQuery(`
            SELECT 
                al.action, al.target_type, al.created_at,
                u.name as user_name
            FROM activity_logs al
            LEFT JOIN users u ON al.user_id = u.id
            ORDER BY al.created_at DESC
            LIMIT 10
        `);

        res.json({
            databaseStats: stats.reduce((acc, row) => {
                acc[row.table_name] = row.count;
                return acc;
            }, {}),
            recentActivity: recentLogs,
            serverInfo: {
                nodejs: process.version,
                uptime: Math.floor(process.uptime()),
                memory: process.memoryUsage()
            }
        });

    } catch (error) {
        console.error('Get system info error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '시스템 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;