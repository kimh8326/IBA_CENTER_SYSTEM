// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: (json['related_entity_id'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'is_read': instance.isRead,
      'related_entity_type': instance.relatedEntityType,
      'related_entity_id': instance.relatedEntityId,
      'created_at': instance.createdAt,
    };

NotificationListResponse _$NotificationListResponseFromJson(
  Map<String, dynamic> json,
) => NotificationListResponse(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NotificationListResponseToJson(
  NotificationListResponse instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'pagination': instance.pagination,
};

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
    };
