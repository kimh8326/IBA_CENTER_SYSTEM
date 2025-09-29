// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassType _$ClassTypeFromJson(Map<String, dynamic> json) => ClassType(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  maxCapacity: (json['max_capacity'] as num).toInt(),
  price: (json['price'] as num?)?.toDouble(),
  color: json['color'] as String,
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$ClassTypeToJson(ClassType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'price': instance.price,
  'color': instance.color,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
};

CreateClassTypeRequest _$CreateClassTypeRequestFromJson(
  Map<String, dynamic> json,
) => CreateClassTypeRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  maxCapacity: (json['max_capacity'] as num).toInt(),
  price: (json['price'] as num?)?.toDouble(),
  color: json['color'] as String,
  isActive: json['is_active'] as bool,
);

Map<String, dynamic> _$CreateClassTypeRequestToJson(
  CreateClassTypeRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'price': instance.price,
  'color': instance.color,
  'is_active': instance.isActive,
};

UpdateClassTypeRequest _$UpdateClassTypeRequestFromJson(
  Map<String, dynamic> json,
) => UpdateClassTypeRequest(
  name: json['name'] as String?,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  maxCapacity: (json['max_capacity'] as num?)?.toInt(),
  price: (json['price'] as num?)?.toDouble(),
  color: json['color'] as String?,
  isActive: json['is_active'] as bool?,
);

Map<String, dynamic> _$UpdateClassTypeRequestToJson(
  UpdateClassTypeRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'duration_minutes': instance.durationMinutes,
  'max_capacity': instance.maxCapacity,
  'price': instance.price,
  'color': instance.color,
  'is_active': instance.isActive,
};
