import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Get initial message
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FOREGROUND MESSAGE RECEIVED:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
      _handleMessage(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Get and save FCM token
    await _getAndSaveToken();
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );
  }

  // Get and save FCM token
  Future<void> _getAndSaveToken({String? userId}) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      if (token != null) {
        // Save token to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        // Save token to Firebase if userId is provided
        if (userId != null) {
          await _usersRef.child(userId).update({
            'fcm_token': token,
            'token_updated_at': ServerValue.timestamp,
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  // Save FCM token for a specific user
  Future<void> saveTokenForUser(String userId) async {
    await _getAndSaveToken(userId: userId);
  }

  // Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    debugPrint('Received message: ${message.messageId}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      _showLocalNotification(message);
    }

    // Handle custom data
    if (message.data.isNotEmpty) {
      _handleCustomData(message.data);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'real_galaxy_channel',
          'Real Galaxy Notifications',
          channelDescription: 'Payment reminders and academy updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Real Galaxy',
      message.notification?.body ?? 'New notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle custom data from message
  void _handleCustomData(Map<String, dynamic> data) {
    debugPrint('Message data: $data');

    // Handle different notification types
    final type = data['type'];
    switch (type) {
      case 'payment_reminder':
        debugPrint('Payment reminder received');
        break;
      case 'payment_overdue':
        debugPrint('Payment overdue notification received');
        break;
      case 'payment_success':
        debugPrint('Payment success notification received');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  // Send payment reminder notification
  Future<void> sendPaymentReminder({
    required String userId,
    required String playerName,
    required String amount,
    required DateTime dueDate,
  }) async {
    try {
      // Save to database for in-app notifications
      await _savePaymentReminderToDatabase(userId, playerName, amount, dueDate);

      debugPrint('Payment reminder created for $userId');

      // In production, this would send via Cloud Functions
      // For now, we'll just save the notification to the database
    } catch (e) {
      debugPrint('Error sending payment reminder: $e');
    }
  }

  // Save payment reminder to database
  Future<void> _savePaymentReminderToDatabase(
    String userId,
    String playerName,
    String amount,
    DateTime dueDate,
  ) async {
    DatabaseReference notificationsRef = FirebaseDatabase.instance.ref(
      'notifications',
    );

    await notificationsRef.push().set({
      'title': 'Payment Reminder',
      'message':
          'Monthly fee of ₵$amount for $playerName is due on ${dueDate.toString().split(' ')[0]}',
      'recipient_id': userId,
      'recipient_type': 'parent',
      'type': 'payment_reminder',
      'is_read': 0,
      'created_at': ServerValue.timestamp,
      'data': {
        'player_name': playerName,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
      },
    });
  }

  // Send general notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? recipientType,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Save to database for in-app notifications
      DatabaseReference notificationsRef = FirebaseDatabase.instance.ref(
        'notifications',
      );

      await notificationsRef.push().set({
        'title': title,
        'message': message,
        'recipient_id': userId,
        'recipient_type': recipientType ?? 'parent',
        'type': type,
        'is_read': 0,
        'created_at': ServerValue.timestamp,
        'data': data ?? {},
      });

      debugPrint('Notification sent: $title to $userId');

      // In production, this would send push notifications via Cloud Functions
      // For now, we save to database which triggers in-app notifications
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send announcement notification
  Future<void> sendAnnouncement({
    required String title,
    required String message,
    String? recipientId,
    String recipientType = 'all',
  }) async {
    await sendNotification(
      userId: recipientId ?? 'all',
      title: title,
      message: message,
      type: 'announcement',
      recipientType: recipientType,
      data: {
        'announcement_type': 'general',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Send match notification
  Future<void> sendMatchNotification({
    required String title,
    required String message,
    String? recipientId,
    Map<String, dynamic>? matchData,
  }) async {
    await sendNotification(
      userId: recipientId ?? 'all',
      title: title,
      message: message,
      type: 'match_update',
      recipientType: recipientId != null ? 'parent' : 'all',
      data: matchData ?? {},
    );
  }

  // Send training notification
  Future<void> sendTrainingNotification({
    required String title,
    required String message,
    String? recipientId,
    Map<String, dynamic>? trainingData,
  }) async {
    await sendNotification(
      userId: recipientId ?? 'all',
      title: title,
      message: message,
      type: 'training_update',
      recipientType: recipientId != null ? 'parent' : 'all',
      data: trainingData ?? {},
    );
  }

  // Send injury alert notification
  Future<void> sendInjuryAlert({
    required String title,
    required String message,
    required String recipientId,
    Map<String, dynamic>? injuryData,
  }) async {
    await sendNotification(
      userId: recipientId,
      title: title,
      message: message,
      type: 'injury_alert',
      recipientType: 'parent',
      data: injuryData ?? {},
    );
  }

  // Send attendance notification
  Future<void> sendAttendanceNotification({
    required String title,
    required String message,
    String? recipientId,
    Map<String, dynamic>? attendanceData,
  }) async {
    await sendNotification(
      userId: recipientId ?? 'all',
      title: title,
      message: message,
      type: 'attendance_due',
      recipientType: 'parent',
      data: attendanceData ?? {},
    );
  }

  // Send progress update notification to parents
  Future<void> sendProgressUpdate({
    required String playerId,
    required String playerName,
    required double attendanceRate,
    required int matchesPlayed,
    required int goalsScored,
  }) async {
    // Find parents of this player (this would need to be implemented based on your data structure)
    // For now, we'll send to all parents
    final title = '📊 Progress Update: $playerName';
    final message =
        '''
🏈 Player Progress Report
━━━━━━━━━━━━━━━━━━━━━━━━
👤 Player: $playerName
📈 Attendance: ${attendanceRate.toStringAsFixed(1)}%
⚽ Matches Played: $matchesPlayed
🎯 Goals Scored: $goalsScored
━━━━━━━━━━━━━━━━━━━━━━━━
Keep up the great work! 💪
    ''';

    await sendNotification(
      userId: 'all',
      title: title,
      message: message,
      type: 'progress_update',
      recipientType: 'parent',
      data: {
        'player_id': playerId,
        'player_name': playerName,
        'attendance_rate': attendanceRate,
        'matches_played': matchesPlayed,
        'goals_scored': goalsScored,
      },
    );
  }

  // Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  // Handle background message
}
