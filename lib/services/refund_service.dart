import 'package:firebase_database/firebase_database.dart';
import '../models/refund.dart';
import '../models/payment.dart';
import 'base_service.dart';
import 'payment_service.dart';

class RefundService {
  final DatabaseReference _ref = dbRef.refunds();
  final PaymentServiceImpl _paymentService = PaymentServiceImpl();
  Future<String> createRefundRequest(Refund refund) async {
    final newRef = _ref.push();
    await newRef.set(refund.toMap());
    return newRef.key ?? '';
  }

  Future<List<Refund>> getAllRefunds() async {
    final refunds = <Refund>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          refunds.add(Refund.fromMap(child.key ?? '', data));
        }
      }
      refunds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error getting refunds: $e');
    }
    return refunds;
  }

  Future<List<Refund>> getRefundsByStatus(RefundStatus status) async {
    final refunds = <Refund>[];
    try {
      final snapshot = await _ref
          .orderByChild('status')
          .equalTo(status.name)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          refunds.add(Refund.fromMap(child.key ?? '', data));
        }
      }
      refunds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error getting refunds by status: $e');
    }
    return refunds;
  }

  Future<List<Refund>> getRefundsByParent(String parentId) async {
    final refunds = <Refund>[];
    try {
      final snapshot = await _ref
          .orderByChild('parent_id')
          .equalTo(parentId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          refunds.add(Refund.fromMap(child.key ?? '', data));
        }
      }
      refunds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error getting refunds by parent: $e');
    }
    return refunds;
  }

  Future<Refund?> getRefund(String refundId) async {
    try {
      final snapshot = await _ref.child(refundId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Refund.fromMap(refundId, data);
      }
    } catch (e) {
      print('Error getting refund: $e');
    }
    return null;
  }

  Future<bool> processRefund(
    String refundId,
    bool approved,
    String processedBy,
  ) async {
    try {
      final refund = await getRefund(refundId);
      if (refund == null) return false;

      final updatedRefund = refund.copyWith(
        status: approved ? RefundStatus.approved : RefundStatus.rejected,
        processedBy: processedBy,
        processedAt: DateTime.now(),
      );

      await _ref.child(refundId).update(updatedRefund.toMap());

      if (approved) {
        final paymentService = PaymentServiceImpl();
        await paymentService.updatePaymentStatus(
          refund.paymentId,
          PaymentStatus.refunded.name,
          null,
        );
      }

      return true;
    } catch (e) {
      print('Error processing refund: $e');
      return false;
    }
  }

  Future<void> deleteRefund(String refundId) async {
    await _ref.child(refundId).remove();
  }
}

