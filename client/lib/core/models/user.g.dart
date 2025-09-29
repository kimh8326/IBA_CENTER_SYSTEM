// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  userType: json['user_type'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  profileImage: json['profile_image'] as String?,
  isActive: json['is_active'] as bool,
  lastLoginAt: json['last_login_at'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  specializations: json['specializations'] as String?,
  experienceYears: (json['experience_years'] as num?)?.toInt(),
  certifications: json['certifications'] as String?,
  hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'user_type': instance.userType,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'profile_image': instance.profileImage,
  'is_active': instance.isActive,
  'last_login_at': instance.lastLoginAt,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'specializations': instance.specializations,
  'experience_years': instance.experienceYears,
  'certifications': instance.certifications,
  'hourly_rate': instance.hourlyRate,
  'bio': instance.bio,
};

MemberProfile _$MemberProfileFromJson(Map<String, dynamic> json) =>
    MemberProfile(
      userId: (json['user_id'] as num).toInt(),
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$MemberProfileToJson(MemberProfile instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'birth_date': instance.birthDate,
      'gender': instance.gender,
      'emergency_contact': instance.emergencyContact,
      'medical_notes': instance.medicalNotes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

InstructorProfile _$InstructorProfileFromJson(Map<String, dynamic> json) =>
    InstructorProfile(
      userId: (json['user_id'] as num).toInt(),
      specialization: json['specialization'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      certifications: (json['certifications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$InstructorProfileToJson(InstructorProfile instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'specialization': instance.specialization,
      'hourly_rate': instance.hourlyRate,
      'bio': instance.bio,
      'certifications': instance.certifications,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  phone: json['phone'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'phone': instance.phone, 'password': instance.password};

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
      'message': instance.message,
    };
