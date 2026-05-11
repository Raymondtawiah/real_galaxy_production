enum NotificationType {
  announcement,
  matchUpdate,
  trainingUpdate,
  paymentReminder,
  injuryAlert,
  matchReady,
  trainingComing,
  attendanceDue,
  trainingStart,
  playerProgress,
}

enum RecipientType { parent, coach, admin, all }

class Notification {
  final String? id;
  final String title;
  final String message;
  final RecipientType recipientType;
  final String? recipientId;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    this.id,
    required this.title,
    required this.message,
    required this.recipientType,
    this.recipientId,
    required this.type,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'recipient_type': recipientType.name,
      'recipient_id': recipientId,
      'type': type.name,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Notification.fromMap(String id, Map<String, dynamic> map) {
    return Notification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      recipientType: RecipientType.values.firstWhere(
        (e) => e.name == (map['recipient_type'] ?? 'all'),
        orElse: () => RecipientType.all,
      ),
      recipientId: map['recipient_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'announcement'),
        orElse: () => NotificationType.announcement,
      ),
      isRead: map['is_read'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get typeDisplay {
    switch (type) {
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.matchUpdate:
        return 'Match Update';
      case NotificationType.trainingUpdate:
        return 'Training Update';
      case NotificationType.paymentReminder:
        return 'Payment Reminder';
      case NotificationType.injuryAlert:
        return 'Injury Alert';
      case NotificationType.matchReady:
        return 'Match Ready';
      case NotificationType.trainingComing:
        return 'Training Coming';
      case NotificationType.attendanceDue:
        return 'Attendance Due';
      case NotificationType.trainingStart:
        return 'Training Start';
      case NotificationType.playerProgress:
        return 'Player Progress';
    }
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.announcement:
        return '📢';
      case NotificationType.matchUpdate:
        return '⚽';
      case NotificationType.trainingUpdate:
        return '🏋️';
      case NotificationType.paymentReminder:
        return '💰';
      case NotificationType.injuryAlert:
        return '🏥';
      case NotificationType.matchReady:
        return '🎯';
      case NotificationType.trainingComing:
        return '⏰';
      case NotificationType.attendanceDue:
        return '✅';
      case NotificationType.trainingStart:
        return '🏃️';
      case NotificationType.playerProgress:
        return '📈';
    }
  }
}
