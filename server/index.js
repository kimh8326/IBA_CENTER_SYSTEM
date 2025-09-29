const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const os = require('os');
require('dotenv').config();

const Database = require('./database/init');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const instructorRoutes = require('./routes/instructors');
const scheduleRoutes = require('./routes/schedules');
const bookingRoutes = require('./routes/bookings');
const classTypeRoutes = require('./routes/class-types');
const membershipTemplateRoutes = require('./routes/membership-templates');
const adminRoutes = require('./routes/admin');

const app = express();
const PORT = process.env.PORT || 3000;

// 네트워크 IP 주소 자동 감지
function getNetworkIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const interface of interfaces[name]) {
            if (interface.family === 'IPv4' && !interface.internal) {
                return interface.address;
            }
        }
    }
    return '192.168.1.100'; // 기본값
}

const NETWORK_IP = getNetworkIP();

// 전역 데이터베이스 인스턴스
let db;

// 미들웨어 설정
app.use(helmet({
    contentSecurityPolicy: false, // 개발 중에는 CSP 비활성화
}));

app.use(cors({
    origin: [
        'http://localhost:3000', 
        'http://127.0.0.1:3000', 
        `http://${NETWORK_IP}:3000`,
        'http://localhost:8081',  // Flutter web dev server
        'http://localhost:8082',  // Flutter web dev server (alternative port)
        'http://127.0.0.1:8081',
        'http://127.0.0.1:8082'
    ],
    credentials: true
}));

app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 정적 파일 서빙 (프로필 이미지, 첨부파일 등)
app.use('/uploads', express.static('uploads'));

// 데이터베이스 미들웨어
app.use((req, res, next) => {
    req.db = db;
    next();
});

// 라우트 설정
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/instructors', instructorRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/class-types', classTypeRoutes);
app.use('/api/membership-templates', membershipTemplateRoutes);
app.use('/api/admin', adminRoutes);

// 헬스체크 엔드포인트
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        message: 'Pilates Center Server is running'
    });
});

// 기본 경로
app.get('/', (req, res) => {
    res.json({
        message: '🏃‍♀️ Pilates Center Management System',
        version: '1.0.0',
        status: 'Running',
        endpoints: [
            'GET /api/health - 서버 상태 확인',
            'POST /api/auth/login - 로그인',
            'GET /api/users - 사용자 목록',
            'GET /api/instructors - 강사 목록',
            'GET /api/schedules - 스케줄 목록',
            'GET /api/bookings - 예약 목록'
        ]
    });
});

// 404 에러 핸들러
app.use((req, res, next) => {
    res.status(404).json({
        error: 'Not Found',
        message: `경로 ${req.originalUrl}를 찾을 수 없습니다.`
    });
});

// 전역 에러 핸들러
app.use((err, req, res, next) => {
    console.error('❌ Server Error:', err);
    
    res.status(err.status || 500).json({
        error: err.name || 'Internal Server Error',
        message: err.message || '서버에서 오류가 발생했습니다.',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// 서버 시작
async function startServer() {
    try {
        // 데이터베이스 초기화
        db = new Database();
        await db.initialize();

        // 서버 시작
        app.listen(PORT, '0.0.0.0', () => {
            console.log('🚀 =================================');
            console.log(`🏃‍♀️ Pilates Center Server Started!`);
            console.log(`📍 Local: http://localhost:${PORT}`);
            console.log(`🌐 Network: http://${NETWORK_IP}:${PORT}`);
            console.log(`📱 External Access: http://${NETWORK_IP}:${PORT}`);
            console.log('🚀 =================================');
            console.log('');
            console.log('🎯 Server ready for connections');
        });

    } catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down server...');
    if (db) {
        await db.close();
    }
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Shutting down server...');
    if (db) {
        await db.close();
    }
    process.exit(0);
});

startServer();