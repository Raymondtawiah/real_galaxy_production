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

class ParentPaymentScreen extends StatefulWidget {
  final String parentId;
  final app_user.User? parentUser;

  const ParentPaymentScreen({
    super.key,
    required this.parentId,
    this.parentUser,
  });

  @override
  State<ParentPaymentScreen> createState() => _ParentPaymentScreenState();
}

class _ParentPaymentScreenState extends State<ParentPaymentScreen>
    with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  final PaystackService _paystackService = PaystackService();

  List<Player> _players = [];
  Player? _selectedPlayer;
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _lastPaymentReference;

  final double _monthlyFee = 400;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPlayers();
    _amountController.text = _monthlyFee.toStringAsFixed(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for payment verification when app resumes
    if (state == AppLifecycleState.resumed && _lastPaymentReference != null) {
      debugPrint(
        'App resumed, checking payment status for: $_lastPaymentReference',
      );
      _verifyPaymentAndSave(_lastPaymentReference!);
      _lastPaymentReference = null; // Clear reference after checking
    }
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final allPlayers = await _firebaseService.getAllPlayers();
      _players = allPlayers
          .where((p) => p.parentId == widget.parentId)
          .toList();
      if (_players.isNotEmpty) {
        _selectedPlayer = _players.first;
      }
    } catch (e) {
      print('Error loading players: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makePayment() async {
    if (_selectedPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a player'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (amount < _monthlyFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum payment is ₵${_monthlyFee.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      debugPrint('=== PAYMENT INITIALIZATION START ===');

      // Validate all required fields
      if (_selectedPlayer == null) {
        debugPrint('ERROR: No player selected');
        throw Exception('No player selected');
      }

      final playerId = _selectedPlayer!.id ?? '';
      final playerName = _selectedPlayer!.name ?? 'Unknown Player';
      final parentEmail = widget.parentUser?.email ?? 'parent@example.com';

      debugPrint('Player ID: $playerId');
      debugPrint('Player Name: $playerName');
      debugPrint('Parent Email: $parentEmail');
      debugPrint('Amount: $amount');

      if (playerId.isEmpty) {
        debugPrint('ERROR: Player ID is missing');
        throw Exception('Player ID is missing');
      }

      if (parentEmail.isEmpty || !parentEmail.contains('@')) {
        debugPrint('ERROR: Invalid email: $parentEmail');
        throw Exception('Valid email is required');
      }

      debugPrint('Calling Paystack API...');

      // Initialize payment with validated metadata
      final paymentResponse = await _paystackService.initializeTransaction(
        email: parentEmail,
        amount: amount,
        reference: 'monthly_fee_${DateTime.now().millisecondsSinceEpoch}',
        callbackUrl: 'realgalaxy://payment',
        metadata: {
          'player_id': playerId,
          'player_name': playerName,
          'parent_id': widget.parentId,
          'payment_type': 'monthly_fee',
          'custom_fields': [
            {
              'display_name': 'Player Name',
              'variable_name': 'player_name',
              'value': playerName,
            },
            {
              'display_name': 'Player Age',
              'variable_name': 'player_age',
              'value': _selectedPlayer!.age.toString(),
            },
            {
              'display_name': 'Payment Type',
              'variable_name': 'payment_type',
              'value': 'Monthly Fee',
            },
          ],
        },
      );

      debugPrint('Paystack Response: $paymentResponse');

      if (paymentResponse['status'] == true) {
        debugPrint('Payment initialization successful, launching browser...');
        final authUrl = paymentResponse['data']['authorization_url'];
        final reference = paymentResponse['data']['reference'];

        debugPrint('Authorization URL: $authUrl');
        debugPrint('Payment Reference: $reference');

        // Store reference for automatic verification when user returns
        _lastPaymentReference = reference;

        // Auto-redirect to browser for payment
        await _launchPaymentUrl(authUrl);
        debugPrint('=== PAYMENT INITIALIZATION SUCCESS ===');
      } else {
        debugPrint(
          'Payment initialization failed: ${paymentResponse['message']}',
        );
        throw Exception(
          'Payment initialization failed: ${paymentResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== PAYMENT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentDialog(String paymentUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please complete your payment in the browser.'),
            const SizedBox(height: 16),
            Text('Amount: ₵${_amountController.text}'),
            Text('Player: ${_selectedPlayer?.name ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchPaymentUrl(paymentUrl);
            },
            child: const Text('Pay Now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      debugPrint('Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        debugPrint('URL can be launched, launching...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('URL launched successfully');
        } else {
          debugPrint('Failed to launch URL');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to launch payment URL'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        debugPrint('Cannot launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch payment URL: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching payment URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyPaymentAndSave(String reference) async {
    try {
      setState(() => _isProcessing = true);

      // Verify payment with Paystack
      final isVerified = await _paystackService.verifyPayment(
        reference,
        expectedAmount: _monthlyFee,
      );

      if (isVerified) {
        // Save payment record to Firebase
        final payment = await _savePaymentRecord(reference);

        // Generate receipt
        await _generateReceipt(payment);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful! Monthly fee paid for ${_selectedPlayer!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment verification failed. Please contact support.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Payment> _savePaymentRecord(String reference) async {
    if (_selectedPlayer == null) {
      throw Exception('No player selected for payment record');
    }

    final payment = Payment(
      parentId: widget.parentId,
      playerId: _selectedPlayer!.id ?? '',
      amount: _monthlyFee,
      paymentType: PaymentType.monthlyFee,
      status: PaymentStatus.paid,
      transactionReference: reference,
      paidAt: DateTime.now(),
    );

    final paymentId = await _firebaseService.createPayment(payment);
    debugPrint('Payment record saved with ID: $paymentId');

    return payment;
  }

  Future<void> _generateReceipt(Payment payment) async {
    try {
      debugPrint(
        'Generating receipt for payment: ${payment.transactionReference}',
      );

      // Create receipt object
      final receipt = Receipt(
        paymentId: payment.transactionReference ?? '',
        parentId: payment.parentId,
        playerId: payment.playerId,
        amount: payment.amount,
        currency: payment.currency,
        date: payment.paidAt ?? DateTime.now(),
        paymentMethod: payment.paymentMethod,
        playerName: _selectedPlayer?.name,
        parentName: widget.parentUser?.name,
      );

      // Save receipt to Firebase
      await _firebaseService.createReceipt(receipt);
      debugPrint(
        'Receipt generated successfully for payment: ${receipt.paymentId}',
      );
    } catch (e) {
      debugPrint('Error generating receipt: $e');
      // Don't show error to user as payment was successful, just log it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pay Monthly Fee'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Fee Payment',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onBackgroundColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pay ₵${_monthlyFee.toStringAsFixed(0)} per month for your child\'s football training',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Player Selection
                  if (_players.isNotEmpty) ...[
                    const Text(
                      'Select Player',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Player>(
                      initialValue: _selectedPlayer,
                      dropdownColor: AppTheme.surfaceVariantColor,
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                      decoration: InputDecoration(
                        labelText: 'Choose Player',
                        labelStyle: const TextStyle(
                          color: AppTheme.onBackgroundMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _players.map((player) {
                        return DropdownMenuItem<Player>(
                          value: player,
                          child: Text('${player.name} (${player.age} years)'),
                        );
                      }).toList(),
                      onChanged: (player) {
                        setState(() => _selectedPlayer = player);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Amount Input
                  const Text(
                    'Payment Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₵)',
                      labelStyle: const TextStyle(
                        color: AppTheme.onBackgroundMuted,
                      ),
                      prefixText: '₵',
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimum amount: ₵${_monthlyFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.onBackgroundFaint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _makePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : const Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Payments are processed securely through Paystack',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        const Text(
                          '• You will receive a receipt after successful payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        const Text(
                          '• Return to app after payment to verify automatically',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () async {
                                    // For manual verification - user can enter reference
                                    final controller = TextEditingController();
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Verify Payment'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            labelText: 'Payment Reference',
                                            hintText:
                                                'Enter reference from payment confirmation',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              if (controller.text.isNotEmpty) {
                                                _verifyPaymentAndSave(
                                                  controller.text.trim(),
                                                );
                                              }
                                            },
                                            child: const Text('Verify'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Verify Manual Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
