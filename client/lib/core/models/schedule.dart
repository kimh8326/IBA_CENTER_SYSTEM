import 'package:json_annotation/json_annotation.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  final int id;
  @JsonKey(name: 'class_type_id')
  final int classTypeId;
  @JsonKey(name: 'instructor_id')
  final int instructorId;
  @JsonKey(name: 'scheduled_at')
  final String scheduledAt;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int maxCapacity;
  @JsonKey(name: 'current_capacity')
  final int currentCapacity;
  final String status;
  final String? notes;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  
  // 조인된 데이터
  @JsonKey(name: 'instructor_name')
  final String? instructorName;
  @JsonKey(name: 'class_type_name')
  final String? classTypeName;
  @JsonKey(name: 'class_color')
  final String? classColor;

  Schedule({
    required this.id,
    required this.classTypeId,
    required this.instructorId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.maxCapacity,
    required this.currentCapacity,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.instructorName,
    this.classTypeName,
    this.classColor,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleToJson(this);

  bool get isAvailable => currentCapacity < maxCapacity && status == 'scheduled';
  bool get isFull => currentCapacity >= maxCapacity;
  int get availableSpots => maxCapacity - currentCapacity;
  
  DateTime get dateTime => DateTime.parse(scheduledAt);
  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));

  String get statusDisplay {
    switch (status) {
      case 'scheduled':
        return '예약 가능';
      case 'in_progress':
        return '진행 중';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소됨';
      default:
        return status;
    }
  }
}

@JsonSerializable()
class ClassType {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int maxCapacity;
  final String color;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;

  ClassType({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.maxCapacity,
    required this.color,
    required this.isActive,
    required this.createdAt,
  });

  factory ClassType.fromJson(Map<String, dynamic> json) =>
      _$ClassTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ClassTypeToJson(this);
}

@JsonSerializable()
class CreateScheduleRequest {
  @JsonKey(name: 'class_type_id')
  final int classTypeId;
  @JsonKey(name: 'instructor_id')
  final int instructorId;
  @JsonKey(name: 'scheduled_at')
  final String scheduledAt;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'max_capacity')
  final int? maxCapacity;
  final String? notes;

  CreateScheduleRequest({
    required this.classTypeId,
    required this.instructorId,
    required this.scheduledAt,
    this.durationMinutes,
    this.maxCapacity,
    this.notes,
  });

  factory CreateScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateScheduleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateScheduleRequestToJson(this);
}