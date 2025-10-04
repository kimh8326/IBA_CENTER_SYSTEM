import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String type;
  final String title;
  final String message;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'related_entity_type')
  final String? relatedEntityType;
  @JsonKey(name: 'related_entity_id')
  final int? relatedEntityId;
  @JsonKey(name: 'created_at')
  final String createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // SQLite에서 boolean이 정수로 저장되므로 변환 필요
    final Map<String, dynamic> convertedJson = Map<String, dynamic>.from(json);
    if (convertedJson['is_read'] is int) {
      convertedJson['is_read'] = convertedJson['is_read'] == 1;
    }

    return _$AppNotificationFromJson(convertedJson);
  }

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  DateTime get createdAtDateTime => DateTime.parse(createdAt);

  String get displayType {
    switch (type) {
      case 'CLASS_REMINDER':
        return '수업 알림';
      case 'CLASS_CANCELLATION':
        return '수업 취소';
      case 'MEMBERSHIP_EXPIRING':
        return '회원권 만료';
      case 'ADMIN_MESSAGE':
        return '관리자 메시지';
      case 'SYSTEM':
        return '시스템';
      default:
        return type;
    }
  }
}

@JsonSerializable()
class NotificationListResponse {
  final List<AppNotification> notifications;
  final Pagination pagination;

  NotificationListResponse({
    required this.notifications,
    required this.pagination,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationListResponseToJson(this);
}

@JsonSerializable()
class Pagination {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'totalPages')
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
