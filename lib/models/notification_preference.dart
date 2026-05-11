class NotificationPreference {
  final String? id;
  final String userId;
  final bool matchUpdates;
  final bool trainingUpdates;
  final bool paymentReminders;
  final bool injuryAlerts;
  final bool announcements;
  final bool matchReminders;
  final bool trainingReminders;
  final bool attendanceReminders;
  final bool emailEnabled;
  final bool pushEnabled;
  final DateTime updatedAt;

  NotificationPreference({
    this.id,
    required this.userId,
    this.matchUpdates = true,
    this.trainingUpdates = true,
    this.paymentReminders = true,
    this.injuryAlerts = true,
    this.announcements = true,
    this.matchReminders = true,
    this.trainingReminders = true,
    this.attendanceReminders = true,
    this.emailEnabled = true,
    this.pushEnabled = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'match_updates': matchUpdates,
      'training_updates': trainingUpdates,
      'payment_reminders': paymentReminders,
      'injury_alerts': injuryAlerts,
      'announcements': announcements,
      'match_reminders': matchReminders,
      'training_reminders': trainingReminders,
      'attendance_reminders': attendanceReminders,
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationPreference.fromMap(String id, Map<String, dynamic> map) {
    return NotificationPreference(
      id: id,
      userId: map['user_id'] ?? '',
      matchUpdates: map['match_updates'] ?? true,
      trainingUpdates: map['training_updates'] ?? true,
      paymentReminders: map['payment_reminders'] ?? true,
      injuryAlerts: map['injury_alerts'] ?? true,
      announcements: map['announcements'] ?? true,
      matchReminders: map['match_reminders'] ?? true,
      trainingReminders: map['training_reminders'] ?? true,
      attendanceReminders: map['attendance_reminders'] ?? true,
      emailEnabled: map['email_enabled'] ?? true,
      pushEnabled: map['push_enabled'] ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationPreference copyWith({
    bool? matchUpdates,
    bool? trainingUpdates,
    bool? paymentReminders,
    bool? injuryAlerts,
    bool? announcements,
    bool? matchReminders,
    bool? trainingReminders,
    bool? attendanceReminders,
    bool? emailEnabled,
    bool? pushEnabled,
  }) {
    return NotificationPreference(
      id: id,
      userId: userId,
      matchUpdates: matchUpdates ?? this.matchUpdates,
      trainingUpdates: trainingUpdates ?? this.trainingUpdates,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      injuryAlerts: injuryAlerts ?? this.injuryAlerts,
      announcements: announcements ?? this.announcements,
      matchReminders: matchReminders ?? this.matchReminders,
      trainingReminders: trainingReminders ?? this.trainingReminders,
      attendanceReminders: attendanceReminders ?? this.attendanceReminders,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      updatedAt: DateTime.now(),
    );
  }
}

