class MembershipTemplate {
  final int id;
  final String name;
  final String? description;
  final int? classTypeId;
  final String? classTypeName;
  final String? classTypeColor;
  final int totalSessions;
  final int validityDays;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  // final DateTime? updatedAt; // 스키마에 없는 컬럼이므로 제거
  final int? activeMemberships;

  MembershipTemplate({
    required this.id,
    required this.name,
    this.description,
    this.classTypeId,
    this.classTypeName,
    this.classTypeColor,
    required this.totalSessions,
    required this.validityDays,
    required this.price,
    required this.isActive,
    required this.createdAt,
    this.activeMemberships,
  });

  factory MembershipTemplate.fromJson(Map<String, dynamic> json) {
    return MembershipTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      classTypeId: json['class_type_id'],
      classTypeName: json['class_type_name'],
      classTypeColor: json['class_type_color'],
      totalSessions: json['total_sessions'],
      validityDays: json['validity_days'],
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      activeMemberships: json['active_memberships'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'class_type_id': classTypeId,
      'class_type_name': classTypeName,
      'class_type_color': classTypeColor,
      'total_sessions': totalSessions,
      'validity_days': validityDays,
      'price': price,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'active_memberships': activeMemberships,
    };
  }

  String get validityText {
    if (validityDays >= 365) {
      final years = (validityDays / 365).floor();
      final remainingDays = validityDays % 365;
      if (remainingDays == 0) {
        return '${years}년';
      } else {
        return '${years}년 $remainingDays일';
      }
    } else if (validityDays >= 30) {
      final months = (validityDays / 30).floor();
      final remainingDays = validityDays % 30;
      if (remainingDays == 0) {
        return '${months}개월';
      } else {
        return '${months}개월 $remainingDays일';
      }
    } else {
      return '$validityDays일';
    }
  }

  String get priceText {
    return '${price.toStringAsFixed(0)}원';
  }

  String get sessionsText {
    return '${totalSessions}회';
  }
}