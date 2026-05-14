import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/services/notification_service.dart';
import 'package:real_galaxy/services/fcm_service.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/payment_expiration_service.dart';
import 'package:real_galaxy/models/notification.dart' as app_notification;
import 'package:real_galaxy/models/payment.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/role.dart';

class OwnerNotificationCenter extends StatefulWidget {
  final String userId;
  final Role role;

  const OwnerNotificationCenter({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<OwnerNotificationCenter> createState() =>
      _OwnerNotificationCenterState();
}

class _OwnerNotificationCenterState extends State<OwnerNotificationCenter>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();
  final PaymentExpirationService _paymentService = PaymentExpirationService();

  List<Player> _players = [];
  List<Payment> _payments = [];
  List<Map<String, dynamic>> _paymentAlerts = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final players = await _firebaseService.getAllPlayers();
      final payments = await _firebaseService.getAllPayments();

      setState(() {
        _players = players;
        _payments = payments;
        _paymentAlerts = _generatePaymentAlerts(players, payments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  List<Map<String, dynamic>> _generatePaymentAlerts(
    List<Player> players,
    List<Payment> payments,
  ) {
    List<Map<String, dynamic>> alerts = [];
    final now = DateTime.now();

    for (final player in players) {
      final playerPayments = payments
          .where((p) => p.playerId == player.id)
          .where((p) => p.status == PaymentStatus.paid && p.paidAt != null)
          .toList();

      if (playerPayments.isNotEmpty) {
        playerPayments.sort((a, b) => b.paidAt!.compareTo(a.paidAt!));
        final lastPayment = playerPayments.first;
        final nextDueDate = lastPayment.paidAt!.add(const Duration(days: 30));
        final daysUntilDue = nextDueDate.difference(now).inDays;

        alerts.add({
          'player': player,
          'lastPayment': lastPayment,
          'nextDueDate': nextDueDate,
          'daysUntilDue': daysUntilDue,
          'status': _getPaymentStatus(daysUntilDue),
          'amount': 400.0,
        });
      } else {
        alerts.add({
          'player': player,
          'lastPayment': null,
          'nextDueDate': null,
          'daysUntilDue': -999,
          'status': 'No Payment History',
          'amount': 400.0,
        });
      }
    }

    alerts.sort((a, b) => a['daysUntilDue'].compareTo(b['daysUntilDue']));
    return alerts;
  }

  String _getPaymentStatus(int daysUntilDue) {
    if (daysUntilDue < 0) return 'Overdue';
    if (daysUntilDue == 0) return 'Due Today';
    if (daysUntilDue <= 3) return 'Due Soon';
    if (daysUntilDue <= 7) return 'Upcoming';
    return 'On Schedule';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.red;
      case 'Due Today':
        return Colors.orange;
      case 'Due Soon':
        return Colors.amber;
      case 'Upcoming':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Notification Center'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Payment Alerts', icon: Icon(Icons.payment)),
            Tab(text: 'Send Message', icon: Icon(Icons.send)),
            Tab(text: 'All Notifications', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentAlertsTab(),
                _buildSendMessageTab(),
                _buildAllNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildPaymentAlertsTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildSummaryCard(
                'Overdue',
                _getAlertCount('Overdue'),
                Colors.red,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'Due Soon',
                _getAlertCount('Due Soon'),
                Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'On Schedule',
                _getAlertCount('On Schedule'),
                Colors.green,
              ),
            ],
          ),
        ),
        // Payment Alerts List
        Expanded(
          child: ListView.builder(
            itemCount: _paymentAlerts.length,
            itemBuilder: (context, index) {
              final alert = _paymentAlerts[index];
              return _buildPaymentAlertCard(alert);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAlertCard(Map<String, dynamic> alert) {
    final player = alert['player'] as Player;
    final status = alert['status'] as String;
    final daysUntilDue = alert['daysUntilDue'] as int;
    final nextDueDate = alert['nextDueDate'] as DateTime?;
    final color = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.person, color: color),
        ),
        title: Text(
          player.name ?? 'Unknown Player',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            if (nextDueDate != null)
              Text('Due: ${nextDueDate.toString().split(' ')[0]}'),
            if (daysUntilDue >= 0) Text('Days until due: $daysUntilDue'),
            Text('Amount: ₵${alert['amount']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != 'On Schedule')
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _sendPaymentReminder(player),
                tooltip: 'Send Payment Reminder',
              ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.green),
              onPressed: () => _sendCustomMessage(player),
              tooltip: 'Send Custom Message',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendMessageTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Send Custom Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Message Type Selection
          Row(
            children: [
              Expanded(
                child: _buildMessageTypeCard(
                  'Payment Reminder',
                  Icons.payment,
                  Colors.green,
                  () => _showPaymentReminderDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMessageTypeCard(
                  'General Announcement',
                  Icons.announcement,
                  Colors.blue,
                  () => _showAnnouncementDialog(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMessageTypeCard(
                  'Match Update',
                  Icons.sports_soccer,
                  Colors.orange,
                  () => _showMatchUpdateDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMessageTypeCard(
                  'Training Alert',
                  Icons.fitness_center,
                  Colors.purple,
                  () => _showTrainingDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTypeCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Recent Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _checkUpcomingPayments(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Payments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _loadData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Notification History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Notification history will appear here\nafter sending notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getAlertCount(String status) {
    return _paymentAlerts.where((alert) => alert['status'] == status).length;
  }

  void _sendPaymentReminder(Player player) {
    // Find the payment alert for this player to check status
    final playerAlert = _paymentAlerts.firstWhere(
      (alert) => (alert['player'] as Player).id == player.id,
      orElse: () => {'status': 'Unknown', 'daysUntilDue': -999},
    );

    final status = playerAlert['status'] as String;
    final daysUntilDue = playerAlert['daysUntilDue'] as int;
    final isExpired = status == 'Overdue' || daysUntilDue < -30;

    if (isExpired) {
      // Send expired payment notification
      _notificationService.createPaymentReminder(
        'PAYMENT EXPIRED - URGENT',
        '🚨 URGENT: Payment for ${player.name} has EXPIRED! Please make immediate payment to continue participation in training and matches.',
        player.parentId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EXPIRED payment notification sent!'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Send regular payment reminder
      _notificationService.createPaymentReminder(
        'Payment Reminder',
        'Monthly fee of ₵400 for ${player.name} is due soon',
        player.parentId!,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment reminder sent!')));
    }
    }

  void _sendCustomMessage(Player player) {
    // Custom messages are handled directly in the Payment Alerts tab
    // This method is kept for compatibility but functionality moved
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the message button in Payment Alerts tab'),
      ),
    );
  }

  void _checkUpcomingPayments() {
    _paymentService.checkUpcomingPaymentDueDates();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment check completed!')));
  }

  void _showPaymentReminderDialog() {
    // Implementation for payment reminder dialog
    _showMessageDialog(
      'Send Payment Reminder',
      'Send payment reminders to all parents with due payments.',
      'payment_reminder',
    );
  }

  void _showAnnouncementDialog() {
    // Implementation for announcement dialog
    _showMessageDialog(
      'Send Announcement',
      'Send a general announcement to all users.',
      'announcement',
    );
  }

  void _showMatchUpdateDialog() {
    // Implementation for match update dialog
    _showMessageDialog(
      'Send Match Update',
      'Send match schedule updates to relevant users.',
      'match_update',
    );
  }

  void _showTrainingDialog() {
    // Implementation for training dialog
    _showMessageDialog(
      'Send Training Alert',
      'Send training session notifications.',
      'training_update',
    );
  }

  void _showMessageDialog(String title, String description, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _sendNotificationByType(type);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _sendNotificationByType(String type) {
    switch (type) {
      case 'payment_reminder':
        // Send to all parents with due payments
        for (final alert in _paymentAlerts) {
          if (alert['status'] != 'On Schedule') {
            final player = alert['player'] as Player;
            _sendPaymentReminder(player);
          }
        }
        break;
      case 'announcement':
        _notificationService.createAnnouncement(
          'Academy Announcement',
          'Important update from Real Galaxy FC management',
          app_notification.RecipientType.all,
        );
        break;
      case 'match_update':
        _notificationService.createMatchNotification(
          'Match Schedule Update',
          'Please check the updated match schedule',
        );
        break;
      case 'training_update':
        _notificationService.createTrainingNotification(
          'Training Update',
          'Training schedule has been updated',
        );
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification sent successfully!')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
