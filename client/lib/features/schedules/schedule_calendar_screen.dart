import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/schedule.dart';
import '../../core/models/booking.dart';
import 'schedule_create_screen.dart';

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

class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  late final ValueNotifier<List<Schedule>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();

    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthSchedules();
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _loadMonthSchedules() {
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    context.read<ScheduleProvider>().loadSchedules(
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
    );
  }

  List<Schedule> _getEventsForDay(DateTime day) {
    final scheduleProvider = context.read<ScheduleProvider>();
    return scheduleProvider.getSchedulesByDate(day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _loadMonthSchedules();
  }

  Future<void> _bookSchedule(Schedule schedule) async {
    // 예약 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('수업 예약'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.classTypeName ?? '수업',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('강사: ${schedule.instructorName ?? '미정'}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MM월 dd일 HH:mm', 'ko_KR').format(schedule.dateTime)} (${schedule.durationMinutes}분)',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('잔여 자리: ${schedule.availableSpots}/${schedule.maxCapacity}명'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '이 수업을 예약하시겠습니까?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예약하기'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    // 예약 생성
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final theme = Theme.of(context);
    
    final request = CreateBookingRequest(
      scheduleId: schedule.id,
      userId: authProvider.user?.id,
      bookingType: 'regular',
    );

    final success = await bookingProvider.createBooking(request);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('수업 예약이 완료되었습니다'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        
        // 스케줄 목록 새로고침
        _loadMonthSchedules();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 실패: ${bookingProvider.error ?? '알 수 없는 오류'}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelSchedule(Schedule schedule) async {
    // 취소 사유 입력 다이얼로그
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수업 취소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 수업을 취소하시겠습니까?\n\n해당 수업을 예약한 모든 회원과 담당 강사에게 알림이 발송됩니다.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '취소 사유',
                hintText: '취소 사유를 입력해주세요',
              ),
              onChanged: (value) => reason = value,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('수업 취소'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context.read<ScheduleProvider>().cancelSchedule(
      schedule.id,
      reason: reason,
    );

    if (success && mounted) {
      // 성공 시 관련 데이터 새로고침
      await Future.wait([
        context.read<BookingProvider>().loadBookings(),
        context.read<NotificationProvider>().loadUnreadCount(),
      ]);

      _loadMonthSchedules();
      _selectedEvents.value = _getEventsForDay(_selectedDay!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수업이 취소되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<ScheduleProvider>().error ?? '수업 취소에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToScheduleCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleCreateScreen(
          initialDate: _selectedDay,
        ),
      ),
    );

    // 스케줄 생성이 성공한 경우 달력 새로고침
    if (result == true) {
      _loadMonthSchedules();
      // 선택된 날짜의 스케줄도 업데이트
      if (_selectedDay != null) {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 달력 헤더
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
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '스케줄 달력',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<ScheduleProvider>(
                  builder: (context, scheduleProvider, _) {
                    if (scheduleProvider.isLoading) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // 달력 위젯
          Consumer<ScheduleProvider>(
            builder: (context, scheduleProvider, _) {
              return TableCalendar<Schedule>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[400]),
                  holidayTextStyle: TextStyle(color: Colors.red[400]),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: _onFormatChanged,
                onPageChanged: _onPageChanged,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return _buildEventMarkers(context, events, theme);
                    }
                    return null;
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // 선택된 날짜의 스케줄 목록
          Expanded(
            child: ValueListenableBuilder<List<Schedule>>(
              valueListenable: _selectedEvents,
              builder: (context, schedules, _) {
                return _buildScheduleList(context, schedules, theme);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.hasPermission('manage_schedules')) {
            return FloatingActionButton(
              onPressed: () => _navigateToScheduleCreate(),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEventMarkers(BuildContext context, List<Schedule> events, ThemeData theme) {
    final groupedEvents = <String, List<Schedule>>{};
    for (final event in events) {
      final classType = event.classTypeName ?? 'Unknown';
      groupedEvents[classType] = (groupedEvents[classType] ?? [])..add(event);
    }

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: groupedEvents.entries.take(3).map((entry) {
          final classType = entry.key;
          final schedules = entry.value;
          final color = schedules.first.classColor != null
              ? _parseColorString(schedules.first.classColor!, theme.colorScheme.primary)
              : theme.colorScheme.primary;

          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context, List<Schedule> schedules, ThemeData theme) {
    if (schedules.isEmpty) {
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
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDay!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선택된 날짜 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedDay != null
                ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDay!)
                : '',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 8),

        // 스케줄 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final authProvider = context.read<AuthProvider>();
              return _ScheduleCard(
                schedule: schedule,
                onBook: _bookSchedule,
                onCancel: authProvider.user?.isMaster == true
                    ? _cancelSchedule
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final Function(Schedule)? onBook;
  final Function(Schedule)? onCancel;

  const _ScheduleCard({
    required this.schedule,
    this.onBook,
    this.onCancel,
  });

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

    final classColor = schedule.classColor != null
        ? _parseColorString(schedule.classColor!, theme.colorScheme.primary)
        : theme.colorScheme.primary;

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
                  backgroundColor: classColor,
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
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                          if (onBook != null) {
                            onBook!(schedule);
                          }
                        },
                        child: const Text('예약하기'),
                      );
                    }
                    
                    if (authProvider.hasPermission('manage_schedules')) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('예약 현황 보기 기능 준비 중입니다'),
                                ),
                              );
                            },
                            child: const Text('예약 현황'),
                          ),
                          if (onCancel != null && schedule.status != 'cancelled')
                            TextButton.icon(
                              onPressed: () {
                                if (onCancel != null) {
                                  onCancel!(schedule);
                                }
                              },
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('수업 취소'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                        ],
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
                  color: theme.colorScheme.surfaceContainerHighest,
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