import 'package:json_annotation/json_annotation.dart';

part 'class_type.g.dart';

@JsonSerializable()
class ClassType {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int maxCapacity;
  final double? price;
  final String color;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  ClassType({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.maxCapacity,
    this.price,
    required this.color,
    required this.isActive,
    this.createdAt,
  });

  factory ClassType.fromJson(Map<String, dynamic> json) {
    // SQLite에서 boolean이 정수로 저장되므로 변환 필요
    final Map<String, dynamic> convertedJson = Map<String, dynamic>.from(json);
    if (convertedJson['is_active'] is int) {
      convertedJson['is_active'] = convertedJson['is_active'] == 1;
    }
    
    // 기본값 처리
    convertedJson['name'] ??= '';
    convertedJson['color'] ??= '#6B4EFF';
    convertedJson['duration_minutes'] ??= 50;
    convertedJson['max_capacity'] ??= 1;
    
    return _$ClassTypeFromJson(convertedJson);
  }
  
  Map<String, dynamic> toJson() => _$ClassTypeToJson(this);

  DateTime get createdAtDateTime {
    return createdAt != null ? DateTime.parse(createdAt!) : DateTime.now();
  }
}

@JsonSerializable()
class CreateClassTypeRequest {
  final String name;
  final String? description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int maxCapacity;
  final double? price;
  final String color;
  @JsonKey(name: 'is_active')
  final bool isActive;

  CreateClassTypeRequest({
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.maxCapacity,
    this.price,
    required this.color,
    required this.isActive,
  });

  factory CreateClassTypeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateClassTypeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateClassTypeRequestToJson(this);
}

@JsonSerializable()
class UpdateClassTypeRequest {
  final String? name;
  final String? description;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int? maxCapacity;
  final double? price;
  final String? color;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  UpdateClassTypeRequest({
    this.name,
    this.description,
    this.durationMinutes,
    this.maxCapacity,
    this.price,
    this.color,
    this.isActive,
  });

  factory UpdateClassTypeRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateClassTypeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateClassTypeRequestToJson(this);
}