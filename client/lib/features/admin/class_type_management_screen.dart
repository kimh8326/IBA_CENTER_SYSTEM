import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/models/class_type.dart';

class ClassTypeManagementScreen extends StatefulWidget {
  const ClassTypeManagementScreen({super.key});

  @override
  State<ClassTypeManagementScreen> createState() => _ClassTypeManagementScreenState();
}

class _ClassTypeManagementScreenState extends State<ClassTypeManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  
  List<ClassType> _classTypes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClassTypes();
  }

  Future<void> _loadClassTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('/class-types');
      final List<dynamic> data = response['classTypes'];
      
      _classTypes = data
          .map((json) => ClassType.fromJson(json as Map<String, dynamic>))
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

  Future<void> _showAddEditDialog({ClassType? classType}) async {
    final isEditing = classType != null;
    final nameController = TextEditingController(text: classType?.name ?? '');
    final descriptionController = TextEditingController(text: classType?.description ?? '');
    final durationController = TextEditingController(text: classType?.durationMinutes.toString() ?? '50');
    final capacityController = TextEditingController(text: classType?.maxCapacity.toString() ?? '1');
    final priceController = TextEditingController(text: classType?.price?.toString() ?? '');
    String selectedColor = classType?.color ?? '#6B4EFF';
    bool isActive = classType?.isActive ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '수업 타입 수정' : '새 수업 타입 추가'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '수업 이름 *',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          decoration: const InputDecoration(
                            labelText: '수업 시간 (분) *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: capacityController,
                          decoration: const InputDecoration(
                            labelText: '최대 인원 *',
                            border: OutlineInputBorder(),
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
                      labelText: '가격 (원)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('테마 색상: '),
                      const SizedBox(width: 8),
                      ...['#6B4EFF', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8']
                          .map((color) => GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${color.replaceAll('#', '')}')),
                                    shape: BoxShape.circle,
                                    border: selectedColor == color
                                        ? Border.all(color: Colors.black, width: 2)
                                        : null,
                                  ),
                                ),
                              ))
                          .toList(),
                    ],
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
                    durationController.text.trim().isEmpty ||
                    capacityController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('필수 항목을 입력해주세요')),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'durationMinutes': int.parse(durationController.text.trim()),
                  'maxCapacity': int.parse(capacityController.text.trim()),
                  'price': priceController.text.trim().isNotEmpty 
                      ? double.parse(priceController.text.trim())
                      : null,
                  'color': selectedColor,
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
        await _updateClassType(classType!.id, result);
      } else {
        await _createClassType(result);
      }
    }
  }

  Future<void> _createClassType(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/class-types', data);
      await _loadClassTypes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수업 타입이 추가되었습니다')),
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

  Future<void> _updateClassType(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/class-types/$id', data);
      await _loadClassTypes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수업 타입이 수정되었습니다')),
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

  Future<void> _deleteClassType(ClassType classType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${classType.name} 수업 타입을 삭제하시겠습니까?\n관련된 스케줄과 예약도 함께 삭제됩니다.'),
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
        await _apiClient.delete('/class-types/${classType.id}');
        await _loadClassTypes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수업 타입이 삭제되었습니다')),
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
        title: const Text('수업 타입 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            tooltip: '새 수업 타입 추가',
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
                  Icons.class_,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '총 ${_classTypes.length}개 수업 타입',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '활성: ${_classTypes.where((c) => c.isActive).length}개',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _buildClassTypeList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTypeList(ThemeData theme) {
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
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadClassTypes,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_classTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 수업 타입이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showAddEditDialog(),
              child: const Text('첫 수업 타입 추가'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassTypes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classTypes.length,
        itemBuilder: (context, index) {
          final classType = _classTypes[index];
          return _ClassTypeCard(
            classType: classType,
            onEdit: () => _showAddEditDialog(classType: classType),
            onDelete: () => _deleteClassType(classType),
          );
        },
      ),
    );
  }
}

class _ClassTypeCard extends StatelessWidget {
  final ClassType classType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassTypeCard({
    required this.classType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = Color(int.parse('0xFF${classType.color.replaceAll('#', '')}'));

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
                  backgroundColor: cardColor,
                  child: Text(
                    classType.name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                            classType.name,
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
                              color: classType.isActive 
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              classType.isActive ? '활성' : '비활성',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: classType.isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (classType.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          classType.description!,
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
                  icon: Icons.schedule,
                  label: '${classType.durationMinutes}분',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.people,
                  label: '최대 ${classType.maxCapacity}명',
                ),
                if (classType.price != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '${classType.price!.toStringAsFixed(0)}원',
                  ),
                ],
              ],
            ),
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