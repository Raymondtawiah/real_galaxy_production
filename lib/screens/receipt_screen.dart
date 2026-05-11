import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/receipt.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatefulWidget {
  final String parentId;

  const ReceiptScreen({super.key, required this.parentId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    // Check if user is authenticated before proceeding
    final authService = AuthService();
    final currentUser = await authService.getCurrentUserProfile();
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Please sign in to view receipts', Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final allReceipts = await _firebaseService.getAllReceipts();
      _receipts = allReceipts
          .where((r) => r.parentId == widget.parentId)
          .toList();
      _receipts.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading receipts: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showReceiptDetail(Receipt receipt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PAYMENT RECEIPT',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.onBackgroundMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.outlineColor),
              const SizedBox(height: 16),
              _buildReceiptRow(
                'Receipt ID',
                receipt.id?.substring(0, 8) ?? 'N/A',
              ),
              _buildReceiptRow(
                'Date',
                DateFormat('MMMM dd, yyyy').format(receipt.date),
              ),
              _buildReceiptRow('Player', receipt.playerName ?? 'N/A'),
              _buildReceiptRow(
                'Payment Method',
                receipt.paymentMethod.toUpperCase(),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.outlineColor),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL PAID',
                    style: TextStyle(color: AppTheme.onBackgroundMuted, fontSize: 14),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₵',
                      decimalDigits: 0,
                    ).format(receipt.amount),
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.outlineColor),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Payment Verified',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Thank you for your payment!',
                  style: TextStyle(color: AppTheme.onBackgroundSubtle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.onBackgroundSubtle)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.onBackgroundColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Receipts'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _receipts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppTheme.onBackgroundFaint),
                  SizedBox(height: 16),
                  Text(
                    'No receipts yet',
                    style: TextStyle(color: AppTheme.onBackgroundSubtle, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete a payment to receive a receipt',
                    style: TextStyle(color: AppTheme.onBackgroundFaint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _receipts.length,
              itemBuilder: (context, index) {
                final receipt = _receipts[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.successColor.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.receipt,
                        color: AppTheme.successColor,
                      ),
                    ),
                    title: Text(
                      receipt.playerName ?? 'Payment',
                      style: const TextStyle(
                        color: AppTheme.onBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(receipt.date),
                      style: const TextStyle(color: AppTheme.onBackgroundSubtle),
                    ),
                    trailing: Text(
                      NumberFormat.currency(
                        symbol: '₵',
                        decimalDigits: 0,
                      ).format(receipt.amount),
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => _showReceiptDetail(receipt),
                  ),
                );
              },
            ),
    );
  }
}

