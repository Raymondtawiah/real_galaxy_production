enum PlayerPaymentStatus { upToDate, pending, overdue }

class PlayerPaymentStatusModel {
  final String? id;
  final String playerId;
  final double totalPaid;
  final double totalDue;
  final DateTime? lastPaymentDate;
  final PlayerPaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerPaymentStatusModel({
    this.id,
    required this.playerId,
    this.totalPaid = 0,
    this.totalDue = 0,
    this.lastPaymentDate,
    this.paymentStatus = PlayerPaymentStatus.upToDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'total_paid': totalPaid,
      'total_due': totalDue,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'payment_status': paymentStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PlayerPaymentStatusModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PlayerPaymentStatusModel(
      id: id,
      playerId: map['player_id'] ?? '',
      totalPaid: (map['total_paid'] ?? 0).toDouble(),
      totalDue: (map['total_due'] ?? 0).toDouble(),
      lastPaymentDate: map['last_payment_date'] != null
          ? DateTime.tryParse(map['last_payment_date'])
          : null,
      paymentStatus: PlayerPaymentStatus.values.firstWhere(
        (e) => e.name == (map['payment_status'] ?? 'upToDate'),
        orElse: () => PlayerPaymentStatus.upToDate,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PlayerPaymentStatusModel copyWith({
    String? playerId,
    double? totalPaid,
    double? totalDue,
    DateTime? lastPaymentDate,
    PlayerPaymentStatus? paymentStatus,
  }) {
    return PlayerPaymentStatusModel(
      id: id,
      playerId: playerId ?? this.playerId,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDue: totalDue ?? this.totalDue,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PlayerPaymentStatus.upToDate:
        return 'Up to date';
      case PlayerPaymentStatus.pending:
        return 'Pending';
      case PlayerPaymentStatus.overdue:
        return 'Overdue';
    }
  }
}

