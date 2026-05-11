import 'package:firebase_database/firebase_database.dart';
import '../models/audit_log.dart';
import 'base_service.dart';

class AuditService {
  final DatabaseReference _ref = dbRef.auditLogs();

  Future<String> logAction({
    required String userId,
    required String userRole,
    required AuditAction action,
    required EntityType entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    final log = AuditLog(
      userId: userId,
      userRole: userRole,
      action: action,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );

    final newRef = _ref.push();
    await newRef.set(log.toMap());
    return newRef.key ?? '';
  }

  Future<List<AuditLog>> getAllLogs({int? limit}) async {
    final logs = <AuditLog>[];
    try {
      var query = _ref.orderByChild('timestamp').limitToLast(limit ?? 100);
      final snapshot = await query.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          logs.add(AuditLog.fromMap(child.key ?? '', data));
        }
      }
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error getting audit logs: $e');
    }
    return logs;
  }

  Future<List<AuditLog>> getLogsByUser(String userId) async {
    final logs = <AuditLog>[];
    try {
      final snapshot = await _ref.orderByChild('user_id').equalTo(userId).get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          logs.add(AuditLog.fromMap(child.key ?? '', data));
        }
      }
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error getting user audit logs: $e');
    }
    return logs;
  }

  Future<List<AuditLog>> getLogsByEntity(
    EntityType entityType,
    String entityId,
  ) async {
    final logs = <AuditLog>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['entity_type'] == entityType.name &&
              data['entity_id'] == entityId) {
            logs.add(AuditLog.fromMap(child.key ?? '', data));
          }
        }
      }
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error getting entity audit logs: $e');
    }
    return logs;
  }

  Future<List<AuditLog>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final logs = <AuditLog>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
          if (timestamp != null &&
              timestamp.isAfter(start) &&
              timestamp.isBefore(end)) {
            logs.add(AuditLog.fromMap(child.key ?? '', data));
          }
        }
      }
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error getting audit logs by date: $e');
    }
    return logs;
  }

  Future<void> deleteOldLogs(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
          if (timestamp != null && timestamp.isBefore(cutoffDate)) {
            await child.ref.remove();
          }
        }
      }
    } catch (e) {
      print('Error deleting old logs: $e');
    }
  }
}

