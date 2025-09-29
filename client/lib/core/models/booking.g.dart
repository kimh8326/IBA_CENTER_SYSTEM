// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: (json['id'] as num).toInt(),
  scheduleId: (json['schedule_id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  membershipId: (json['membership_id'] as num?)?.toInt(),
  bookingType: json['booking_type'] as String,
  bookingStatus: json['booking_status'] as String,
  bookedAt: json['booked_at'] as String,
  cancelledAt: json['cancelled_at'] as String?,
  cancelReason: json['cancel_reason'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
  userName: json['user_name'] as String?,
  userPhone: json['user_phone'] as String?,
  scheduledAt: json['scheduled_at'] as String?,
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  classTypeName: json['class_type_name'] as String?,
  instructorName: json['instructor_name'] as String?,
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'schedule_id': instance.scheduleId,
  'user_id': instance.userId,
  'membership_id': instance.membershipId,
  'booking_type': instance.bookingType,
  'booking_status': instance.bookingStatus,
  'booked_at': instance.bookedAt,
  'cancelled_at': instance.cancelledAt,
  'cancel_reason': instance.cancelReason,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'user_name': instance.userName,
  'user_phone': instance.userPhone,
  'scheduled_at': instance.scheduledAt,
  'duration_minutes': instance.durationMinutes,
  'class_type_name': instance.classTypeName,
  'instructor_name': instance.instructorName,
};

CreateBookingRequest _$CreateBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateBookingRequest(
  scheduleId: (json['schedule_id'] as num).toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  membershipId: (json['membership_id'] as num?)?.toInt(),
  bookingType: json['booking_type'] as String? ?? 'regular',
);

Map<String, dynamic> _$CreateBookingRequestToJson(
  CreateBookingRequest instance,
) => <String, dynamic>{
  'schedule_id': instance.scheduleId,
  'user_id': instance.userId,
  'membership_id': instance.membershipId,
  'booking_type': instance.bookingType,
};

CancelBookingRequest _$CancelBookingRequestFromJson(
  Map<String, dynamic> json,
) => CancelBookingRequest(cancelReason: json['cancel_reason'] as String?);

Map<String, dynamic> _$CancelBookingRequestToJson(
  CancelBookingRequest instance,
) => <String, dynamic>{'cancel_reason': instance.cancelReason};
