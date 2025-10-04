import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 알림 목록 로드
  Future<void> loadNotifications({bool? isRead, int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (isRead != null) {
        queryParams['is_read'] = isRead.toString();
      }

      final response = await _apiClient.get('/notifications', queryParams: queryParams);

      final notificationList = NotificationListResponse.fromJson(response);
      _notifications = notificationList.notifications;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ NotificationProvider: 알림 로드 실패 - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 안 읽은 알림 개수 로드
  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      _unreadCount = response['unreadCount'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ NotificationProvider: 안 읽은 알림 개수 로드 실패 - $e');
    }
  }

  /// 특정 알림 읽음 처리
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _apiClient.put('/notifications/$notificationId/read', {});

      // 로컬 상태 업데이트
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }

      // 알림 목록 새로고침
      await loadNotifications();

      return true;
    } catch (e) {
      debugPrint('❌ NotificationProvider: 알림 읽음 처리 실패 - $e');
      return false;
    }
  }

  /// 모든 알림 읽음 처리
  Future<bool> markAllAsRead() async {
    try {
      await _apiClient.put('/notifications/read-all', {});

      _unreadCount = 0;

      // 알림 목록 새로고침
      await loadNotifications();

      return true;
    } catch (e) {
      debugPrint('❌ NotificationProvider: 모든 알림 읽음 처리 실패 - $e');
      return false;
    }
  }

  /// 관리자 메시지 발송 (Master 전용)
  Future<bool> sendAdminMessage({
    required String target, // 'all_members', 'all_instructors', 또는 userId
    required String title,
    required String message,
  }) async {
    try {
      await _apiClient.post('/notifications/admin-message', {
        'target': target,
        'title': title,
        'message': message,
      });

      return true;
    } catch (e) {
      debugPrint('❌ NotificationProvider: 관리자 메시지 발송 실패 - $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 알림 데이터 초기화 (로그아웃 시 사용)
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
