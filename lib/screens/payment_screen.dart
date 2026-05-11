import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/payment.dart';
import 'package:real_galaxy/models/receipt.dart';
import 'package:real_galaxy/models/user.dart' as app_user;
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/paystack_service.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String parentId;
  final app_user.User? parentUser;

  const PaymentScreen({super.key, required this.parentId, this.parentUser});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PaystackService _paystackService = PaystackService();

  List<Player> _players = [];
  Player? _selectedPlayer;
  PaymentType _selectedPaymentType = PaymentType.monthlyFee;
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isProcessing = false;

  final double _registrationFee = 500;
  final double _monthlyFee = 400;
  final double _trialFee = 200;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final allPlayers = await _firebaseService.getAllPlayers();
      _players = allPlayers
          .where((p) => p.parentId == widget.parentId)
          .toList();
    } catch (e) {
      debugPrint('Error loading players: $e');
    }
    setState(() => _isLoading = false);
  }

  void _updateAmount() {
    switch (_selectedPaymentType) {
      case PaymentType.registration:
        _amountController.text = _registrationFee.toStringAsFixed(0);
        break;
      case PaymentType.monthlyFee:
        _amountController.text = _monthlyFee.toStringAsFixed(0);
        break;
      case PaymentType.trial:
        _amountController.text = _trialFee.toStringAsFixed(0);
        break;
    }
  }

  Future<void> _processPayment() async {
    // Check if user is authenticated before proceeding
    final authService = AuthService();
    final currentUser = await authService.getCurrentUserProfile();
    if (currentUser == null) {
      _showMessage('Please sign in to make payments', Colors.red);
      return;
    }

    if (_selectedPlayer == null) {
      _showMessage('Please select a child', Colors.red);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount', Colors.red);
      return;
    }

    final expectedAmount = switch (_selectedPaymentType) {
      PaymentType.registration => _registrationFee,
      PaymentType.monthlyFee => _monthlyFee,
      PaymentType.trial => _trialFee,
    };

    if (amount < expectedAmount) {
      _showMessage(
        'Amount must be at least ₵${expectedAmount.toInt()} for ${_selectedPaymentType.name}',
        Colors.red,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final reference = _paystackService.generateReference();

      final payment = Payment(
        parentId: widget.parentId,
        playerId: _selectedPlayer!.id!,
        amount: amount,
        paymentType: _selectedPaymentType,
        status: PaymentStatus.pending,
      );
      final paymentId = await _firebaseService.createPayment(payment);

      final email = widget.parentUser?.email ?? 'parent@realgalaxy.com';

      final result = await _paystackService.initializeTransaction(
        email: email,
        amount: amount,
        reference: reference,
        callbackUrl: PaystackService().callbackUrl,
      );

      debugPrint('Paystack result: $result');

      if (result['status'] == true && result['data'] != null) {
        final authorizationUrl = result['data']['authorization_url'];

        if (!mounted) return;

        final confirm = await _showPaymentDialog();

        if (confirm == true) {
          final uri = Uri.parse(authorizationUrl);
          debugPrint('Authorization URL: $authorizationUrl');

          bool canLaunch = await canLaunchUrl(uri);
          debugPrint('Can launch URL: $canLaunch');

          if (canLaunch) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);

            if (!mounted) return;

            // Ask user if they completed payment
            final checkPayment = await _showCheckPaymentDialog();

            if (checkPayment == true) {
              final verified = await _paystackService.verifyPayment(
                reference,
                expectedAmount: amount,
              );
              debugPrint('Verification result: $verified');

              if (verified) {
                await _firebaseService.updatePaymentStatus(
                  paymentId,
                  PaymentStatus.paid,
                  reference,
                );

                await _firebaseService.updatePlayerPaymentAmounts(
                  _selectedPlayer!.id!,
                  amount,
                );

                // Create enrollment after successful payment
                final enrollments = await _firebaseService
                    .getEnrollmentsByPlayer(_selectedPlayer!.id!);
                for (var enrollment in enrollments) {
                  if (enrollment.status == 'pending') {
                    await _firebaseService.updateEnrollment(
                      enrollment.id!,
                      enrollment.copyWith(
                        status: 'active',
                        paymentVerifiedAt: DateTime.now(),
                      ),
                    );
                  }
                }

                final receipt = Receipt(
                  paymentId: paymentId,
                  parentId: widget.parentId,
                  playerId: _selectedPlayer!.id!,
                  amount: amount,
                  date: DateTime.now(),
                  playerName: _selectedPlayer!.name,
                  parentName: widget.parentUser?.name,
                );
                await _firebaseService.createReceipt(receipt);

                _showMessage('Payment successful!', AppTheme.successColor);
              } else {
                await _firebaseService.updatePaymentStatus(
                  paymentId,
                  PaymentStatus.failed,
                  reference,
                );
                _showMessage(
                  'Payment verification failed. Check your payment history.',
                  AppTheme.primaryColor,
                );
              }
            } else {
              _showMessage(
                'Payment saved as pending. Check history after payment completes.',
                AppTheme.primaryColor,
              );
            }
          } else {
            _showMessage('Could not open payment page', Colors.red);
          }
        } else {
          await _firebaseService.updatePaymentStatus(
            paymentId,
            PaymentStatus.failed,
            reference,
          );
          _showMessage('Payment cancelled', Colors.orange);
        }
      } else {
        final message = result['message'] ?? 'Failed to initialize payment';
        _showMessage('Payment error: $message', Colors.red);
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      _showMessage('Payment error: $e', Colors.red);
    }

    setState(() => _isProcessing = false);
  }

  Future<bool?> _showPaymentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You will be redirected to Paystack to complete your payment.',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
            SizedBox(height: 16),
            Text(
              'After completing payment, return to this app.',
              style: TextStyle(
                color: AppTheme.onBackgroundSubtle,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue to Pay'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCheckPaymentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Payment Status',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Have you completed the payment on Paystack?',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
            SizedBox(height: 12),
            Text(
              'If you completed the payment, click "Yes" to verify.',
              style: TextStyle(
                color: AppTheme.onBackgroundSubtle,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Not Yet',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Verify Payment'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Child',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_players.isEmpty)
                    const Text(
                      'No children registered',
                      style: TextStyle(color: AppTheme.onBackgroundSubtle),
                    )
                  else
                    DropdownButtonFormField<Player>(
                      initialValue: _selectedPlayer,
                      dropdownColor: AppTheme.surfaceVariantColor,
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                      decoration: const InputDecoration(
                        labelText: 'Child',
                        labelStyle: TextStyle(
                          color: AppTheme.onBackgroundMuted,
                        ),
                      ),
                      items: _players
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (player) =>
                          setState(() => _selectedPlayer = player),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Type',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PaymentType>(
                    initialValue: _selectedPaymentType,
                    dropdownColor: AppTheme.surfaceVariantColor,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PaymentType.registration,
                        child: Text('Registration Fee'),
                      ),
                      DropdownMenuItem(
                        value: PaymentType.monthlyFee,
                        child: Text('Monthly Fee'),
                      ),
                      DropdownMenuItem(
                        value: PaymentType.trial,
                        child: Text('Trial Fee'),
                      ),
                    ],
                    onChanged: (type) {
                      setState(() {
                        _selectedPaymentType = type!;
                        _updateAmount();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Amount (GHS)',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                      prefixText: '₵ ',
                      prefixStyle: TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${NumberFormat.currency(symbol: '₵').format(_registrationFee)} registration, ${NumberFormat.currency(symbol: '₵').format(_monthlyFee)} monthly, ${NumberFormat.currency(symbol: '₵').format(_trialFee)} trial',
                    style: const TextStyle(
                      color: AppTheme.onBackgroundFaint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.onBackgroundColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Pay Now',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
