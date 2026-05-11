import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/refund.dart';
import 'package:real_galaxy/services/refund_service.dart';
import 'package:real_galaxy/services/permission_service.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:intl/intl.dart';

class RefundsScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const RefundsScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  final RefundService _refundService = RefundService();
  List<Refund> _refunds = [];
  bool _isLoading = true;

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _loadRefunds() async {
    // Check if user is authenticated before proceeding
    final authService = AuthService();
    final currentUser = await authService.getCurrentUserProfile();
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Please sign in to view refunds', AppTheme.primaryColor);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      _refunds = await _refundService.getAllRefunds();
    } catch (e) {
      print('Error loading refunds: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _processRefund(String refundId, bool approved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          approved ? 'Approve Refund' : 'Reject Refund',
          style: const TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: Text(
          approved
              ? 'Are you sure you want to approve this refund?'
              : 'Are you sure you want to reject this refund?',
          style: const TextStyle(color: AppTheme.onBackgroundMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _refundService.processRefund(
        refundId,
        approved,
        widget.userRole.displayName,
      );
      if (success) {
        _loadRefunds();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Refund approved' : 'Refund rejected'),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showRefundDetails(Refund refund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Refund Details',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Amount', '₵${refund.amount.toStringAsFixed(2)}'),
            _detailRow('Reason', refund.reason),
            _detailRow('Status', refund.status.name.toUpperCase()),
            _detailRow(
              'Created',
              DateFormat('MMM dd, yyyy').format(refund.createdAt),
            ),
            if (refund.processedAt != null)
              _detailRow(
                'Processed',
                DateFormat('MMM dd, yyyy').format(refund.processedAt!),
              ),
            if (refund.processedBy != null)
              _detailRow('Processed By', refund.processedBy!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppTheme.onBackgroundSubtle)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppTheme.onBackgroundColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.canManageRefund(widget.userRole)) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Refunds'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: const Center(
          child: Text(
            'You do not have permission to view this page',
            style: TextStyle(color: AppTheme.onBackgroundSubtle),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Requests'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _refunds.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppTheme.onBackgroundFaint),
                  SizedBox(height: 16),
                  Text(
                    'No refund requests',
                    style: TextStyle(color: AppTheme.onBackgroundSubtle, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _refunds.length,
              itemBuilder: (context, index) {
                final refund = _refunds[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '₵${refund.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refund.reason,
                          style: const TextStyle(color: AppTheme.onBackgroundSubtle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(refund.createdAt),
                          style: const TextStyle(
                            color: AppTheme.onBackgroundFaint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(refund.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            refund.status.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.onBackgroundColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (refund.status == RefundStatus.pending) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                            onPressed: () => _processRefund(refund.id!, true),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _processRefund(refund.id!, false),
                            tooltip: 'Reject',
                          ),
                        ],
                      ],
                    ),
                    onTap: () => _showRefundDetails(refund),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return Colors.orange;
      case RefundStatus.approved:
        return Colors.green;
      case RefundStatus.rejected:
        return Colors.red;
    }
  }
}

