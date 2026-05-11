import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/training_session.dart';
import 'base_service.dart';

abstract class TrainingService {
  Future<String> createTrainingSession(TrainingSession session);
  Future<List<TrainingSession>> getAllTrainingSessions();
  Future<List<TrainingSession>> getTrainingSessionsByTeam(String teamId);
  Future<List<TrainingSession>> getTrainingSessionsByCoach(String coachId);
  Future<TrainingSession?> getTrainingSession(String sessionId);
  Future<void> updateTrainingSession(String sessionId, TrainingSession session);
  Future<void> deleteTrainingSession(String sessionId);
}

class TrainingServiceImpl extends TrainingService {
  final DatabaseReference _ref = dbRef.trainingSessions();

  @override
  Future<String> createTrainingSession(TrainingSession session) async {
    final newRef = _ref.push();
    await newRef.set(session.toMap());
    return newRef.key ?? '';
  }

  @override
  Future<List<TrainingSession>> getAllTrainingSessions() async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          sessions.add(TrainingSession.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting training sessions: $e');
    }
    return sessions;
  }

  @override
  Future<List<TrainingSession>> getTrainingSessionsByTeam(String teamId) async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _ref.orderByChild('team_id').equalTo(teamId).get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          sessions.add(TrainingSession.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting training sessions by team: $e');
    }
    return sessions;
  }

  @override
  Future<List<TrainingSession>> getTrainingSessionsByCoach(
    String coachId,
  ) async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _ref
          .orderByChild('coach_id')
          .equalTo(coachId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          sessions.add(TrainingSession.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting training sessions by coach: $e');
    }
    return sessions;
  }

  @override
  Future<TrainingSession?> getTrainingSession(String sessionId) async {
    try {
      final snapshot = await _ref.child(sessionId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return TrainingSession.fromMap(sessionId, data);
      }
    } catch (e) {
      print('Error getting training session: $e');
    }
    return null;
  }

  @override
  Future<void> updateTrainingSession(
    String sessionId,
    TrainingSession session,
  ) async {
    final data = session.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _ref.child(sessionId).update(data);
  }

  @override
  Future<void> deleteTrainingSession(String sessionId) async {
    await _ref.child(sessionId).remove();
    await dbRef
        .attendance()
        .orderByChild('session_id')
        .equalTo(sessionId)
        .get()
        .then((snapshot) {
          if (snapshot.exists) {
            for (var child in snapshot.children) {
              child.ref.remove();
            }
          }
        });
  }
}

