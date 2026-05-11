import 'package:firebase_database/firebase_database.dart';

class DatabaseRef {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference users() => _db.ref('users');
  DatabaseReference players() => _db.ref('players');
  DatabaseReference teams() => _db.ref('teams');
  DatabaseReference trainingSessions() => _db.ref('training_sessions');
  DatabaseReference attendance() => _db.ref('attendance');
  DatabaseReference matches() => _db.ref('matches');
  DatabaseReference playerMatchPerf() => _db.ref('player_match_performance');
  DatabaseReference teamStats() => _db.ref('team_stats');
  DatabaseReference matchReports() => _db.ref('match_reports');
  DatabaseReference payments() => _db.ref('payments');
  DatabaseReference playerPaymentStatus() => _db.ref('player_payment_status');
  DatabaseReference receipts() => _db.ref('receipts');
  DatabaseReference reports() => _db.ref('reports');
  DatabaseReference auditLogs() => _db.ref('audit_logs');
  DatabaseReference refunds() => _db.ref('refunds');
  DatabaseReference enrollments() => _db.ref('enrollments');
  DatabaseReference videos() => _db.ref('videos');
  DatabaseReference notificationPreferences() =>
      _db.ref('notification_preferences');

  static final DatabaseRef _instance = DatabaseRef._internal();
  factory DatabaseRef() => _instance;
  DatabaseRef._internal();
}

final dbRef = DatabaseRef();

