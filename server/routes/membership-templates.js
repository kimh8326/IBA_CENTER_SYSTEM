const express = require('express');
const { authenticateToken, requireMaster, requireStaff } = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// 모든 회원권 템플릿 조회 (관리자 + 강사)
router.get('/', requireStaff, async (req, res) => {
    try {
        const { include_inactive = 'false' } = req.query;
        
        let whereClause = '';
        const params = [];
        
        if (include_inactive !== 'true') {
            whereClause = 'WHERE mt.is_active = 1';
        }
        
        const membershipTemplates = await req.db.getAllQuery(`
            SELECT 
                mt.id, mt.name, mt.description, mt.class_type_id, 
                mt.total_sessions, mt.validity_days, mt.price, 
                mt.is_active, mt.created_at,
                ct.name as class_type_name,
                ct.color as class_type_color,
                COUNT(m.id) as active_memberships
            FROM membership_templates mt
            LEFT JOIN class_types ct ON mt.class_type_id = ct.id
            LEFT JOIN memberships m ON mt.id = m.template_id AND m.status = 'active'
            ${whereClause}
            GROUP BY mt.id
            ORDER BY mt.is_active DESC, mt.name ASC
        `, params);

        res.json({
            membershipTemplates,
            totalCount: membershipTemplates.length
        });

    } catch (error) {
        console.error('Get membership templates error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원권 템플릿 목록을 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 특정 회원권 템플릿 조회
router.get('/:id', requireMaster, async (req, res) => {
    try {
        const templateId = parseInt(req.params.id);
        
        const template = await req.db.getQuery(`
            SELECT 
                mt.id, mt.name, mt.description, mt.class_type_id, 
                mt.total_sessions, mt.validity_days, mt.price, 
                mt.is_active, mt.created_at,
                ct.name as class_type_name,
                ct.color as class_type_color
            FROM membership_templates mt
            LEFT JOIN class_types ct ON mt.class_type_id = ct.id
            WHERE mt.id = ?
        `, [templateId]);

        if (!template) {
            return res.status(404).json({
                error: 'Not Found',
                message: '회원권 템플릿을 찾을 수 없습니다.'
            });
        }

        // 관련 통계
        const stats = await req.db.getQuery(`
            SELECT 
                COUNT(m.id) as total_memberships,
                COUNT(CASE WHEN m.status = 'active' THEN 1 END) as active_memberships,
                COUNT(CASE WHEN m.status = 'expired' THEN 1 END) as expired_memberships,
                SUM(m.purchase_price) as total_revenue
            FROM memberships m
            WHERE m.template_id = ?
        `, [templateId]);

        res.json({
            template,
            stats
        });

    } catch (error) {
        console.error('Get membership template error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원권 템플릿 정보를 가져오는 중 오류가 발생했습니다.'
        });
    }
});

// 새 회원권 템플릿 생성
router.post('/', requireMaster, async (req, res) => {
    try {
        const {
            name,
            description,
            classTypeId,
            totalSessions,
            validityDays,
            price,
            isActive
        } = req.body;

        // 필수 필드 검증
        if (!name || !totalSessions || !validityDays || !price) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '회원권 이름, 총 세션 수, 유효 기간, 가격은 필수입니다.'
            });
        }

        // 수업 타입 존재 확인 (classTypeId가 제공된 경우)
        if (classTypeId) {
            const classType = await req.db.getQuery(
                'SELECT id FROM class_types WHERE id = ? AND is_active = 1',
                [classTypeId]
            );

            if (!classType) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '유효하지 않은 수업 타입입니다.'
                });
            }
        }

        // 회원권 이름 중복 확인
        const existingTemplate = await req.db.getQuery(
            'SELECT id FROM membership_templates WHERE name = ?',
            [name]
        );

        if (existingTemplate) {
            return res.status(409).json({
                error: 'Conflict',
                message: '이미 존재하는 회원권 템플릿 이름입니다.'
            });
        }

        // 유효성 검증
        if (totalSessions < 1 || totalSessions > 200) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '총 세션 수는 1회에서 200회 사이여야 합니다.'
            });
        }

        if (validityDays < 7 || validityDays > 3650) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '유효 기간은 7일에서 3650일 사이여야 합니다.'
            });
        }

        if (price < 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '가격은 0 이상이어야 합니다.'
            });
        }

        // 회원권 템플릿 생성
        const result = await req.db.runQuery(`
            INSERT INTO membership_templates (
                name, description, class_type_id, total_sessions, 
                validity_days, price, is_active
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        `, [
            name.trim(),
            description ? description.trim() : null,
            classTypeId || null,
            totalSessions,
            validityDays,
            price,
            isActive !== false ? 1 : 0
        ]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'create', 'membership_template', ?, ?)
        `, [req.user.userId, result.id, JSON.stringify({
            name,
            total_sessions: totalSessions,
            validity_days: validityDays,
            price,
            created_by: req.user.name
        })]);

        // 생성된 회원권 템플릿 정보 조회
        const newTemplate = await req.db.getQuery(`
            SELECT 
                mt.id, mt.name, mt.description, mt.class_type_id, 
                mt.total_sessions, mt.validity_days, mt.price, 
                mt.is_active, mt.created_at,
                ct.name as class_type_name
            FROM membership_templates mt
            LEFT JOIN class_types ct ON mt.class_type_id = ct.id
            WHERE mt.id = ?
        `, [result.id]);

        res.status(201).json({
            message: '회원권 템플릿이 생성되었습니다.',
            template: newTemplate
        });

    } catch (error) {
        console.error('Create membership template error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원권 템플릿 생성 중 오류가 발생했습니다.'
        });
    }
});

// 회원권 템플릿 수정
router.put('/:id', requireMaster, async (req, res) => {
    try {
        const templateId = parseInt(req.params.id);
        const {
            name,
            description,
            classTypeId,
            totalSessions,
            validityDays,
            price,
            isActive
        } = req.body;

        // 기존 템플릿 확인
        const existingTemplate = await req.db.getQuery(
            'SELECT * FROM membership_templates WHERE id = ?',
            [templateId]
        );

        if (!existingTemplate) {
            return res.status(404).json({
                error: 'Not Found',
                message: '회원권 템플릿을 찾을 수 없습니다.'
            });
        }

        // 수업 타입 존재 확인
        if (classTypeId && classTypeId !== existingTemplate.class_type_id) {
            const classType = await req.db.getQuery(
                'SELECT id FROM class_types WHERE id = ? AND is_active = 1',
                [classTypeId]
            );

            if (!classType) {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: '유효하지 않은 수업 타입입니다.'
                });
            }
        }

        // 이름 중복 확인 (자신 제외)
        if (name && name !== existingTemplate.name) {
            const duplicateCheck = await req.db.getQuery(
                'SELECT id FROM membership_templates WHERE name = ? AND id != ?',
                [name, templateId]
            );

            if (duplicateCheck) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: '이미 존재하는 회원권 템플릿 이름입니다.'
                });
            }
        }

        // 유효성 검증
        if (totalSessions && (totalSessions < 1 || totalSessions > 200)) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '총 세션 수는 1회에서 200회 사이여야 합니다.'
            });
        }

        if (validityDays && (validityDays < 7 || validityDays > 3650)) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '유효 기간은 7일에서 3650일 사이여야 합니다.'
            });
        }

        if (price !== null && price !== undefined && price < 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '가격은 0 이상이어야 합니다.'
            });
        }

        // 업데이트할 필드 동적 생성
        let updateFields = [];
        let updateParams = [];
        const changes = {};

        if (name !== undefined && name !== existingTemplate.name) {
            updateFields.push('name = ?');
            updateParams.push(name.trim());
            changes.name = { from: existingTemplate.name, to: name.trim() };
        }

        if (description !== undefined && description !== existingTemplate.description) {
            updateFields.push('description = ?');
            updateParams.push(description ? description.trim() : null);
            changes.description = { from: existingTemplate.description, to: description };
        }

        if (classTypeId !== undefined && classTypeId !== existingTemplate.class_type_id) {
            updateFields.push('class_type_id = ?');
            updateParams.push(classTypeId || null);
            changes.class_type_id = { from: existingTemplate.class_type_id, to: classTypeId };
        }

        if (totalSessions !== undefined && totalSessions !== existingTemplate.total_sessions) {
            updateFields.push('total_sessions = ?');
            updateParams.push(totalSessions);
            changes.total_sessions = { from: existingTemplate.total_sessions, to: totalSessions };
        }

        if (validityDays !== undefined && validityDays !== existingTemplate.validity_days) {
            updateFields.push('validity_days = ?');
            updateParams.push(validityDays);
            changes.validity_days = { from: existingTemplate.validity_days, to: validityDays };
        }

        if (price !== undefined && price !== existingTemplate.price) {
            updateFields.push('price = ?');
            updateParams.push(price);
            changes.price = { from: existingTemplate.price, to: price };
        }

        if (isActive !== undefined && (isActive ? 1 : 0) !== existingTemplate.is_active) {
            updateFields.push('is_active = ?');
            updateParams.push(isActive ? 1 : 0);
            changes.is_active = { from: existingTemplate.is_active, to: isActive };
        }

        // 변경사항이 없는 경우
        if (updateFields.length === 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: '변경할 내용이 없습니다.'
            });
        }

        updateParams.push(templateId);

        // 템플릿 수정
        await req.db.runQuery(`
            UPDATE membership_templates 
            SET ${updateFields.join(', ')} 
            WHERE id = ?
        `, updateParams);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'update', 'membership_template', ?, ?)
        `, [req.user.userId, templateId, JSON.stringify({
            changes,
            updated_by: req.user.name
        })]);

        // 수정된 템플릿 정보 조회
        const updatedTemplate = await req.db.getQuery(`
            SELECT 
                mt.id, mt.name, mt.description, mt.class_type_id, 
                mt.total_sessions, mt.validity_days, mt.price, 
                mt.is_active, mt.created_at,
                ct.name as class_type_name
            FROM membership_templates mt
            LEFT JOIN class_types ct ON mt.class_type_id = ct.id
            WHERE mt.id = ?
        `, [templateId]);

        res.json({
            message: '회원권 템플릿이 수정되었습니다.',
            template: updatedTemplate
        });

    } catch (error) {
        console.error('Update membership template error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원권 템플릿 수정 중 오류가 발생했습니다.'
        });
    }
});

// 회원권 템플릿 삭제
router.delete('/:id', requireMaster, async (req, res) => {
    try {
        const templateId = parseInt(req.params.id);

        // 기존 템플릿 확인
        const existingTemplate = await req.db.getQuery(
            'SELECT * FROM membership_templates WHERE id = ?',
            [templateId]
        );

        if (!existingTemplate) {
            return res.status(404).json({
                error: 'Not Found',
                message: '회원권 템플릿을 찾을 수 없습니다.'
            });
        }

        // 관련 활성 회원권 확인
        const relatedMemberships = await req.db.getQuery(`
            SELECT COUNT(*) as count 
            FROM memberships 
            WHERE template_id = ? AND status IN ('active', 'suspended')
        `, [templateId]);

        if (relatedMemberships.count > 0) {
            return res.status(409).json({
                error: 'Conflict',
                message: '활성화된 회원권이 있는 템플릿은 삭제할 수 없습니다. 먼저 관련 회원권을 처리해주세요.'
            });
        }

        // 템플릿 삭제
        await req.db.runQuery('DELETE FROM membership_templates WHERE id = ?', [templateId]);

        // 활동 로그 기록
        await req.db.runQuery(`
            INSERT INTO activity_logs (user_id, action, target_type, target_id, details) 
            VALUES (?, 'delete', 'membership_template', ?, ?)
        `, [req.user.userId, templateId, JSON.stringify({
            deleted_template: {
                name: existingTemplate.name,
                total_sessions: existingTemplate.total_sessions,
                validity_days: existingTemplate.validity_days,
                price: existingTemplate.price
            },
            deleted_by: req.user.name
        })]);

        res.json({
            message: '회원권 템플릿이 삭제되었습니다.',
            deletedTemplate: {
                id: templateId,
                name: existingTemplate.name
            }
        });

    } catch (error) {
        console.error('Delete membership template error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: '회원권 템플릿 삭제 중 오류가 발생했습니다.'
        });
    }
});

module.exports = router;