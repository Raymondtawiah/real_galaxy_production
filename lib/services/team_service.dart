import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/team.dart';
import 'base_service.dart';

abstract class TeamService {
  Future<String> createTeam(Team team);
  Future<List<Team>> getAllTeams();
  Future<Team?> getTeam(String teamId);
  Future<List<Team>> getTeamsByCoach(String coachId);
  Future<void> updateTeam(String teamId, Team team);
  Future<void> deleteTeam(String teamId);
  Future<void> updateTeamPlayerCount(String teamId, int count);
}

class TeamServiceImplementation extends TeamService {
  final DatabaseReference _ref = dbRef.teams();

  @override
  Future<String> createTeam(Team team) async {
    final newRef = _ref.push();
    await newRef.set(team.toMap());
    return newRef.key ?? '';
  }

  @override
  Future<List<Team>> getAllTeams() async {
    final teams = <Team>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          Map<String, dynamic> data = Map<String, dynamic>.from(
            child.value as Map,
          );
          teams.add(Team.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all teams: $e');
    }
    return teams;
  }

  @override
  Future<Team?> getTeam(String teamId) async {
    try {
      final snapshot = await _ref.child(teamId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Team.fromMap(teamId, data);
      }
    } catch (e) {
      print('Error getting team: $e');
    }
    return null;
  }

  @override
  Future<List<Team>> getTeamsByCoach(String coachId) async {
    final teams = <Team>[];
    try {
      final snapshot = await _ref
          .orderByChild('coach_id')
          .equalTo(coachId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          Map<String, dynamic> data = Map<String, dynamic>.from(
            child.value as Map,
          );
          teams.add(Team.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting teams by coach: $e');
    }
    return teams;
  }

  @override
  Future<void> updateTeam(String teamId, Team team) async {
    final data = team.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _ref.child(teamId).update(data);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _ref.child(teamId).remove();
  }

  @override
  Future<void> updateTeamPlayerCount(String teamId, int count) async {
    await _ref.child(teamId).update({
      'players_count': count,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

