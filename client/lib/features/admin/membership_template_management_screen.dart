import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/models/membership_template.dart';
import '../../core/models/class_type.dart';

class MembershipTemplateManagementScreen extends StatefulWidget {
  const MembershipTemplateManagementScreen({super.key});

  @override
  State<MembershipTemplateManagementScreen> createState() => _MembershipTemplateManagementScreenState();
}

class _MembershipTemplateManagementScreenState extends State<MembershipTemplateManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  
  List<MembershipTemplate> _templates = [];
  List<ClassType> _classTypes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTemplates(),
      _loadClassTypes(),
    ]);
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('/membership-templates');
      final List<dynamic> data = response['membershipTemplates'];
      
      _templates = data
          .map((json) => MembershipTemplate.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassTypes() async {
    try {
      final response = await _apiClient.get('/class-types');
      final List<dynamic> data = response['classTypes'];
      
      _classTypes = data
          .map((json) => ClassType.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 수업 타입 로드 실패는 무시 (선택사항이므로)
    }
  }

  Future<void> _showAddEditDialog({MembershipTemplate? template}) async {
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descriptionController = TextEditingController(text: template?.description ?? '');
    final sessionsController = TextEditingController(text: template?.totalSessions.toString() ?? '10');
    final validityController = TextEditingController(text: template?.validityDays.toString() ?? '90');
    final priceController = TextEditingController(text: template?.price.toString() ?? '');
    int? selectedClassTypeId = template?.classTypeId;
    bool isActive = template?.isActive ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '회원권 템플릿 수정' : '새 회원권 템플릿 추가'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '회원권 이름 *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: '설명',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedClassTypeId,
                    decoration: const InputDecoration(
                      labelText: '수업 타입 (선택사항)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('수업 타입 미지정 (범용)'),
                      ),
                      ..._classTypes.where((ct) => ct.isActive).map((classType) =>
                        DropdownMenuItem<int?>(
                          value: classType.id,
                          child: Text(classType.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedClassTypeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sessionsController,
                          decoration: const InputDecoration(
                            labelText: '총 세션 수 *',
                            border: OutlineInputBorder(),
                            suffix: Text('회'),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: validityController,
                          decoration: const InputDecoration(
                            labelText: '유효 기간 *',
                            border: OutlineInputBorder(),
                            suffix: Text('일'),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: '가격 *',
                      border: OutlineInputBorder(),
                      suffix: Text('원'),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('활성 상태'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    sessionsController.text.trim().isEmpty ||
                    validityController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('필수 항목을 입력해주세요')),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'classTypeId': selectedClassTypeId,
                  'totalSessions': int.parse(sessionsController.text.trim()),
                  'validityDays': int.parse(validityController.text.trim()),
                  'price': double.parse(priceController.text.trim()),
                  'isActive': isActive,
                });
              },
              child: Text(isEditing ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (isEditing) {
        await _updateTemplate(template!.id, result);
      } else {
        await _createTemplate(result);
      }
    }
  }

  Future<void> _createTemplate(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/membership-templates', data);
      await _loadTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원권 템플릿이 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 실패: $e')),
        );
      }
    }
  }

  Future<void> _updateTemplate(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/membership-templates/$id', data);
      await _loadTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원권 템플릿이 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(MembershipTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${template.name} 회원권 템플릿을 삭제하시겠습니까?\n활성화된 회원권이 있는 경우 삭제할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiClient.delete('/membership-templates/${template.id}');
        await _loadTemplates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원권 템플릿이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원권 템플릿 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: '새 회원권 템플릿 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '총 ${_templates.length}개 회원권 템플릿',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '활성: ${_templates.where((t) => t.isActive).length}개',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _buildTemplateList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTemplates,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 회원권 템플릿이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showAddEditDialog(),
              child: const Text('첫 회원권 템플릿 추가'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return _TemplateCard(
            template: template,
            onEdit: () => _showAddEditDialog(template: template),
            onDelete: () => _deleteTemplate(template),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final MembershipTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? cardColor;
    
    if (template.classTypeColor != null) {
      try {
        cardColor = Color(int.parse('0xFF${template.classTypeColor!.replaceAll('#', '')}'));
      } catch (e) {
        cardColor = theme.colorScheme.primary;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cardColor ?? theme.colorScheme.primary,
                  child: Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            template.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: template.isActive 
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              template.isActive ? '활성' : '비활성',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: template.isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (template.classTypeName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '수업 타입: ${template.classTypeName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (template.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          template.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: template.sessionsText,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.schedule,
                  label: template.validityText,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: template.priceText,
                ),
              ],
            ),
            
            if (template.activeMemberships != null && template.activeMemberships! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '활성 회원권: ${template.activeMemberships}개',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}