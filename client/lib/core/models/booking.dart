import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final int id;
  @JsonKey(name: 'schedule_id')
  final int scheduleId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'membership_id')
  final int? membershipId;
  @JsonKey(name: 'booking_type')
  final String bookingType;
  @JsonKey(name: 'booking_status')
  final String bookingStatus;
  @JsonKey(name: 'booked_at')
  final String bookedAt;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;
  @JsonKey(name: 'cancel_reason')
  final String? cancelReason;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  // 조인된 데이터
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'user_phone')
  final String? userPhone;
  @JsonKey(name: 'scheduled_at')
  final String? scheduledAt;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'class_type_name')
  final String? classTypeName;
  @JsonKey(name: 'instructor_name')
  final String? instructorName;

  Booking({
    required this.id,
    required this.scheduleId,
    required this.userId,
    this.membershipId,
    required this.bookingType,
    required this.bookingStatus,
    required this.bookedAt,
    this.cancelledAt,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userPhone,
    this.scheduledAt,
    this.durationMinutes,
    this.classTypeName,
    this.instructorName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  bool get isActive => bookingStatus == 'confirmed' || bookingStatus == 'waiting';
  bool get isCancelled => bookingStatus == 'cancelled';
  bool get isWaiting => bookingStatus == 'waiting';
  bool get isConfirmed => bookingStatus == 'confirmed';

  DateTime? get scheduleDateTime =>
      scheduledAt != null ? DateTime.parse(scheduledAt!) : null;

  String get statusDisplay {
    switch (bookingStatus) {
      case 'confirmed':
        return '예약 확정';
      case 'waiting':
        return '대기 중';
      case 'cancelled':
        return '취소됨';
      case 'completed':
        return '수업 완료';
      case 'no_show':
        return '노쇼';
      default:
        return bookingStatus;
    }
  }

  String get typeDisplay {
    switch (bookingType) {
      case 'regular':
        return '정기';
      case 'trial':
        return '체험';
      case 'drop_in':
        return '드롭인';
      default:
        return bookingType;
    }
  }
}

@JsonSerializable()
class CreateBookingRequest {
  @JsonKey(name: 'schedule_id')
  final int scheduleId;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'membership_id')
  final int? membershipId;
  @JsonKey(name: 'booking_type')
  final String bookingType;

  CreateBookingRequest({
    required this.scheduleId,
    this.userId,
    this.membershipId,
    this.bookingType = 'regular',
  });

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

@JsonSerializable()
class CancelBookingRequest {
  @JsonKey(name: 'cancel_reason')
  final String? cancelReason;

  CancelBookingRequest({
    this.cancelReason,
  });

  factory CancelBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CancelBookingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CancelBookingRequestToJson(this);
}