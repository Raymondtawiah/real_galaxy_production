import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/user.dart';
import '../models/login_log.dart';
import '../models/role.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/training_session.dart';
import '../models/attendance.dart';
import '../models/match.dart';
import '../models/player_match_performance.dart';
import '../models/payment.dart';
import '../models/receipt.dart';
import '../models/enrollment.dart';
import '../models/video.dart';
import '../models/security_challenge.dart';
import 'password_reset_result.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Database references
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _loginLogsRef => _database.ref('login_logs');
  DatabaseReference get _rateLimitsRef => _database.ref('rate_limits');
  DatabaseReference get _playersRef => _database.ref('players');
  DatabaseReference get _teamsRef => _database.ref('teams');
  DatabaseReference get _trainingSessionsRef =>
      _database.ref('training_sessions');
  DatabaseReference get _attendanceRef => _database.ref('attendance');
  DatabaseReference get _matchesRef => _database.ref('matches');
  DatabaseReference get _playerMatchPerfRef =>
      _database.ref('player_match_performance');
  DatabaseReference get _teamStatsRef => _database.ref('team_stats');
  DatabaseReference get _matchReportsRef => _database.ref('match_reports');
  DatabaseReference get _paymentsRef => _database.ref('payments');
  DatabaseReference get _playerPaymentStatusRef =>
      _database.ref('player_payment_status');
  DatabaseReference get _receiptsRef => _database.ref('receipts');
  DatabaseReference get _refundsRef => _database.ref('refunds');
  DatabaseReference get _videosRef => _database.ref('videos');
  DatabaseReference get _enrollmentsRef => _database.ref('enrollments');
  DatabaseReference get _passwordResetCodesRef =>
      _database.ref('password_reset_codes');
  DatabaseReference get _passwordResetAttemptsRef =>
      _database.ref('password_reset_attempts');
  DatabaseReference get _securityChallengesRef =>
      _database.ref('security_challenges');

  // Public getters
  DatabaseReference get usersRef => _usersRef;
  DatabaseReference get playersRef => _playersRef;
  DatabaseReference get teamsRef => _teamsRef;
  DatabaseReference get trainingSessionsRef => _trainingSessionsRef;
  DatabaseReference get attendanceRef => _attendanceRef;
  DatabaseReference get matchesRef => _matchesRef;
  DatabaseReference get playerMatchPerfRef => _playerMatchPerfRef;
  DatabaseReference get teamStatsRef => _teamStatsRef;
  DatabaseReference get matchReportsRef => _matchReportsRef;
  DatabaseReference get paymentsRef => _paymentsRef;
  DatabaseReference get playerPaymentStatusRef => _playerPaymentStatusRef;
  DatabaseReference get receiptsRef => _receiptsRef;
  DatabaseReference get refundsRef => _refundsRef;
  DatabaseReference get videosRef => _videosRef;

  // ===== AUTH & RATE LIMITING =====

  Future<bool> canAttemptLogin(String email) async {
    try {
      final now = DateTime.now();
      final limitKey = email
          .toLowerCase()
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_');
      final snapshot = await _rateLimitsRef.child(limitKey).get();

      if (!snapshot.exists) return true;

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return true;

      final attempts =
          (data['attempts'] as List<dynamic>?)?.cast<String>() ?? [];
      final cutoff = now
          .subtract(const Duration(minutes: 15))
          .toIso8601String();
      final recentAttempts = attempts
          .where((ts) => ts.compareTo(cutoff) > 0)
          .toList();

      return recentAttempts.length < 5;
    } catch (e) {
      return true;
    }
  }

  Future<void> recordFailedAttempt(String email) async {
    try {
      final now = DateTime.now().toIso8601String();
      final limitKey = email.toLowerCase();
      final snapshot = await _rateLimitsRef.child(limitKey).get();

      List<dynamic> attempts = [];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        attempts = (data['attempts'] as List<dynamic>?)?.cast<dynamic>() ?? [];
      }

      attempts.add(now);
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      attempts = attempts
          .where((ts) => (ts as String).compareTo(cutoff) > 0)
          .toList();

      await _rateLimitsRef.child(limitKey).set({
        'attempts': attempts,
        'last_updated': now,
      });
    } catch (e) {
      print('Error recording failed attempt: $e');
    }
  }

  Future<void> clearAttempts(String email) async {
    try {
      await _rateLimitsRef.child(email.toLowerCase()).remove();
    } catch (e) {
      print('Error clearing attempts: $e');
    }
  }

  Future<void> logLogin(LoginLog log) async {
    try {
      final newLogRef = _loginLogsRef.push();
      await newLogRef.set({
        'user_id': log.userId,
        'ip_address': log.ipAddress,
        'device_info': log.deviceInfo ?? '',
        'success': log.success ? 1 : 0,
        'timestamp': log.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error logging login: $e');
    }
  }

  Future<bool> ownerExists() async {
    try {
      final snapshot = await _usersRef
          .orderByChild('role')
          .equalTo('owner')
          .limitToFirst(1)
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  // ===== USERS =====

  Future<User?> getUserProfile(String uid) async {
    try {
      var snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return _userFromData(uid, data);
      }

      // Try find by email (uid might be email)
      snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final lowerUid = uid.toLowerCase();
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final email = (data['email'] ?? '').toString().toLowerCase();
          if (email == lowerUid) {
            return _userFromData(child.key ?? uid, data);
          }
        }
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  Future<void> updateUserProfile(
    String uid,
    String name, {
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (phoneNumber != null) {
        updateData['phone_number'] = phoneNumber;
      }

      await _usersRef.child(uid).update(updateData);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  User _userFromData(String uid, Map<dynamic, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.tryParse(value.toString());
      } catch (e) {
        return null;
      }
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      return value.toString() == '1' ||
          value.toString().toLowerCase() == 'true';
    }

    return User(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      role: RoleExtension.fromString(data['role']?.toString() ?? 'parent'),
      mustChangePassword: parseBool(data['must_change_password']),
      isActive: parseBool(data['is_active']),
      createdBy: data['created_by']?.toString(),
      phoneNumber: data['phone_number']?.toString(),
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(data['updated_at']) ?? DateTime.now(),
      lastPasswordChange: parseDate(data['last_password_change']),
    );
  }

  Future<void> setUserProfile(String uid, User user) async {
    await _usersRef.child(uid).set({
      'name': user.name,
      'email': user.email.toLowerCase(),
      'role': user.role.name,
      'must_change_password': user.mustChangePassword ? 1 : 0,
      'is_active': user.isActive ? 1 : 0,
      'created_by': user.createdBy,
      'phone_number': user.phoneNumber,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'last_password_change': user.lastPasswordChange?.toIso8601String(),
    });
  }

  Future<void> setUserActive(String uid, bool isActive) async {
    await _usersRef.child(uid).update({
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<User>> getUsersByRole(String roleName) async {
    final users = <User>[];
    try {
      final snapshot = await _usersRef
          .orderByChild('role')
          .equalTo(roleName)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          users.add(_userFromData(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting users by role: $e');
    }
    return users;
  }

  Future<bool> parentExists(String parentId) async {
    if (parentId.isEmpty) return false;
    try {
      final snapshot = await _usersRef.child(parentId).get();
      if (!snapshot.exists) return false;
      final data = snapshot.value as Map<dynamic, dynamic>?;
      final role = RoleExtension.fromString(data?['role']?.toString() ?? '');
      return role == Role.parent;
    } catch (e) {
      return false;
    }
  }

  Future<bool> coachExists(String coachId) async {
    if (coachId.isEmpty) return false;
    try {
      final snapshot = await _usersRef.child(coachId).get();
      if (!snapshot.exists) return false;
      final data = snapshot.value as Map<dynamic, dynamic>?;
      final role = RoleExtension.fromString(data?['role']?.toString() ?? '');
      return role == Role.coach;
    } catch (e) {
      return false;
    }
  }

  Future<String> createPlayer(Player player) async {
    if (player.parentId.isEmpty) {
      throw Exception('parentId cannot be empty');
    }
    final parentSnap = await _usersRef.child(player.parentId).get();
    if (!parentSnap.exists) {
      throw Exception('Parent not found with ID: ${player.parentId}');
    }
    final parentData = parentSnap.value as Map<dynamic, dynamic>?;
    final role = RoleExtension.fromString(
      parentData?['role']?.toString() ?? '',
    );
    if (role != Role.parent) {
      throw Exception('User is not a parent');
    }

    final newPlayerRef = _playersRef.push();
    await newPlayerRef.set(player.toMap());

    if (player.teamId != null && player.teamId!.isNotEmpty) {
      final count = await _getTeamPlayerCount(player.teamId!);
      await _updateTeamPlayerCount(player.teamId!, count);
    }

    return newPlayerRef.key ?? '';
  }

  Future<List<Player>> getAllPlayers() async {
    final players = <Player>[];
    try {
      final snapshot = await _playersRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all players: $e');
    }
    return players;
  }

  Future<List<Player>> getPlayersByParent(String parentId) async {
    final players = <Player>[];
    try {
      final snapshot = await _playersRef
          .orderByChild('parent_id')
          .equalTo(parentId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting players by parent: $e');
    }
    return players;
  }

  Future<List<Player>> getPlayersByTeam(String teamId) async {
    final players = <Player>[];
    try {
      final snapshot = await _playersRef
          .orderByChild('team_id')
          .equalTo(teamId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          players.add(Player.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting players by team: $e');
    }
    return players;
  }

  Future<Player?> getPlayer(String playerId) async {
    print('FirebaseService: Getting player with ID: $playerId');
    try {
      final snapshot = await _playersRef.child(playerId).get();
      print('FirebaseService: Snapshot exists: ${snapshot.exists}');
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('FirebaseService: Player data keys: ${data.keys.toList()}');
        final player = Player.fromMap(playerId, data);
        print('FirebaseService: Player created: ${player.name}');
        return player;
      } else {
        print('FirebaseService: No player found with ID: $playerId');
      }
    } catch (e) {
      print('FirebaseService: Error getting player: $e');
      print('FirebaseService: Stack trace: ${StackTrace.current}');
    }
    return null;
  }

  Future<void> updatePlayer(String playerId, Player player) async {
    if (player.parentId.isEmpty) {
      throw Exception('parentId cannot be empty');
    }
    final parentSnap = await _usersRef.child(player.parentId).get();
    if (!parentSnap.exists) {
      throw Exception('Parent not found with ID: ${player.parentId}');
    }
    final parentData = parentSnap.value as Map<dynamic, dynamic>?;
    final role = RoleExtension.fromString(
      parentData?['role']?.toString() ?? '',
    );
    if (role != Role.parent) {
      throw Exception('User is not a parent');
    }

    final oldSnapshot = await _playersRef.child(playerId).get();
    String? oldTeamId;
    if (oldSnapshot.exists) {
      final oldData = Map<String, dynamic>.from(oldSnapshot.value as Map);
      oldTeamId = oldData['team_id'] as String?;
    }

    final data = player.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _playersRef.child(playerId).update(data);

    if (oldTeamId != player.teamId) {
      if (oldTeamId != null) {
        final oldCount = await _getTeamPlayerCount(oldTeamId);
        await _updateTeamPlayerCount(oldTeamId, oldCount);
      }
      if (player.teamId != null) {
        final newCount = await _getTeamPlayerCount(player.teamId!);
        await _updateTeamPlayerCount(player.teamId!, newCount);
      }
    }
  }

  Future<void> deactivatePlayer(String playerId) async {
    await _playersRef.child(playerId).update({
      'is_active': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> activatePlayer(String playerId) async {
    await _playersRef.child(playerId).update({
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> archivePlayer(String playerId) async {
    await _playersRef.child(playerId).update({
      'is_deleted': 1,
      'is_active': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> restorePlayer(String playerId) async {
    await _playersRef.child(playerId).update({
      'is_deleted': 0,
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> uploadPlayerImageFile(String playerId, File file) async {
    try {
      final storageRef = _storage.ref().child('player_images/$playerId.jpg');
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      await _playersRef.child(playerId).update({
        'image_url': downloadUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error uploading player image: $e');
      rethrow;
    }
  }

  Future<int> _getTeamPlayerCount(String teamId) async {
    final snapshot = await _playersRef
        .orderByChild('team_id')
        .equalTo(teamId)
        .get();
    return snapshot.exists ? snapshot.children.length : 0;
  }

  Future<void> _updateTeamPlayerCount(String teamId, int count) async {
    await _teamsRef.child(teamId).update({
      'players_count': count,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ===== TEAMS =====

  Future<String> createTeam(Team team) async {
    final newTeamRef = _teamsRef.push();
    await newTeamRef.set(team.toMap());
    return newTeamRef.key ?? '';
  }

  Future<List<Team>> getAllTeams() async {
    final teams = <Team>[];
    try {
      final snapshot = await _teamsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          teams.add(Team.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all teams: $e');
    }
    return teams;
  }

  Future<Team?> getTeam(String teamId) async {
    try {
      final snapshot = await _teamsRef.child(teamId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Team.fromMap(teamId, data);
      }
    } catch (e) {
      print('Error getting team: $e');
    }
    return null;
  }

  Future<void> updateTeam(String teamId, Team team) async {
    final data = team.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _teamsRef.child(teamId).update(data);
  }

  Future<void> deleteTeam(String teamId) async {
    await _teamsRef.child(teamId).remove();
  }

  // ===== MATCHES =====

  Future<String> createMatch(Match match) async {
    final newMatchRef = _matchesRef.push();
    await newMatchRef.set(match.toMap());
    return newMatchRef.key ?? '';
  }

  Future<List<Match>> getAllMatches() async {
    final matches = <Match>[];
    try {
      final snapshot = await _matchesRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          matches.add(Match.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all matches: $e');
    }
    return matches;
  }

  Future<void> updateMatch(String matchId, Match match) async {
    final data = match.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _matchesRef.child(matchId).update(data);
  }

  Future<void> deleteMatch(String matchId) async {
    await _matchesRef.child(matchId).remove();
  }

  // ===== TRAINING SESSIONS =====

  Future<String> createTrainingSession(TrainingSession session) async {
    final newSessionRef = _trainingSessionsRef.push();
    await newSessionRef.set(session.toMap());
    return newSessionRef.key ?? '';
  }

  Future<List<TrainingSession>> getAllTrainingSessions() async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _trainingSessionsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          sessions.add(TrainingSession.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all training sessions: $e');
    }
    return sessions;
  }

  Future<List<TrainingSession>> getTrainingSessionsByCoach(
    String coachId,
  ) async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _trainingSessionsRef
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

  Future<List<TrainingSession>> getTrainingSessionsByTeam(String teamId) async {
    final sessions = <TrainingSession>[];
    try {
      final snapshot = await _trainingSessionsRef
          .orderByChild('team_id')
          .equalTo(teamId)
          .get();
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

  Future<void> deleteTrainingSession(String sessionId) async {
    await _trainingSessionsRef.child(sessionId).remove();
  }

  // ===== ATTENDANCE =====

  Future<void> recordAttendance(Attendance attendance) async {
    final newRef = _attendanceRef.push();
    await newRef.set(attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceBySession(String sessionId) async {
    final records = <Attendance>[];
    try {
      final snapshot = await _attendanceRef
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

  // ===== VIDEOS =====

  Future<String> createVideo(Video video) async {
    final newVideoRef = _videosRef.push();
    await newVideoRef.set(video.toMap());
    return newVideoRef.key ?? '';
  }

  Future<List<Video>> getAllVideos() async {
    final videos = <Video>[];
    try {
      final snapshot = await _videosRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          videos.add(Video.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all videos: $e');
    }
    return videos;
  }

  Future<List<Video>> getVideosByPlayer(String playerId) async {
    final videos = <Video>[];
    try {
      final snapshot = await _videosRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          videos.add(Video.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting videos by player: $e');
    }
    return videos;
  }

  Future<List<Video>> getVideosForParent(String parentId) async {
    final videos = <Video>[];
    try {
      final players = await getPlayersByParent(parentId);
      if (players.isNotEmpty) {
        final playerIds = players.map((p) => p.id!).toList();
        for (var playerId in playerIds) {
          final playerVideos = await getVideosByPlayer(playerId);
          videos.addAll(playerVideos);
        }
      }
    } catch (e) {
      print('Error getting videos for parent: $e');
    }
    return videos;
  }

  Future<void> deleteVideo(String videoId) async {
    await _videosRef.child(videoId).remove();
  }

  // ===== PAYMENTS =====

  Future<String> createPayment(Payment payment) async {
    final newPaymentRef = _paymentsRef.push();
    await newPaymentRef.set(payment.toMap());
    return newPaymentRef.key ?? '';
  }

  Future<List<Payment>> getAllPayments() async {
    final payments = <Payment>[];
    try {
      final snapshot = await _paymentsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          payments.add(Payment.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all payments: $e');
    }
    return payments;
  }

  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status,
    String transactionReference,
  ) async {
    await _paymentsRef.child(paymentId).update({
      'status': status.name,
      'transaction_reference': transactionReference,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePlayerPaymentAmounts(
    String playerId,
    double totalAmount,
  ) async {
    final snapshot = await _paymentsRef
        .orderByChild('player_id')
        .equalTo(playerId)
        .get();
    if (snapshot.exists) {
      double sum = 0;
      for (var child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        sum += (data['amount'] ?? 0).toDouble();
      }
      await _playerPaymentStatusRef.child(playerId).set({
        'total_amount': sum,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String> createReceipt(Receipt receipt) async {
    final newReceiptRef = _receiptsRef.push();
    await newReceiptRef.set(receipt.toMap());
    return newReceiptRef.key ?? '';
  }

  Future<List<Receipt>> getAllReceipts() async {
    final receipts = <Receipt>[];
    try {
      final snapshot = await _receiptsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          receipts.add(Receipt.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting all receipts: $e');
    }
    return receipts;
  }

  // ===== ENROLLMENTS =====

  Future<List<Enrollment>> getEnrollmentsByPlayer(String playerId) async {
    final enrollments = <Enrollment>[];
    try {
      final snapshot = await _enrollmentsRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          enrollments.add(Enrollment.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting enrollments by player: $e');
    }
    return enrollments;
  }

  Future<void> updateEnrollment(
    String enrollmentId,
    Enrollment enrollment,
  ) async {
    final data = enrollment.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _enrollmentsRef.child(enrollmentId).update(data);
  }

  // ===== PLAYER MATCH PERFORMANCE =====

  Future<String> createPlayerMatchPerformance(
    PlayerMatchPerformance perf,
  ) async {
    final newPerfRef = _playerMatchPerfRef.push();
    await newPerfRef.set(perf.toMap());
    return newPerfRef.key ?? '';
  }

  Future<List<PlayerMatchPerformance>> getPerformanceByMatch(
    String matchId,
  ) async {
    final perfs = <PlayerMatchPerformance>[];
    try {
      final snapshot = await _playerMatchPerfRef
          .orderByChild('match_id')
          .equalTo(matchId)
          .get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          perfs.add(PlayerMatchPerformance.fromMap(child.key ?? '', data));
        }
      }
    } catch (e) {
      print('Error getting performance by match: $e');
    }
    return perfs;
  }

  // ===== PASSWORD RESET & SECURITY =====

  Future<User?> findUserByEmail(String email) async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final lowerEmail = email.toLowerCase();
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final userEmail = (data['email'] ?? '').toString().toLowerCase();
          if (userEmail == lowerEmail) {
            return _userFromData(child.key ?? '', data);
          }
        }
      }
    } catch (e) {
      print('Error finding user by email: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> checkParentPasswordResetLimit(
    String parentId,
  ) async {
    try {
      final snapshot = await _passwordResetAttemptsRef.child(parentId).get();
      final now = DateTime.now();

      if (!snapshot.exists) {
        return {'allowed': true, 'remainingAttempts': 3};
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return {'allowed': true, 'remainingAttempts': 3};
      }

      final attempts =
          (data['attempts'] as List<dynamic>?)?.cast<String>() ?? [];
      final lockedUntilStr = data['locked_until'] as String?;
      final lockedUntil = lockedUntilStr != null
          ? DateTime.tryParse(lockedUntilStr)
          : null;

      if (lockedUntil != null && now.isBefore(lockedUntil)) {
        return {
          'allowed': false,
          'remainingAttempts': 0,
          'lockedUntil': lockedUntil.toIso8601String(),
        };
      }

      final cutoff = now
          .subtract(const Duration(minutes: 15))
          .toIso8601String();
      final recentAttempts = attempts
          .where((ts) => ts.compareTo(cutoff) > 0)
          .toList();
      final remaining = 3 - recentAttempts.length;

      if (remaining <= 0) {
        final newLockUntil = now.add(const Duration(minutes: 15));
        await _passwordResetAttemptsRef.child(parentId).update({
          'locked_until': newLockUntil.toIso8601String(),
        });
        return {
          'allowed': false,
          'remainingAttempts': 0,
          'lockedUntil': newLockUntil.toIso8601String(),
        };
      }

      return {'allowed': true, 'remainingAttempts': remaining};
    } catch (e) {
      return {'allowed': true, 'remainingAttempts': 3};
    }
  }

  Future<List<SecurityQuestion>> getChallengesForParent(String parentId) async {
    final questions = <SecurityQuestion>[];
    try {
      final snapshot = await _securityChallengesRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          questions.add(
            SecurityQuestion(
              id: child.key ?? '',
              question: data['question'] ?? '',
              category: ChallengeCategory.values.firstWhere(
                (e) => e.name == (data['category'] ?? 'low'),
                orElse: () => ChallengeCategory.low,
              ),
              fieldPath: data['field_path'] ?? '',
              teamId: data['team_id'] as String?,
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting challenges: $e');
    }
    return questions;
  }

  Future<Map<String, dynamic>> verifySecurityAnswers({
    required String parentId,
    required String email,
    required Map<String, String> answers,
  }) async {
    try {
      final parent = await _usersRef.child(parentId).get();
      if (!parent.exists) {
        return {'success': false, 'message': 'Parent not found'};
      }

      final parentData = parent.value as Map<dynamic, dynamic>;
      final storedAnswers =
          parentData['security_answers'] as Map<dynamic, dynamic>?;

      if (storedAnswers == null) {
        return {'success': false, 'message': 'No security questions set up'};
      }

      for (var entry in answers.entries) {
        final stored = storedAnswers[entry.key]?.toString() ?? '';
        if (stored.toLowerCase() != entry.value.toLowerCase()) {
          final limitInfo = await checkParentPasswordResetLimit(parentId);
          int remaining = limitInfo['remainingAttempts'] ?? 0;

          await _recordFailedSecurityAttempt(parentId);

          return {
            'success': false,
            'message': 'Incorrect answer. $remaining attempts remaining.',
            'remainingAttempts': remaining,
          };
        }
      }

      await _clearSecurityAttempts(parentId);

      final resetToken = '${DateTime.now().millisecondsSinceEpoch}_$parentId';
      await _passwordResetCodesRef.child(parentId).set({
        'token': resetToken,
        'used': 0,
        'created_at': DateTime.now().toIso8601String(),
        'email': email,
      });

      return {'success': true, 'resetToken': resetToken};
    } catch (e) {
      return {'success': false, 'message': 'Verification failed'};
    }
  }

  Future<void> _recordFailedSecurityAttempt(String parentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final snapshot = await _passwordResetAttemptsRef.child(parentId).get();

      List<dynamic> attempts = [];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        attempts = (data['attempts'] as List<dynamic>?)?.cast<dynamic>() ?? [];
      }

      attempts.add(now);
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      attempts = attempts
          .where((ts) => (ts as String).compareTo(cutoff) > 0)
          .toList();

      await _passwordResetAttemptsRef.child(parentId).set({
        'attempts': attempts,
        'last_updated': now,
      });
    } catch (e) {
      print('Error recording failed security attempt: $e');
    }
  }

  Future<void> _clearSecurityAttempts(String parentId) async {
    try {
      await _passwordResetAttemptsRef.child(parentId).remove();
    } catch (e) {
      print('Error clearing security attempts: $e');
    }
  }

  Future<PasswordResetResult> sendPasswordResetCode(String email) async {
    try {
      final user = await findUserByEmail(email);
      if (user == null) {
        return PasswordResetResult(success: false, message: 'User not found');
      }

      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
          .toString();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 10));

      await _passwordResetCodesRef.child(user.id!).set({
        'code': code,
        'email': email,
        'used': 0,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      return PasswordResetResult(
        success: true,
        message: 'Verification code sent to your email',
        userId: user.id,
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: 'Failed to send verification code',
      );
    }
  }

  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    try {
      // Use Firebase Auth's built-in password reset email functionality
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      return PasswordResetResult(
        success: true,
        message: 'Password reset link has been sent to your email',
      );
    } catch (e) {
      String errorMessage = 'Failed to send password reset email';

      // Handle specific Firebase Auth errors
      if (e is fb.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Try again later';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      return PasswordResetResult(success: false, message: errorMessage);
    }
  }

  Future<bool> verifyPasswordResetCode(String email, String code) async {
    try {
      final user = await findUserByEmail(email);
      if (user == null) return false;

      final snapshot = await _passwordResetCodesRef.child(user.id!).get();
      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final storedCode = data['code']?.toString() ?? '';
      final used = (data['used'] as int?) == 1;
      final expiresAtStr = data['expires_at'] as String?;

      if (used) return false;
      if (storedCode != code) return false;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.tryParse(expiresAtStr);
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PasswordResetResult> completePasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      if (!await verifyPasswordResetCode(email, code)) {
        return PasswordResetResult(
          success: false,
          message: 'Invalid or expired verification code',
        );
      }

      final user = await findUserByEmail(email);
      if (user == null) {
        return PasswordResetResult(success: false, message: 'User not found');
      }

      await _usersRef.child(user.id!).update({
        'password': newPassword,
        'last_password_change': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _passwordResetCodesRef.child(user.id!).update({'used': 1});

      return PasswordResetResult(
        success: true,
        message: 'Password reset successfully',
        userId: user.id,
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: 'Failed to reset password',
      );
    }
  }

  Future<PasswordResetResult> completeKnowledgePasswordReset({
    required String parentId,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final snapshot = await _passwordResetCodesRef.child(parentId).get();
      if (!snapshot.exists) {
        return PasswordResetResult(
          success: false,
          message: 'Invalid reset link',
        );
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final storedToken = data['token']?.toString() ?? '';
      final used = (data['used'] as int?) == 1;

      if (used || storedToken != resetToken) {
        return PasswordResetResult(
          success: false,
          message: 'Invalid or already used reset link',
        );
      }

      await _usersRef.child(parentId).update({
        'password': newPassword,
        'last_password_change': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _passwordResetCodesRef.child(parentId).update({'used': 1});

      return PasswordResetResult(
        success: true,
        message: 'Password reset successfully',
        userId: parentId,
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: 'Failed to reset password',
      );
    }
  }
}
