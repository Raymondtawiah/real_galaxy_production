enum PaymentType { registration, monthlyFee, trial }

enum PaymentStatus { pending, paid, failed, refunded, expired }

class Payment {
  final String? id;
  final String parentId;
  final String playerId;
  final double amount;
  final String currency;
  final PaymentType paymentType;
  final String paymentMethod;
  final PaymentStatus status;
  final String? transactionReference;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    this.id,
    required this.parentId,
    required this.playerId,
    required this.amount,
    this.currency = 'GHS',
    required this.paymentType,
    this.paymentMethod = 'paystack',
    this.status = PaymentStatus.pending,
    this.transactionReference,
    this.paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'parent_id': parentId,
      'player_id': playerId,
      'amount': amount,
      'currency': currency,
      'payment_type': paymentType.name,
      'payment_method': paymentMethod,
      'status': status.name,
      'transaction_reference': transactionReference,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      parentId: map['parent_id'] ?? '',
      playerId: map['player_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'GHS',
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == (map['payment_type'] ?? 'monthlyFee'),
        orElse: () => PaymentType.monthlyFee,
      ),
      paymentMethod: map['payment_method'] ?? 'paystack',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      transactionReference: map['transaction_reference'],
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at']) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Payment copyWith({
    String? parentId,
    String? playerId,
    double? amount,
    String? currency,
    PaymentType? paymentType,
    String? paymentMethod,
    PaymentStatus? status,
    String? transactionReference,
    DateTime? paidAt,
  }) {
    return Payment(
      id: id,
      parentId: parentId ?? this.parentId,
      playerId: playerId ?? this.playerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get paymentTypeDisplay {
    switch (paymentType) {
      case PaymentType.registration:
        return 'Registration Fee';
      case PaymentType.monthlyFee:
        return 'Monthly Fee';
      case PaymentType.trial:
        return 'Trial Fee';
    }
  }

  String get statusDisplay {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.expired:
        return 'Expired';
    }
  }
}
