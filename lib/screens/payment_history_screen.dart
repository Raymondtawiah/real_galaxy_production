import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/payment.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String parentId;

  const PaymentHistoryScreen({super.key, required this.parentId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    // Check if user is authenticated before proceeding
    final authService = AuthService();
    final currentUser = await authService.getCurrentUserProfile();
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Please sign in to view payment history', Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Load all payments and filter by parentId (fallback if index doesn't exist)
      final allPayments = await _firebaseService.getAllPayments();
      _payments = allPayments
          .where((p) => p.parentId == widget.parentId)
          .toList();
      _payments.sort((a, b) {
        final aDate = a.paidAt ?? a.createdAt;
        final bDate = b.paidAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      debugPrint(
        'Loaded ${_payments.length} payments for parent ${widget.parentId}',
      );
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.onBackgroundFaint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No payments yet',
                    style: TextStyle(
                      color: AppTheme.onBackgroundSubtle,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make a payment to see it here',
                    style: TextStyle(color: AppTheme.onBackgroundFaint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              payment.paymentTypeDisplay,
                              style: const TextStyle(
                                color: AppTheme.onBackgroundColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  payment.status,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(payment.status),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    color: AppTheme.onBackgroundSubtle,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    symbol: '₵',
                                    decimalDigits: 0,
                                  ).format(payment.amount),
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    color: AppTheme.onBackgroundSubtle,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(payment.paidAt ?? payment.createdAt),
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (payment.transactionReference != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Ref: ${payment.transactionReference}',
                            style: const TextStyle(
                              color: AppTheme.onBackgroundFaint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
