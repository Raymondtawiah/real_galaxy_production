class Enrollment {
  final String? id;
  final String playerId;
  final String trainingSessionId;
  final String parentId;
  final String? paymentId;
  final String status; // 'active', 'cancelled', 'pending'
  final DateTime enrollmentDate;
  final DateTime? paymentVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Enrollment({
    this.id,
    required this.playerId,
    required this.trainingSessionId,
    required this.parentId,
    this.paymentId,
    this.status = 'active',
    DateTime? enrollmentDate,
    this.paymentVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : enrollmentDate = enrollmentDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'training_session_id': trainingSessionId,
      'parent_id': parentId,
      'payment_id': paymentId,
      'status': status,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'payment_verified_at': paymentVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Enrollment.fromMap(String id, Map<dynamic, dynamic> map) {
    return Enrollment(
      id: id,
      playerId: map['player_id'] ?? '',
      trainingSessionId: map['training_session_id'] ?? '',
      parentId: map['parent_id'] ?? '',
      paymentId: map['payment_id'],
      status: map['status'] ?? 'active',
      enrollmentDate: map['enrollment_date'] != null
          ? DateTime.tryParse(map['enrollment_date']) ?? DateTime.now()
          : DateTime.now(),
      paymentVerifiedAt: map['payment_verified_at'] != null
          ? DateTime.tryParse(map['payment_verified_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Enrollment copyWith({
    String? playerId,
    String? trainingSessionId,
    String? parentId,
    String? paymentId,
    String? status,
    DateTime? enrollmentDate,
    DateTime? paymentVerifiedAt,
    DateTime? updatedAt,
  }) {
    return Enrollment(
      id: id,
      playerId: playerId ?? this.playerId,
      trainingSessionId: trainingSessionId ?? this.trainingSessionId,
      parentId: parentId ?? this.parentId,
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

