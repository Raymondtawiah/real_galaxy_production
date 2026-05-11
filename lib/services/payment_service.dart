import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/payment.dart';
import 'base_service.dart';

abstract class PaymentService {
  Future<String> createPayment(Payment payment);
  Future<List<Payment>> getAllPayments();
  Future<List<Payment>> getPaymentsByParent(String parentId);
  Future<List<Payment>> getPaymentsByPlayer(String playerId);
  Future<Payment?> getPaymentByReference(String reference);
  Future<void> updatePaymentStatus(
    String paymentId,
    String status,
    String? reference,
  );
  Future<void> updatePayment(String paymentId, Payment payment);
}

class PaymentServiceImpl extends PaymentService {
  final DatabaseReference _ref = dbRef.payments();

  @override
  Future<String> createPayment(Payment payment) async {
    final newRef = _ref.push();
    await newRef.set(payment.toMap());
    return newRef.key ?? '';
  }

  @override
  Future<List<Payment>> getAllPayments() async {
    final payments = <Payment>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          payments.add(Payment.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting payments: $e');
    }
    return payments;
  }

  @override
  Future<List<Payment>> getPaymentsByParent(String parentId) async {
    final payments = <Payment>[];
    try {
      final snapshot = await _ref
          .orderByChild('parent_id')
          .equalTo(parentId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          payments.add(Payment.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting payments by parent: $e');
    }
    return payments;
  }

  @override
  Future<List<Payment>> getPaymentsByPlayer(String playerId) async {
    final payments = <Payment>[];
    try {
      final snapshot = await _ref
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          payments.add(Payment.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting payments by player: $e');
    }
    return payments;
  }

  @override
  Future<Payment?> getPaymentByReference(String reference) async {
    try {
      final snapshot = await _ref
          .orderByChild('transaction_reference')
          .equalTo(reference)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          return Payment.fromMap(child.key ?? '', data);
        }
      }
    } catch (e) {
      print('Error getting payment by reference: $e');
    }
    return null;
  }

  @override
  Future<void> updatePaymentStatus(
    String paymentId,
    String status,
    String? reference,
  ) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (reference != null) {
      data['transaction_reference'] = reference;
    }
    await _ref.child(paymentId).update(data);
  }

  @override
  Future<void> updatePayment(String paymentId, Payment payment) async {
    final data = payment.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _ref.child(paymentId).update(data);
  }
}

