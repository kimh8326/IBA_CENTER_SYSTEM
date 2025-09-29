const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'pilates-center-secret-key-2024';

// JWT 토큰 인증 미들웨어
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: '액세스 토큰이 필요합니다.'
        });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '유효하지 않은 토큰입니다.'
            });
        }
        req.user = user;
        next();
    });
}

// 권한 확인 미들웨어 생성 함수
function requireRole(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: '로그인이 필요합니다.'
            });
        }

        if (!allowedRoles.includes(req.user.userType)) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '접근 권한이 없습니다.',
                requiredRoles: allowedRoles,
                userRole: req.user.userType
            });
        }

        next();
    };
}

// 마스터 전용 미들웨어
const requireMaster = requireRole('master');

// 마스터 + 강사 미들웨어
const requireStaff = requireRole('master', 'instructor');

// 모든 인증된 사용자 미들웨어
const requireAuth = requireRole('master', 'instructor', 'member');

// 강사가 본인 데이터만 접근하도록 하는 미들웨어
function requireInstructorOwnership(req, res, next) {
    // 마스터는 모든 데이터 접근 가능
    if (req.user.userType === 'master') {
        return next();
    }

    // 강사는 본인 데이터만 접근 가능
    if (req.user.userType === 'instructor') {
        const instructorId = req.params.instructorId || req.body.instructor_id || req.query.instructor_id;
        
        if (instructorId && instructorId !== req.user.userId.toString()) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 데이터만 접근할 수 있습니다.'
            });
        }
        return next();
    }

    return res.status(403).json({
        error: 'Forbidden',
        message: '강사 또는 관리자 권한이 필요합니다.'
    });
}

// 회원이 본인 데이터만 접근하도록 하는 미들웨어
function requireMemberOwnership(req, res, next) {
    // 마스터는 모든 데이터 접근 가능
    if (req.user.userType === 'master') {
        return next();
    }

    // 회원은 본인 데이터만 접근 가능
    if (req.user.userType === 'member') {
        const memberId = req.params.memberId || req.params.userId || req.body.user_id || req.query.user_id;
        
        if (memberId && memberId !== req.user.userId.toString()) {
            return res.status(403).json({
                error: 'Forbidden',
                message: '본인의 데이터만 접근할 수 있습니다.'
            });
        }
        return next();
    }

    return res.status(403).json({
        error: 'Forbidden',
        message: '권한이 없습니다.'
    });
}

// 스케줄 소유권 확인 미들웨어 (강사가 본인 스케줄만 수정하도록)
async function requireScheduleOwnership(req, res, next) {
    try {
        // 마스터는 모든 스케줄 접근 가능
        if (req.user.userType === 'master') {
            return next();
        }

        // 강사는 본인 스케줄만 접근 가능
        if (req.user.userType === 'instructor') {
            const scheduleId = req.params.scheduleId || req.params.id;
            
            if (!scheduleId) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '스케줄 ID가 필요합니다.'
                });
            }

            // 스케줄 소유권 확인
            const schedule = await req.db.getQuery(
                'SELECT instructor_id FROM schedules WHERE id = ?',
                [scheduleId]
            );

            if (!schedule) {
                return res.status(404).json({
                    error: 'Not Found',
                    message: '스케줄을 찾을 수 없습니다.'
                });
            }

            if (schedule.instructor_id !== req.user.userId) {
                return res.status(403).json({
                    error: 'Forbidden',
                    message: '본인이 담당하는 스케줄만 수정할 수 있습니다.'
                });
            }

            return next();
        }

        return res.status(403).json({
            error: 'Forbidden',
            message: '강사 또는 관리자 권한이 필요합니다.'
        });

    } catch (error) {
        console.error('Schedule ownership verification error:', error);
        return res.status(500).json({
            error: 'Internal Server Error',
            message: '권한 확인 중 오류가 발생했습니다.'
        });
    }
}

// 예약 소유권 확인 미들웨어 (회원이 본인 예약만 수정하도록)
async function requireBookingOwnership(req, res, next) {
    try {
        // 마스터는 모든 예약 접근 가능
        if (req.user.userType === 'master') {
            return next();
        }

        const bookingId = req.params.bookingId || req.params.id;
        
        if (!bookingId) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '예약 ID가 필요합니다.'
            });
        }

        // 예약 정보 조회
        const booking = await req.db.getQuery(`
            SELECT b.user_id, b.schedule_id, s.instructor_id
            FROM bookings b
            JOIN schedules s ON b.schedule_id = s.id
            WHERE b.id = ?
        `, [bookingId]);

        if (!booking) {
            return res.status(404).json({
                error: 'Not Found',
                message: '예약을 찾을 수 없습니다.'
            });
        }

        // 강사는 본인 수업의 예약만 접근 가능
        if (req.user.userType === 'instructor') {
            if (booking.instructor_id !== req.user.userId) {
                return res.status(403).json({
                    error: 'Forbidden',
                    message: '본인이 담당하는 수업의 예약만 관리할 수 있습니다.'
                });
            }
            return next();
        }

        // 회원은 본인 예약만 접근 가능
        if (req.user.userType === 'member') {
            if (booking.user_id !== req.user.userId) {
                return res.status(403).json({
                    error: 'Forbidden',
                    message: '본인의 예약만 관리할 수 있습니다.'
                });
            }
            return next();
        }

        return res.status(403).json({
            error: 'Forbidden',
            message: '권한이 없습니다.'
        });

    } catch (error) {
        console.error('Booking ownership verification error:', error);
        return res.status(500).json({
            error: 'Internal Server Error',
            message: '권한 확인 중 오류가 발생했습니다.'
        });
    }
}

// 데이터 필터링 헬퍼 함수들
const dataFilters = {
    // 강사용 스케줄 필터 (본인 스케줄만)
    getInstructorSchedulesFilter: (userType, userId) => {
        if (userType === 'master') {
            return ''; // 마스터는 모든 스케줄
        } else if (userType === 'instructor') {
            return ` AND s.instructor_id = ${userId}`; // 본인 스케줄만
        } else {
            return ''; // 회원도 모든 공개 스케줄 조회 가능
        }
    },

    // 강사용 예약 필터 (본인 수업 예약만)
    getInstructorBookingsFilter: (userType, userId) => {
        if (userType === 'master') {
            return ''; // 마스터는 모든 예약
        } else if (userType === 'instructor') {
            return ` AND s.instructor_id = ${userId}`; // 본인 수업 예약만
        } else {
            return ` AND b.user_id = ${userId}`; // 회원은 본인 예약만
        }
    },

    // 강사용 회원 필터 (강사는 모든 회원 조회 가능)
    getInstructorMembersFilter: (userType, userId) => {
        if (userType === 'master' || userType === 'instructor') {
            return ''; // 마스터와 강사는 모든 회원 조회 가능
        } else {
            return ` AND u.id = ${userId}`; // 일반 회원은 본인만
        }
    }
};

module.exports = {
    authenticateToken,
    requireRole,
    requireMaster,
    requireStaff,
    requireAuth,
    requireInstructorOwnership,
    requireMemberOwnership,
    requireScheduleOwnership,
    requireBookingOwnership,
    dataFilters
};