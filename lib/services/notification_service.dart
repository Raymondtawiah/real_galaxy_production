import 'package:firebase_database/firebase_database.dart';
import '../models/notification.dart';
import 'fcm_service.dart';

class NotificationService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('notifications');
  final FCMService _fcmService = FCMService();

  Future<String> createNotification(Notification notification) async {
    final newRef = _ref.push();
    await newRef.set(notification.toMap());
    return newRef.key ?? '';
  }

  Future<void> markAsRead(String notificationId) async {
    await _ref.child(notificationId).update({'is_read': 1});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _ref
        .orderByChild('recipient_id')
        .equalTo(userId)
        .get();
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final value = child.value as Map?;
        if (value != null && value['is_read'] == 0) {
          await child.ref.update({'is_read': 1});
        }
      }
    }
  }

  Future<List<Notification>> getNotificationsByUser(String userId) async {
    final notifications = <Notification>[];
    try {
      final snapshot = await _ref
          .orderByChild('recipient_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          notifications.add(Notification.fromMap(child.key ?? '', data));
        }
      }
      final allSnapshot = await _ref
          .orderByChild('recipient_type')
          .equalTo('all')
          .get();
      if (allSnapshot.exists) {
        for (var child in allSnapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          notifications.add(Notification.fromMap(child.key ?? '', data));
        }
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error getting notifications: $e');
    }
    return notifications;
  }

  Future<List<Notification>> getUnreadNotifications(String userId) async {
    final notifications = <Notification>[];
    try {
      final snapshot = await _ref
          .orderByChild('recipient_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['is_read'] == 0) {
            notifications.add(Notification.fromMap(child.key ?? '', data));
          }
        }
      }
    } catch (e) {
      print('Error getting unread notifications: $e');
    }
    return notifications;
  }

  Future<int> getUnreadCount(String userId) async {
    final notifications = await getUnreadNotifications(userId);
    return notifications.length;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _ref.child(notificationId).remove();
  }

  Future<void> createAnnouncement(
    String title,
    String message,
    RecipientType recipientType, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendAnnouncement(
      title: title,
      message: message,
      recipientId: recipientId,
      recipientType: recipientType.name,
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientType,
      recipientId: recipientId,
      type: NotificationType.announcement,
    );
    await createNotification(notification);
  }

  Future<void> createMatchNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendMatchNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      matchData: {
        'notification_type': 'match_update',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientId != null
          ? RecipientType.parent
          : RecipientType.all,
      recipientId: recipientId,
      type: NotificationType.matchUpdate,
    );
    await createNotification(notification);
  }

  Future<void> createTrainingNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendTrainingNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      trainingData: {
        'notification_type': 'training_update',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientId != null
          ? RecipientType.parent
          : RecipientType.all,
      recipientId: recipientId,
      type: NotificationType.trainingUpdate,
    );
    await createNotification(notification);
  }

  Future<void> createPaymentReminder(
    String title,
    String message,
    String recipientId,
  ) async {
    // Send via FCM
    await _fcmService.sendNotification(
      userId: recipientId,
      title: title,
      message: message,
      type: 'payment_reminder',
      recipientType: 'parent',
      data: {
        'notification_type': 'payment_reminder',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: RecipientType.parent,
      recipientId: recipientId,
      type: NotificationType.paymentReminder,
    );
    await createNotification(notification);
  }

  Future<void> createInjuryAlert(
    String title,
    String message,
    String recipientId,
  ) async {
    // Send via FCM
    await _fcmService.sendInjuryAlert(
      title: title,
      message: message,
      recipientId: recipientId,
      injuryData: {
        'notification_type': 'injury_alert',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: RecipientType.parent,
      recipientId: recipientId,
      type: NotificationType.injuryAlert,
    );
    await createNotification(notification);
  }

  Future<void> createMatchReadyNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendMatchNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      matchData: {
        'notification_type': 'match_ready',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientId != null
          ? RecipientType.parent
          : RecipientType.all,
      recipientId: recipientId,
      type: NotificationType.matchReady,
    );
    await createNotification(notification);
  }

  Future<void> createTrainingComingNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendTrainingNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      trainingData: {
        'notification_type': 'training_coming',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientId != null
          ? RecipientType.parent
          : RecipientType.all,
      recipientId: recipientId,
      type: NotificationType.trainingComing,
    );
    await createNotification(notification);
  }

  Future<void> createTrainingStartNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendTrainingNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      trainingData: {
        'notification_type': 'training_start',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: recipientId != null
          ? RecipientType.parent
          : RecipientType.all,
      recipientId: recipientId,
      type: NotificationType.trainingStart,
    );
    await createNotification(notification);
  }

  Future<void> createAttendanceDueNotification(
    String title,
    String message, {
    String? recipientId,
  }) async {
    // Send via FCM
    await _fcmService.sendAttendanceNotification(
      title: title,
      message: message,
      recipientId: recipientId,
      attendanceData: {
        'notification_type': 'attendance_due',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: RecipientType.parent,
      recipientId: recipientId,
      type: NotificationType.attendanceDue,
    );
    await createNotification(notification);
  }

  Future<void> createProgressUpdateNotification(
    String title,
    String message,
    String recipientId,
  ) async {
    // Send via FCM
    await _fcmService.sendNotification(
      userId: recipientId,
      title: title,
      message: message,
      type: 'player_progress',
      recipientType: 'parent',
      data: {
        'notification_type': 'player_progress',
        'sent_at': DateTime.now().toIso8601String(),
      },
    );

    // Also create database record for in-app notifications
    final notification = Notification(
      title: title,
      message: message,
      recipientType: RecipientType.parent,
      recipientId: recipientId,
      type: NotificationType.playerProgress,
    );
    await createNotification(notification);
  }

  Future<void> createBatchProgressNotifications(
    List<String> recipientIds,
    String baseTitle,
    String baseMessage,
    Map<String, String> personalizedMessages,
  ) async {
    // Send individual notifications to each parent
    for (final recipientId in recipientIds) {
      final personalizedMessage =
          personalizedMessages[recipientId] ?? baseMessage;
      await createProgressUpdateNotification(
        baseTitle,
        personalizedMessage,
        recipientId,
      );
    }
  }
}
