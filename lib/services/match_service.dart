import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/match.dart' as match_model;
import 'base_service.dart';

abstract class MatchService {
  Future<String> createMatch(match_model.Match match);
  Future<List<match_model.Match>> getAllMatches();
  Future<List<match_model.Match>> getMatchesByTeam(String teamId);
  Future<match_model.Match?> getMatch(String matchId);
  Future<void> updateMatch(String matchId, match_model.Match match);
  Future<void> deleteMatch(String matchId);
}

class MatchServiceImpl extends MatchService {
  final DatabaseReference _ref = dbRef.matches();

  @override
  Future<String> createMatch(match_model.Match match) async {
    final newRef = _ref.push();
    await newRef.set(match.toMap());
    return newRef.key ?? '';
  }

  @override
  Future<List<match_model.Match>> getAllMatches() async {
    final matches = <match_model.Match>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          matches.add(match_model.Match.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all matches: $e');
    }
    return matches;
  }

  @override
  Future<List<match_model.Match>> getMatchesByTeam(String teamId) async {
    final matches = <match_model.Match>[];
    try {
      final allMatches = await getAllMatches();
      matches.addAll(
        allMatches.where(
          (m) => m.homeTeamId == teamId || m.awayTeamId == teamId,
        ),
      );
    } catch (e) {
      print('Error getting matches by team: $e');
    }
    return matches;
  }

  @override
  Future<match_model.Match?> getMatch(String matchId) async {
    try {
      final snapshot = await _ref.child(matchId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return match_model.Match.fromMap(matchId, data);
      }
    } catch (e) {
      print('Error getting match: $e');
    }
    return null;
  }

  @override
  Future<void> updateMatch(String matchId, match_model.Match match) async {
    final data = match.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _ref.child(matchId).update(data);
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await _ref.child(matchId).remove();
  }
}

