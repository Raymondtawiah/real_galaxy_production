enum RefundStatus { pending, approved, rejected }

class Refund {
  final String? id;
  final String paymentId;
  final String parentId;
  final double amount;
  final String reason;
  final RefundStatus status;
  final String? processedBy;
  final DateTime createdAt;
  final DateTime? processedAt;

  Refund({
    this.id,
    required this.paymentId,
    required this.parentId,
    required this.amount,
    required this.reason,
    this.status = RefundStatus.pending,
    this.processedBy,
    DateTime? createdAt,
    this.processedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'parent_id': parentId,
      'amount': amount,
      'reason': reason,
      'status': status.name,
      'processed_by': processedBy,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  factory Refund.fromMap(String id, Map<String, dynamic> map) {
    return Refund(
      id: id,
      paymentId: map['payment_id'] ?? '',
      parentId: map['parent_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      status: RefundStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => RefundStatus.pending,
      ),
      processedBy: map['processed_by'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      processedAt: map['processed_at'] != null
          ? DateTime.tryParse(map['processed_at'])
          : null,
    );
  }

  Refund copyWith({
    RefundStatus? status,
    String? processedBy,
    DateTime? processedAt,
  }) {
    return Refund(
      id: id,
      paymentId: paymentId,
      parentId: parentId,
      amount: amount,
      reason: reason,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

