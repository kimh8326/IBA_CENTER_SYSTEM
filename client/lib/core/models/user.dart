import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  @JsonKey(name: 'user_type')
  final String userType;
  final String name;
  final String phone;
  final String? email;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_login_at')
  final String? lastLoginAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  
  // Instructor specific fields
  final String? specializations;
  @JsonKey(name: 'experience_years')
  final int? experienceYears;
  final String? certifications;
  @JsonKey(name: 'hourly_rate')
  final double? hourlyRate;
  final String? bio;

  User({
    required this.id,
    required this.userType,
    required this.name,
    required this.phone,
    this.email,
    this.profileImage,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    this.specializations,
    this.experienceYears,
    this.certifications,
    this.hourlyRate,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // SQLite에서 boolean이 정수로 저장되므로 변환 필요
    final Map<String, dynamic> convertedJson = Map<String, dynamic>.from(json);
    if (convertedJson['is_active'] is int) {
      convertedJson['is_active'] = convertedJson['is_active'] == 1;
    }
    
    // null 값들을 적절한 기본값으로 처리
    convertedJson['name'] ??= '';
    convertedJson['phone'] ??= '';
    convertedJson['created_at'] ??= DateTime.now().toIso8601String();
    
    return _$UserFromJson(convertedJson);
  }
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isMaster => userType == 'master';
  bool get isInstructor => userType == 'instructor';
  bool get isMember => userType == 'member';

  String get displayRole {
    switch (userType) {
      case 'master':
        return '관리자';
      case 'instructor':
        return '강사';
      case 'member':
        return '회원';
      default:
        return userType;
    }
  }
  
  DateTime get createdAtDateTime {
    return createdAt != null ? DateTime.parse(createdAt!) : DateTime.now();
  }
}

@JsonSerializable()
class MemberProfile {
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  final String? gender;
  @JsonKey(name: 'emergency_contact')
  final String? emergencyContact;
  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  MemberProfile({
    required this.userId,
    this.birthDate,
    this.gender,
    this.emergencyContact,
    this.medicalNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) =>
      _$MemberProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MemberProfileToJson(this);
}

@JsonSerializable()
class InstructorProfile {
  @JsonKey(name: 'user_id')
  final int userId;
  final String? specialization;
  @JsonKey(name: 'hourly_rate')
  final double? hourlyRate;
  final String? bio;
  final List<String> certifications;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  InstructorProfile({
    required this.userId,
    this.specialization,
    this.hourlyRate,
    this.bio,
    required this.certifications,
    required this.createdAt,
    this.updatedAt,
  });

  factory InstructorProfile.fromJson(Map<String, dynamic> json) =>
      _$InstructorProfileFromJson(json);
  Map<String, dynamic> toJson() => _$InstructorProfileToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({
    required this.phone,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final String token;
  final User user;
  final String message;

  LoginResponse({
    required this.token,
    required this.user,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}