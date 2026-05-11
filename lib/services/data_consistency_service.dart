import 'package:firebase_database/firebase_database.dart';
import 'base_service.dart';

class DataConsistencyService {
  final DatabaseReference _playersRef = dbRef.players();
  final DatabaseReference _attendanceRef = dbRef.attendance();
  final DatabaseReference _matchesRef = dbRef.matches();
  final DatabaseReference _performanceRef = dbRef.playerMatchPerf();
  final DatabaseReference _enrollmentsRef = dbRef.enrollments();
  final DatabaseReference _videosRef = dbRef.videos();

  Future<bool> canDeleteTeam(String teamId) async {
    try {
      final playersSnapshot = await _playersRef
          .orderByChild('team_id')
          .equalTo(teamId)
          .get();
      if (playersSnapshot.exists && playersSnapshot.children.isNotEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking team: $e');
      return false;
    }
  }

  Future<bool> canDeletePlayer(String playerId) async {
    try {
      final attendanceSnapshot = await _attendanceRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (attendanceSnapshot.exists && attendanceSnapshot.children.isNotEmpty) {
        return false;
      }

      final performanceSnapshot = await _performanceRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (performanceSnapshot.exists &&
          performanceSnapshot.children.isNotEmpty) {
        return false;
      }

      final enrollmentSnapshot = await _enrollmentsRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (enrollmentSnapshot.exists && enrollmentSnapshot.children.isNotEmpty) {
        return false;
      }

      final videoSnapshot = await _videosRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (videoSnapshot.exists && videoSnapshot.children.isNotEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking player: $e');
      return false;
    }
  }

  Future<String> getDeleteTeamBlocker(String teamId) async {
    final canDelete = await canDeleteTeam(teamId);
    if (!canDelete) {
      final playersSnapshot = await _playersRef
          .orderByChild('team_id')
          .equalTo(teamId)
          .get();
      final count = playersSnapshot.children.length;
      return 'Cannot delete team. It has $count player(s) assigned. Please reassign or remove players first.';
    }
    return '';
  }

  Future<String> getDeletePlayerBlocker(String playerId) async {
    final canDelete = await canDeletePlayer(playerId);
    if (!canDelete) {
      return 'Cannot delete player. Player has attendance or match performance records.';
    }
    return '';
  }

  Future<void> unassignTeamFromPlayers(String teamId) async {
    try {
      final snapshot = await _playersRef
          .orderByChild('team_id')
          .equalTo(teamId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          await child.ref.update({'team_id': null});
        }
      }
    } catch (e) {
      print('Error unassigning players: $e');
    }
  }

  Future<void> deletePlayerData(String playerId) async {
    try {
      final attendanceSnapshot = await _attendanceRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (attendanceSnapshot.exists) {
        for (var child in attendanceSnapshot.children) {
          await child.ref.remove();
        }
      }

      final performanceSnapshot = await _performanceRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (performanceSnapshot.exists) {
        for (var child in performanceSnapshot.children) {
          await child.ref.remove();
        }
      }
    } catch (e) {
      print('Error deleting player data: $e');
    }
  }
}

