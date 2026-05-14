import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/fcm_service.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const NotificationManagementScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen>
    with TickerProviderStateMixin {
  final FCMService _fcmService = FCMService();
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRecipientType = 'all';
  String _selectedNotificationType = 'general';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _fcmService.sendNotification(
        userId: _selectedRecipientType == 'all' ? 'all' : widget.userId,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedNotificationType,
        recipientType: _selectedRecipientType,
        data: {
          'sent_by': widget.userId,
          'sent_at': DateTime.now().toIso8601String(),
        },
      );

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendProgressNotification() async {
    setState(() => _isLoading = true);

    try {
      // This would typically get real player data
      await _fcmService.sendProgressUpdate(
        playerId: 'sample_player_id',
        playerName: 'John Doe',
        attendanceRate: 85.5,
        matchesPlayed: 12,
        goalsScored: 5,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress notification sent to parents'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send progress notification: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Send'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.history), text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendNotificationTab(),
          _buildProgressNotificationTab(),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Custom Notification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create and send notifications to specific user groups',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      labelStyle: const TextStyle(color: AppTheme.onBackgroundMuted),
                      prefixIcon: const Icon(Icons.title, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Message Field
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: const TextStyle(color: AppTheme.onBackgroundMuted),
                      prefixIcon: const Icon(Icons.message, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),

                  // Recipient Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRecipientType,
                    decoration: InputDecoration(
                      labelText: 'Send To',
                      labelStyle: const TextStyle(color: AppTheme.onBackgroundMuted),
                      prefixIcon: const Icon(Icons.people, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'parent', child: Text('Parents Only')),
                      DropdownMenuItem(value: 'coach', child: Text('Coaches Only')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins Only')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRecipientType = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notification Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedNotificationType,
                    decoration: InputDecoration(
                      labelText: 'Notification Type',
                      labelStyle: const TextStyle(color: AppTheme.onBackgroundMuted),
                      prefixIcon: const Icon(Icons.category, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('General')),
                      DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                      DropdownMenuItem(value: 'match', child: Text('Match')),
                      DropdownMenuItem(value: 'training', child: Text('Training')),
                      DropdownMenuItem(value: 'payment', child: Text('Payment')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedNotificationType = value!);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send Notification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send automated progress reports to parents',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Progress Notification Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Send Sample Progress Report
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Sample Progress Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onBackgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a sample progress notification to see how parents will receive player progress updates.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendProgressNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send Sample'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress Notifications Include:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onBackgroundColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem('📊 Attendance Rate'),
                        _buildFeatureItem('⚽ Matches Played'),
                        _buildFeatureItem('🎯 Goals Scored'),
                        _buildFeatureItem('📈 Performance Metrics'),
                        _buildFeatureItem('💪 Encouragement Message'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Templates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),

          // Template Cards
          _buildTemplateCard(
            'Attendance Reminder',
            'Don\'t forget to mark attendance for today\'s training session.',
            Icons.access_time,
            Colors.orange,
          ),
          _buildTemplateCard(
            'Match Day Notification',
            'Today\'s match starts at 4:00 PM. Please arrive 30 minutes early.',
            Icons.sports_soccer,
            Colors.blue,
          ),
          _buildTemplateCard(
            'Payment Reminder',
            'Your monthly payment is due. Please complete it by the end of this week.',
            Icons.payment,
            Colors.purple,
          ),
          _buildTemplateCard(
            'Training Update',
            'Training schedule has been updated. Check the app for new timings.',
            Icons.update,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(String title, String message, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.onBackgroundColor,
          ),
        ),
        subtitle: Text(
          message,
          style: const TextStyle(
            color: AppTheme.onBackgroundMuted,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send, color: AppTheme.primaryColor),
          onPressed: () {
            _titleController.text = title;
            _messageController.text = message;
            _tabController.animateTo(0);
          },
        ),
      ),
    );
  }
}
