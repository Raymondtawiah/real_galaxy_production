import 'package:firebase_database/firebase_database.dart';
import '../models/notification_preference.dart';
import 'base_service.dart';

class NotificationPreferenceService {
  final DatabaseReference _ref = dbRef.notificationPreferences();

  Future<NotificationPreference?> getPreferences(String userId) async {
    try {
      final snapshot = await _ref.orderByChild('user_id').equalTo(userId).get();
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          return NotificationPreference.fromMap(child.key ?? '', data);
        }
      }
    } catch (e) {
      print('Error getting notification preferences: $e');
    }
    return null;
  }

  Future<String> savePreferences(NotificationPreference prefs) async {
    final existing = await getPreferences(prefs.userId);
    if (existing != null && existing.id != null) {
      await _ref.child(existing.id!).update(prefs.toMap());
      return existing.id!;
    } else {
      final newRef = _ref.push();
      await newRef.set(prefs.toMap());
      return newRef.key ?? '';
    }
  }

  Future<void> updatePreference(String userId, String key, bool value) async {
    final existing = await getPreferences(userId);
    if (existing != null && existing.id != null) {
      await _ref.child(existing.id!).child(key).set(value);
    } else {
      final prefs = NotificationPreference(
        userId: userId,
        matchUpdates: key == 'match_updates' ? value : true,
        trainingUpdates: key == 'training_updates' ? value : true,
        paymentReminders: key == 'payment_reminders' ? value : true,
        injuryAlerts: key == 'injury_alerts' ? value : true,
        announcements: key == 'announcements' ? value : true,
        emailEnabled: key == 'email_enabled' ? value : true,
        pushEnabled: key == 'push_enabled' ? value : true,
      );
      await savePreferences(prefs);
    }
  }

  Future<bool> shouldSendNotification(
    String userId,
    String notificationType,
  ) async {
    final prefs = await getPreferences(userId);
    if (prefs == null) return true;

    switch (notificationType) {
      case 'match_update':
        return prefs.matchUpdates;
      case 'training_update':
        return prefs.trainingUpdates;
      case 'payment_reminder':
        return prefs.paymentReminders;
      case 'injury_alert':
        return prefs.injuryAlerts;
      case 'announcement':
        return prefs.announcements;
      default:
        return true;
    }
  }
}

