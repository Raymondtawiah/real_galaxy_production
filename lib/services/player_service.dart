import 'package:firebase_database/firebase_database.dart';
import 'package:real_galaxy/models/player.dart';
import 'base_service.dart';

abstract class PlayerService {
  Future<String> createPlayer(Player player);
  Future<List<Player>> getAllPlayers();
  Future<List<Player>> getPlayersByParent(String parentId);
  Future<List<Player>> getPlayersByTeam(String teamId);
  Future<Player?> getPlayer(String playerId);
  Future<void> updatePlayer(String playerId, Player player);
  Future<void> deletePlayer(String playerId);
  Future<void> updatePlayerImage(String playerId, String imageUrl);
}

class PlayerServiceImpl extends PlayerService {
  final DatabaseReference _ref = dbRef.players();

  @override
  Future<String> createPlayer(Player player) async {
    final newRef = _ref.push();
    await newRef.set(player.toMap());
    return newRef.key ?? '';
  }

  @override
  Future<List<Player>> getAllPlayers() async {
    final players = <Player>[];
    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          Map<String, dynamic> data = Map<String, dynamic>.from(
            child.value as Map,
          );
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all players: $e');
    }
    return players;
  }

  @override
  Future<List<Player>> getPlayersByParent(String parentId) async {
    final players = <Player>[];
    try {
      final snapshot = await _ref
          .orderByChild('parent_id')
          .equalTo(parentId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          Map<String, dynamic> data = Map<String, dynamic>.from(
            child.value as Map,
          );
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting players by parent: $e');
    }
    return players;
  }

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    final players = <Player>[];
    try {
      final snapshot = await _ref.orderByChild('team_id').equalTo(teamId).get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          Map<String, dynamic> data = Map<String, dynamic>.from(
            child.value as Map,
          );
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting players by team: $e');
    }
    return players;
  }

  @override
  Future<Player?> getPlayer(String playerId) async {
    try {
      final snapshot = await _ref.child(playerId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Player.fromMap(playerId, data);
      }
    } catch (e) {
      print('Error getting player: $e');
    }
    return null;
  }

  @override
  Future<void> updatePlayer(String playerId, Player player) async {
    final data = player.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _ref.child(playerId).update(data);
  }

  @override
  Future<void> deletePlayer(String playerId) async {
    await _ref.child(playerId).remove();
  }

  @override
  Future<void> updatePlayerImage(String playerId, String imageUrl) async {
    await _ref.child(playerId).update({
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

