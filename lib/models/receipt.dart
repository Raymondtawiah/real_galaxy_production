class Receipt {
  final String? id;
  final String paymentId;
  final String parentId;
  final String playerId;
  final double amount;
  final String currency;
  final DateTime date;
  final String paymentMethod;
  final String? playerName;
  final String? parentName;
  final DateTime createdAt;

  Receipt({
    this.id,
    required this.paymentId,
    required this.parentId,
    required this.playerId,
    required this.amount,
    this.currency = 'GHS',
    required this.date,
    this.paymentMethod = 'paystack',
    this.playerName,
    this.parentName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'parent_id': parentId,
      'player_id': playerId,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'player_name': playerName,
      'parent_name': parentName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(String id, Map<String, dynamic> map) {
    return Receipt(
      id: id,
      paymentId: map['payment_id'] ?? '',
      parentId: map['parent_id'] ?? '',
      playerId: map['player_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'NGN',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      paymentMethod: map['payment_method'] ?? 'paystack',
      playerName: map['player_name'],
      parentName: map['parent_name'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get receiptNumber {
    return 'RG-${DateTime.now().year}-${id ?? '0000'}';
  }
}

