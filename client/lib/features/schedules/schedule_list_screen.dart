import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/schedule.dart';

Color _parseColorString(String colorString, Color defaultColor) {
  try {
    String cleanedColor = colorString.replaceAll('#', '');
    if (cleanedColor.length == 6) {
      return Color(int.parse('0xFF$cleanedColor'));
    }
    return defaultColor;
  } catch (e) {
    return defaultColor;
  }
}

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
    });
  }

  void _loadSchedules() {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<ScheduleProvider>().loadSchedules(date: dateString);
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 날짜 선택 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 스케줄 목록
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (context, scheduleProvider, _) {
                if (scheduleProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (scheduleProvider.error != null) {
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
                          scheduleProvider.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadSchedules,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                final daySchedules = scheduleProvider.getSchedulesByDate(_selectedDate);

                if (daySchedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '선택한 날짜에 수업이 없습니다',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadSchedules(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daySchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = daySchedules[index];
                      return _ScheduleCard(schedule: schedule);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.hasPermission('manage_schedules')) {
            return FloatingActionButton(
              onPressed: () {
                // 새 스케줄 생성 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('스케줄 생성 기능 준비 중입니다'),
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateFormat('HH:mm').format(schedule.dateTime);
    final endTime = DateFormat('HH:mm').format(schedule.endTime);
    
    Color statusColor = theme.colorScheme.primary;
    if (schedule.isFull) {
      statusColor = theme.colorScheme.error;
    } else if (schedule.currentCapacity > schedule.maxCapacity * 0.8) {
      statusColor = Colors.orange;
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
                // 수업 타입 아이콘
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _parseColorString(schedule.classColor ?? '6366F1', Colors.indigo),
                  child: Text(
                    schedule.classTypeName?.substring(0, 1) ?? 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 수업 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.classTypeName ?? '수업',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '강사: ${schedule.instructorName ?? '미정'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // 시간 정보
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$startTime - $endTime',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${schedule.durationMinutes}분',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 예약 현황
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: schedule.maxCapacity > 0 
                        ? schedule.currentCapacity / schedule.maxCapacity 
                        : 0,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${schedule.currentCapacity}/${schedule.maxCapacity}명',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 상태 및 액션 버튼
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    schedule.statusDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.user?.isMember == true && schedule.isAvailable) {
                      return TextButton(
                        onPressed: () {
                          // 예약하기
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('예약 기능 준비 중입니다'),
                            ),
                          );
                        },
                        child: const Text('예약하기'),
                      );
                    }
                    
                    if (authProvider.hasPermission('manage_schedules')) {
                      return TextButton(
                        onPressed: () {
                          // 예약 현황 보기
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('예약 현황 보기 기능 준비 중입니다'),
                            ),
                          );
                        },
                        child: const Text('예약 현황'),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            
            if (schedule.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  schedule.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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