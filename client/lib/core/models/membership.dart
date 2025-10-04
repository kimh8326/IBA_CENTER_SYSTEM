class Membership {
  final int id;
  final int userId;
  final int templateId;
  final int remainingSessions;
  final String startDate;
  final String endDate;
  final double purchasePrice;
  final String status;
  final String purchasedAt;
  
  // Template 정보 (조인된 데이터)
  final String? templateName;
  final int? totalSessions;
  final int? validityDays;
  final double? templatePrice;

  const Membership({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.remainingSessions,
    required this.startDate,
    required this.endDate,
    required this.purchasePrice,
    required this.status,
    required this.purchasedAt,
    this.templateName,
    this.totalSessions,
    this.validityDays,
    this.templatePrice,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0, // user_id가 없을 경우 0으로 기본값 설정
      templateId: json['template_id'] as int,
      remainingSessions: json['remaining_sessions'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      status: json['status'] as String,
      purchasedAt: json['purchased_at'] as String,
      templateName: json['template_name'] as String?,
      totalSessions: json['total_sessions'] as int?,
      validityDays: json['validity_days'] as int?,
      templatePrice: json['template_price'] != null 
          ? (json['template_price'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'remaining_sessions': remainingSessions,
      'start_date': startDate,
      'end_date': endDate,
      'purchase_price': purchasePrice,
      'status': status,
      'purchased_at': purchasedAt,
      'template_name': templateName,
      'total_sessions': totalSessions,
      'validity_days': validityDays,
      'template_price': templatePrice,
    };
  }

  // 상태 표시용 메서드들
  String get statusText {
    switch (status) {
      case 'active':
        return '활성';
      case 'expired':
        return '만료';
      case 'suspended':
        return '일시정지';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';

  // 남은 일수 계산
  int get remainingDays {
    try {
      final endDateTime = DateTime.parse(endDate);
      final now = DateTime.now();
      final difference = endDateTime.difference(now);
      return difference.inDays > 0 ? difference.inDays : 0;
    } catch (e) {
      return 0;
    }
  }

  // 진행률 계산 (0.0 ~ 1.0)
  double get usageProgress {
    if (totalSessions == null || totalSessions == 0) return 0.0;
    final usedSessions = totalSessions! - remainingSessions;
    return usedSessions / totalSessions!;
  }

  @override
  String toString() {
    return 'Membership(id: $id, templateName: $templateName, remainingSessions: $remainingSessions, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Membership && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}