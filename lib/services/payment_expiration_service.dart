import 'package:flutter/foundation.dart';
import 'package:real_galaxy/models/payment.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/paystack_service.dart';
import 'package:real_galaxy/services/fcm_service.dart';
import 'package:real_galaxy/models/player.dart';

class PaymentExpirationService {
  static final PaymentExpirationService _instance =
      PaymentExpirationService._internal();
  factory PaymentExpirationService() => _instance;
  PaymentExpirationService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final PaystackService _paystackService = PaystackService();
  final FCMService _fcmService = FCMService();

  // Payment expiration timeframes (in minutes/hours)
  static const Duration _pendingPaymentExpiration = Duration(minutes: 30);
  static const Duration _verificationTimeout = Duration(hours: 24);

  /// Check for expired payments and update their status
  Future<void> checkAndUpdateExpiredPayments() async {
    try {
      debugPrint('Checking for expired payments...');

      // Get all pending payments
      final allPayments = await _firebaseService.getAllPayments();
      final pendingPayments = allPayments
          .where((p) => p.status == PaymentStatus.pending)
          .toList();

      debugPrint('Found ${pendingPayments.length} pending payments to check');

      for (final payment in pendingPayments) {
        await _checkPaymentExpiration(payment);
      }

      // Check for payments that failed verification
      final failedPayments = allPayments
          .where((p) => p.status == PaymentStatus.failed)
          .toList();
      for (final payment in failedPayments) {
        await _checkFailedPaymentExpiration(payment);
      }
    } catch (e) {
      debugPrint('Error checking expired payments: $e');
    }
  }

  /// Check for upcoming payment due dates (monthly fees)
  Future<void> checkUpcomingPaymentDueDates() async {
    try {
      debugPrint('Checking for upcoming payment due dates...');

      final allPlayers = await _firebaseService.getAllPlayers();
      final now = DateTime.now();

      for (final player in allPlayers) {
        // Calculate next payment due date (30 days after last payment)
        final lastPayment = await _getLastPaymentForPlayer(player.id ?? '');
        if (lastPayment != null) {
          final nextDueDate = lastPayment.paidAt!.add(const Duration(days: 30));
          final daysUntilDue = nextDueDate.difference(now).inDays;

          if (daysUntilDue <= 3 && daysUntilDue > 0) {
            debugPrint('Payment for ${player.name} due in $daysUntilDue days');
            await _sendPaymentReminderNotification(
              player,
              nextDueDate,
              daysUntilDue,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking upcoming payment due dates: $e');
    }
  }

  /// Get the last payment for a player
  Future<Payment?> _getLastPaymentForPlayer(String playerId) async {
    try {
      final allPayments = await _firebaseService.getAllPayments();
      final playerPayments = allPayments
          .where((p) => p.playerId == playerId)
          .toList();
      final paidPayments = playerPayments
          .where((p) => p.status == PaymentStatus.paid && p.paidAt != null)
          .toList();

      if (paidPayments.isEmpty) return null;

      // Return the most recent payment
      paidPayments.sort((a, b) => b.paidAt!.compareTo(a.paidAt!));
      return paidPayments.first;
    } catch (e) {
      debugPrint('Error getting last payment for player $playerId: $e');
      return null;
    }
  }

  /// Send payment reminder notification to parent
  Future<void> _sendPaymentReminderNotification(
    Player player,
    DateTime dueDate,
    int daysUntilDue,
  ) async {
    try {
      if (player.parentId.isEmpty) return;

      final amount = 400.0; // Monthly fee amount
      await _fcmService.sendPaymentReminder(
        userId: player.parentId,
        playerName: player.name ?? 'Unknown Player',
        amount: amount.toStringAsFixed(0),
        dueDate: dueDate,
      );

      debugPrint(
        'Payment reminder sent for ${player.name} - due in $daysUntilDue days',
      );
    } catch (e) {
      debugPrint('Error sending payment reminder for ${player.name}: $e');
    }
  }

  /// Check if a specific payment has expired
  Future<void> _checkPaymentExpiration(Payment payment) async {
    final now = DateTime.now();
    final timeSinceCreation = now.difference(payment.createdAt);

    // Check if pending payment has expired
    if (timeSinceCreation > _pendingPaymentExpiration) {
      debugPrint(
        'Payment ${payment.id} has expired (${timeSinceCreation.inMinutes} minutes old)',
      );

      // Try to verify with Paystack one last time
      if (payment.transactionReference != null) {
        final isValid = await _paystackService.verifyPayment(
          payment.transactionReference!,
          expectedAmount: payment.amount,
        );

        if (isValid) {
          // Payment was actually successful, update status
          await _updatePaymentStatus(
            payment.id!,
            PaymentStatus.paid,
            payment.transactionReference,
          );
          debugPrint(
            'Payment ${payment.id} was actually successful, updating to paid',
          );
        } else {
          // Payment truly expired
          await _updatePaymentStatus(
            payment.id!,
            PaymentStatus.expired,
            payment.transactionReference,
          );
          debugPrint('Payment ${payment.id} marked as expired');
        }
      } else {
        // No transaction reference, mark as expired
        await _updatePaymentStatus(
          payment.id!,
          PaymentStatus.expired,
          payment.transactionReference,
        );
      }
    }
  }

  /// Check if failed payments should be marked as expired
  Future<void> _checkFailedPaymentExpiration(Payment payment) async {
    final now = DateTime.now();
    final timeSinceCreation = now.difference(payment.createdAt);

    // If failed payment is older than verification timeout, mark as expired
    if (timeSinceCreation > _verificationTimeout) {
      debugPrint(
        'Failed payment ${payment.id} expired after ${timeSinceCreation.inHours} hours',
      );
      await _updatePaymentStatus(
        payment.id!,
        PaymentStatus.expired,
        payment.transactionReference,
      );
    }
  }

  /// Update payment status in database
  Future<void> _updatePaymentStatus(
    String paymentId,
    PaymentStatus newStatus,
    String? transactionReference,
  ) async {
    try {
      await _firebaseService.updatePaymentStatus(
        paymentId,
        newStatus,
        transactionReference ?? '',
      );
      debugPrint('Updated payment $paymentId status to $newStatus');
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  /// Get payment expiration info
  Map<String, dynamic> getPaymentExpirationInfo(Payment payment) {
    final now = DateTime.now();
    final timeSinceCreation = now.difference(payment.createdAt);
    final remainingTime = _pendingPaymentExpiration - timeSinceCreation;

    return {
      'isExpired': timeSinceCreation > _pendingPaymentExpiration,
      'timeSinceCreation': timeSinceCreation,
      'remainingTime': remainingTime.isNegative ? Duration.zero : remainingTime,
      'expiresAt': payment.createdAt.add(_pendingPaymentExpiration),
      'minutesRemaining': remainingTime.isNegative
          ? 0
          : remainingTime.inMinutes,
    };
  }

  /// Schedule periodic expiration checks
  void startExpirationMonitoring() {
    debugPrint('Starting payment expiration monitoring...');

    // Check every 10 minutes
    Future.doWhile(() async {
      await checkAndUpdateExpiredPayments();
      await Future.delayed(const Duration(minutes: 10));
      return true; // Continue indefinitely
    });
  }

  /// Get all expired payments for a user
  Future<List<Payment>> getExpiredPaymentsForUser(String userId) async {
    try {
      final allPayments = await _firebaseService.getAllPayments();
      return allPayments
          .where(
            (p) => p.parentId == userId && p.status == PaymentStatus.expired,
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting expired payments: $e');
      return [];
    }
  }

  /// Get payment statistics
  Future<Map<String, int>> getPaymentStatistics() async {
    try {
      final allPayments = await _firebaseService.getAllPayments();

      final stats = <String, int>{
        'pending': 0,
        'paid': 0,
        'failed': 0,
        'expired': 0,
        'refunded': 0,
        'total': allPayments.length,
      };

      for (final payment in allPayments) {
        stats[payment.status.name] = (stats[payment.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting payment statistics: $e');
      return {};
    }
  }
}
