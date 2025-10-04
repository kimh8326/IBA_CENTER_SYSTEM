import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/class_type.dart';
import '../../core/models/user.dart';

class ScheduleCreateScreen extends StatefulWidget {
  final DateTime? initialDate;
  
  const ScheduleCreateScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<ScheduleCreateScreen> createState() => _ScheduleCreateScreenState();
}

class _ScheduleCreateScreenState extends State<ScheduleCreateScreen> {
  final ApiClient _apiClient = ApiClient();
  
  // Form controllers
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  ClassType? _selectedClassType;
  User? _selectedInstructor;
  int _duration = 50;
  int _maxCapacity = 1;
  String _notes = '';
  
  // Data
  List<ClassType> _classTypes = [];
  List<ClassType> _filteredClassTypes = [];
  List<User> _instructors = [];

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadClassTypes(),
        _loadInstructors(),
      ]);
      // 초기에는 모든 수업 타입을 보여줌
      setState(() {
        _filteredClassTypes = _classTypes;
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
          .where((classType) => classType.isActive)
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수업 타입 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadInstructors() async {
    try {
      final response = await _apiClient.get('/instructors');
      final List<dynamic> data = response['instructors'];
      
      _instructors = data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .where((instructor) => instructor.isActive)
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('강사 목록 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onClassTypeChanged(ClassType? classType) {
    setState(() {
      _selectedClassType = classType;
      if (classType != null) {
        _duration = classType.durationMinutes;
        _maxCapacity = classType.maxCapacity;
      }
    });
  }

  void _onInstructorChanged(User? instructor) {
    setState(() {
      _selectedInstructor = instructor;

      if (instructor == null || instructor.teachableClassTypeIds == null || instructor.teachableClassTypeIds!.isEmpty) {
        // 강사가 선택되지 않았거나, 가르칠 수 있는 수업이 없으면 모든 수업 타입을 보여줌
        _filteredClassTypes = _classTypes;
      } else {
        // 강사가 가르칠 수 있는 수업만 필터링
        final teachableIds = instructor.teachableClassTypeIds!.toSet();
        _filteredClassTypes = _classTypes.where((ct) => teachableIds.contains(ct.id)).toList();
      }

      // 만약 이전에 선택된 수업 타입이 필터링된 목록에 없다면 선택 해제
      if (_selectedClassType != null && !_filteredClassTypes.contains(_selectedClassType)) {
        _selectedClassType = null;
      }
    });
  }

  Future<void> _createSchedule() async {
    if (_selectedClassType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수업 타입을 선택해주세요')),
      );
      return;
    }

    if (_selectedInstructor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('강사를 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final scheduleData = {
        'class_type_id': _selectedClassType!.id,
        'instructor_id': _selectedInstructor!.id,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': _duration,
        'max_capacity': _maxCapacity,
        'notes': _notes.trim().isEmpty ? null : _notes.trim(),
      };

      final response = await _apiClient.post('/schedules', scheduleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '스케줄이 성공적으로 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // 생성 성공 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스케줄 생성 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('스케줄 생성'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('스케줄 생성'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createSchedule,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('생성'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 및 시간 설정
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '일정',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('날짜'),
                            subtitle: Text(DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(_selectedDate)),
                            onTap: _selectDate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('시간'),
                            subtitle: Text(_selectedTime.format(context)),
                            onTap: _selectTime,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 수업 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '수업 정보',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ClassType>(
                      value: _selectedClassType,
                      decoration: const InputDecoration(
                        labelText: '수업 타입 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: _filteredClassTypes.map((classType) {
                        return DropdownMenuItem<ClassType>(
                          value: classType,
                          child: Text(classType.name),
                        );
                      }).toList(),
                      onChanged: _onClassTypeChanged,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<User>(
                      value: _selectedInstructor,
                      decoration: const InputDecoration(
                        labelText: '강사 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _instructors.map((instructor) {
                        return DropdownMenuItem<User>(
                          value: instructor,
                          child: Text(instructor.name),
                        );
                      }).toList(),
                      onChanged: _onInstructorChanged,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _duration.toString(),
                            decoration: const InputDecoration(
                              labelText: '수업 시간 (분)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              final minutes = int.tryParse(value);
                              if (minutes != null && minutes > 0) {
                                _duration = minutes;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _maxCapacity.toString(),
                            decoration: const InputDecoration(
                              labelText: '최대 인원',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              final capacity = int.tryParse(value);
                              if (capacity != null && capacity > 0) {
                                _maxCapacity = capacity;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 메모
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '메모 (선택사항)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '수업에 대한 특별한 안내사항이 있으면 입력하세요',
                      ),
                      onChanged: (value) {
                        _notes = value;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 요약 정보
            if (_selectedClassType != null && _selectedInstructor != null)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '생성될 스케줄 정보',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• 수업: ${_selectedClassType!.name}\n'
                        '• 강사: ${_selectedInstructor!.name}\n'
                        '• 일시: ${DateFormat('MM월 dd일 (E) HH:mm', 'ko').format(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute))}\n'
                        '• 소요시간: ${_duration}분\n'
                        '• 최대인원: ${_maxCapacity}명',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}