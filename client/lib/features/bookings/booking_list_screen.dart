import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/booking.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  String _selectedFilter = 'confirmed';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() {
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    
    if (authProvider.user?.isMember == true) {
      // 회원은 자신의 예약만 보기
      bookingProvider.loadBookings(userId: authProvider.user!.id);
    } else {
      // 관리자/강사는 모든 예약 보기
      bookingProvider.loadBookings();
    }
  }

  void _cancelBooking(Booking booking) async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    final success = await context.read<BookingProvider>().cancelBooking(
      booking.id,
      reason: reason,
    );

    if (success && mounted) {
      // 예약 취소 성공 시 스케줄과 알림도 새로고침
      await Future.wait([
        context.read<ScheduleProvider>().loadSchedules(),
        context.read<NotificationProvider>().loadUnreadCount(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 취소되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<BookingProvider>().error ?? '취소에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 삭제'),
        content: const Text('예약을 완전히 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context.read<BookingProvider>().deleteBooking(booking.id);

    if (success && mounted) {
      // 예약 삭제 성공 시 스케줄도 새로고침
      await context.read<ScheduleProvider>().loadSchedules();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<BookingProvider>().error ?? '삭제에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showCancelDialog() async {
    String? reason;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('예약을 취소하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '취소 사유 (선택)',
                hintText: '취소 사유를 입력해주세요',
              ),
              onChanged: (value) => reason = value,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reason ?? '사용자 요청'),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 필터 선택
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
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'confirmed',
                        label: Text('확정'),
                      ),
                      ButtonSegment<String>(
                        value: 'cancelled',
                        label: Text('취소'),
                      ),
                      ButtonSegment<String>(
                        value: 'all',
                        label: Text('전체'),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _selectedFilter = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 예약 목록
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, _) {
                if (bookingProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (bookingProvider.error != null) {
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
                          bookingProvider.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadBookings,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                List<Booking> filteredBookings = bookingProvider.bookings;
                
                if (_selectedFilter != 'all') {
                  filteredBookings = bookingProvider.bookings
                      .where((booking) => booking.bookingStatus == _selectedFilter)
                      .toList();
                }

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '예약이 없습니다',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final authProvider = context.read<AuthProvider>();
                      return _BookingCard(
                        booking: booking,
                        onCancel: () => _cancelBooking(booking),
                        onDelete: authProvider.user?.isMaster == true
                            ? () => _deleteBooking(booking)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const _BookingCard({
    required this.booking,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor = theme.colorScheme.primary;
    IconData statusIcon = Icons.check_circle;
    
    if (booking.isCancelled) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.cancel;
    } else if (booking.isWaiting) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    final scheduleDateTime = booking.scheduleDateTime;
    String timeText = '시간 미정';
    if (scheduleDateTime != null) {
      timeText = DateFormat('MM월 dd일 (E) HH:mm', 'ko_KR').format(scheduleDateTime);
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
                // 상태 아이콘
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                
                // 수업 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.classTypeName ?? '수업',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '강사: ${booking.instructorName ?? '미정'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // 예약 상태
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
                    booking.statusDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 시간 및 예약 정보
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.typeDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            if (booking.userName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '예약자: ${booking.userName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            
            // 예약 날짜
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.bookedAt != null
                      ? '예약일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(booking.bookedAt!))}'
                      : '예약일: -',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            // 취소 정보 (취소된 경우)
            if (booking.isCancelled && booking.cancelReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '취소 사유:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      booking.cancelReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 액션 버튼
            if (booking.isActive && onCancel != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('취소'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],

            // 삭제 버튼 (관리자 전용, 취소된 예약)
            if (booking.isCancelled && onDelete != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}