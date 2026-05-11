import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/attendance.dart';
import 'base_service.dart';

abstract class AttendanceService {
  Future<void> recordAttendance(Attendance attendance);
  Future<List<Attendance>> getAttendanceBySession(String sessionId);
  Future<List<Attendance>> getAttendanceByPlayer(String playerId);
  Future<Attendance?> getAttendance(String sessionId, String playerId);
  Future<void> updateAttendance(
    String sessionId,
    String playerId,
    String status,
  );
}

class AttendanceServiceImpl extends AttendanceService {
  final DatabaseReference _ref = dbRef.attendance();

  @override
  Future<void> recordAttendance(Attendance attendance) async {
    final key = '${attendance.sessionId}_${attendance.playerId}';
    await _ref.child(key).set(attendance.toMap());
  }

   @override
   Future<List<Attendance>> getAttendanceBySession(String sessionId) async {
     final records = <Attendance>[];
     try {
       final snapshot = await _ref
           .orderByChild('session_id')
           .equalTo(sessionId)
           .get();
       if (snapshot.exists) {
         for (var child in snapshot.children) {
           final data = Map<String, dynamic>.from(child.value as Map);
           records.add(Attendance.fromMap(child.key ?? '', data));
         }
       }
     } catch (e) {
       print('Error getting attendance by session: $e');
     }
     return records;
   }

   @override
   Future<List<Attendance>> getAttendanceByPlayer(String playerId) async {
     final records = <Attendance>[];
     try {
       final snapshot = await _ref
           .orderByChild('player_id')
           .equalTo(playerId)
           .get();
       if (snapshot.exists) {
         for (var child in snapshot.children) {
           final data = Map<String, dynamic>.from(child.value as Map);
           records.add(Attendance.fromMap(child.key ?? '', data));
         }
       }
     } catch (e) {
       print('Error getting attendance by player: $e');
     }
     return records;
   }

   @override
   Future<Attendance?> getAttendance(String sessionId, String playerId) async {
     try {
       final key = '${sessionId}_$playerId';
       final snapshot = await _ref.child(key).get();
       if (snapshot.exists) {
         final data = Map<String, dynamic>.from(snapshot.value as Map);
         return Attendance.fromMap(key, data);
       }
     } catch (e) {
       print('Error getting attendance: $e');
     }
     return null;
   }

  @override
  Future<void> updateAttendance(
    String sessionId,
    String playerId,
    String status,
  ) async {
    final key = '${sessionId}_$playerId';
    await _ref.child(key).update({
      'status': status,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }
}

