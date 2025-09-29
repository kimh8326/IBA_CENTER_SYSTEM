// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schedule _$ScheduleFromJson(Map<String, dynamic> json) => Schedule(
  id: (json['id'] as num).toInt(),
  classTypeId: (json['class_type_id'] as num).toInt(),
  instructorId: (json['instructor_id'] as num).toInt(),
  scheduledAt: json['scheduled_at'] as String,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  maxCapacity: (json['max_capacity'] as num).toInt(),
  currentCapacity: (json['current_capacity'] as num).toInt(),
  status: json['status'] as String,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
  instructorName: json['instructor_name'] as String?,
  classTypeName: json['class_type_name'] as String?,
  classColor: json['class_color'] as String?,
);

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
  'id': instance.id,
  'class_type_id': instance.classTypeId,
  'instructor_id': instance.instructorId,
  'scheduled_at': instance.scheduledAt,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'current_capacity': instance.currentCapacity,
  'status': instance.status,
  'notes': instance.notes,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'instructor_name': instance.instructorName,
  'class_type_name': instance.classTypeName,
  'class_color': instance.classColor,
};

ClassType _$ClassTypeFromJson(Map<String, dynamic> json) => ClassType(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  maxCapacity: (json['max_capacity'] as num).toInt(),
  color: json['color'] as String,
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$ClassTypeToJson(ClassType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'color': instance.color,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
};

CreateScheduleRequest _$CreateScheduleRequestFromJson(
  Map<String, dynamic> json,
) => CreateScheduleRequest(
  classTypeId: (json['class_type_id'] as num).toInt(),
  instructorId: (json['instructor_id'] as num).toInt(),
  scheduledAt: json['scheduled_at'] as String,
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  maxCapacity: (json['max_capacity'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CreateScheduleRequestToJson(
  CreateScheduleRequest instance,
) => <String, dynamic>{
  'class_type_id': instance.classTypeId,
  'instructor_id': instance.instructorId,
  'scheduled_at': instance.scheduledAt,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'notes': instance.notes,
};
