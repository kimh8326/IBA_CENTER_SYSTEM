import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final provider = context.read<NotificationProvider>();

    bool? isRead;
    if (_filter == 'unread') {
      isRead = false;
    } else if (_filter == 'read') {
      isRead = true;
    }

    await provider.loadNotifications(isRead: isRead);
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    final provider = context.read<NotificationProvider>();
    final success = await provider.markAsRead(notification.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림을 읽음 처리했습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final provider = context.read<NotificationProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 알림 읽음 처리'),
        content: const Text('모든 알림을 읽음 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.markAllAsRead();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알림을 읽음 처리했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('모두 읽음 처리'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('전체'),
                  icon: Icon(Icons.all_inbox),
                ),
                ButtonSegment(
                  value: 'unread',
                  label: Text('안읽음'),
                  icon: Icon(Icons.circle, size: 12),
                ),
                ButtonSegment(
                  value: 'read',
                  label: Text('읽음'),
                  icon: Icon(Icons.done),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _filter = selected.first;
                });
                _loadNotifications();
              },
            ),
          ),

          // 알림 목록
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '알림을 불러올 수 없습니다',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadNotifications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'unread'
                              ? '읽지 않은 알림이 없습니다'
                              : _filter == 'read'
                                  ? '읽은 알림이 없습니다'
                                  : '알림이 없습니다',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () => _markAsRead(notification),
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

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'CLASS_REMINDER':
        return Icons.access_time;
      case 'CLASS_CANCELLATION':
        return Icons.cancel;
      case 'MEMBERSHIP_EXPIRING':
        return Icons.warning_amber;
      case 'ADMIN_MESSAGE':
        return Icons.campaign;
      case 'SYSTEM':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'CLASS_REMINDER':
        return Colors.blue;
      case 'CLASS_CANCELLATION':
        return Colors.red;
      case 'MEMBERSHIP_EXPIRING':
        return Colors.orange;
      case 'ADMIN_MESSAGE':
        return Colors.purple;
      case 'SYSTEM':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.grey[100] : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: notification.isRead
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.displayType,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MM월 dd일 HH:mm', 'ko')
                              .format(notification.createdAtDateTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
