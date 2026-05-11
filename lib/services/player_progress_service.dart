import 'package:firebase_database/firebase_database.dart';
import '../models/player_progress.dart';
import '../models/player.dart';
import 'notification_service.dart';

class PlayerProgressService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref(
    'player_progress',
  );
  final NotificationService _notificationService = NotificationService();

  Future<String> createPlayerProgress(PlayerProgress progress) async {
    final newRef = _ref.push();
    await newRef.set(progress.toMap());
    return newRef.key ?? '';
  }

  Future<void> updatePlayerProgress(
    String progressId,
    PlayerProgress progress,
  ) async {
    await _ref.child(progressId).update(progress.toMap());
  }

  Future<void> deletePlayerProgress(String progressId) async {
    await _ref.child(progressId).remove();
  }

  Future<PlayerProgress?> getPlayerProgress(String progressId) async {
    final snapshot = await _ref.child(progressId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return PlayerProgress.fromMap(progressId, data);
    }
    return null;
  }

  Future<List<PlayerProgress>> getPlayerProgressByPlayer(
    String playerId,
  ) async {
    final progressList = <PlayerProgress>[];
    try {
      final snapshot = await _ref
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();

      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final progress = PlayerProgress.fromMap(child.key ?? '', data);
          if (progress.isActive) {
            progressList.add(progress);
          }
        }
      }
      progressList.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    } catch (e) {
      print('Error getting player progress: $e');
    }
    return progressList;
  }

  Future<List<PlayerProgress>> getPlayerProgressByCategory(
    String playerId,
    ProgressCategory category,
  ) async {
    final allProgress = await getPlayerProgressByPlayer(playerId);
    return allProgress.where((p) => p.category == category).toList();
  }

  Future<PlayerProgressSummary> getPlayerProgressSummary(
    String playerId,
  ) async {
    final allProgress = await getPlayerProgressByPlayer(playerId);

    // Calculate category ratings
    final categoryRatings = <ProgressCategory, double>{};
    for (final category in ProgressCategory.values) {
      final categoryProgress = allProgress.where((p) => p.category == category);
      if (categoryProgress.isNotEmpty) {
        final totalRating = categoryProgress.fold<double>(
          0.0,
          (sum, p) => sum + p.rating,
        );
        categoryRatings[category] = totalRating / categoryProgress.length;
      } else {
        categoryRatings[category] = 0.0;
      }
    }

    // Calculate overall rating
    final overallRating = categoryRatings.values.isNotEmpty
        ? categoryRatings.values.reduce((a, b) => a + b) /
              categoryRatings.values.length
        : 0.0;

    // Get recent assessments (last 5)
    final recentAssessments = allProgress.take(5).toList();

    // Get last updated date
    final lastUpdated = allProgress.isNotEmpty
        ? allProgress.first.updatedAt
        : DateTime.now();

    return PlayerProgressSummary(
      playerId: playerId,
      playerName: '', // Will be filled by caller
      overallRating: overallRating,
      categoryRatings: categoryRatings,
      recentAssessments: recentAssessments,
      lastUpdated: lastUpdated,
      totalAssessments: allProgress.length,
    );
  }

  Future<List<PlayerProgressSummary>> getAllPlayersProgressSummaries(
    List<Player> players,
  ) async {
    final summaries = <PlayerProgressSummary>[];

    for (final player in players) {
      final summary = await getPlayerProgressSummary(player.id!);
      final updatedSummary = PlayerProgressSummary(
        playerId: summary.playerId,
        playerName: player.name,
        overallRating: summary.overallRating,
        categoryRatings: summary.categoryRatings,
        recentAssessments: summary.recentAssessments,
        lastUpdated: summary.lastUpdated,
        totalAssessments: summary.totalAssessments,
      );
      summaries.add(updatedSummary);
    }

    summaries.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return summaries;
  }

  Future<void> createProgressUpdateNotification(
    String playerId,
    String playerName,
    String parentId,
    String skillName,
    SkillLevel newLevel,
    double rating,
  ) async {
    final title = 'Progress Update for $playerName';
    final message =
        '$playerName has achieved $newLevel level in $skillName with a rating of ${rating.toStringAsFixed(1)}/10.0';

    // Create notification for the specific parent using the notification service method
    await _notificationService.createProgressUpdateNotification(
      title,
      message,
      parentId,
    );
  }

  Future<void> createBatchProgressNotifications(
    List<Player> players,
    Map<String, PlayerProgress> progressUpdates,
  ) async {
    for (final player in players) {
      final progress = progressUpdates[player.id];
      if (progress != null) {
        await createProgressUpdateNotification(
          player.id!,
          player.name,
          player.parentId,
          progress.skillName,
          progress.currentLevel,
          progress.rating,
        );
      }
    }
  }

  Future<List<PlayerProgress>> getRecentProgressForAllPlayers(
    List<Player> players, {
    int days = 7,
  }) async {
    final allProgress = <PlayerProgress>[];
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    for (final player in players) {
      final playerProgress = await getPlayerProgressByPlayer(player.id!);
      final recentProgress = playerProgress
          .where((p) => p.assessmentDate.isAfter(cutoffDate))
          .toList();
      allProgress.addAll(recentProgress);
    }

    allProgress.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    return allProgress;
  }

  Future<Map<String, dynamic>> getTeamProgressStats(
    List<Player> players,
  ) async {
    final summaries = await getAllPlayersProgressSummaries(players);

    if (summaries.isEmpty) {
      return {
        'totalPlayers': 0,
        'averageRating': 0.0,
        'topPerformer': null,
        'categoryAverages': <ProgressCategory, double>{},
        'gradeDistribution': <String, int>{},
      };
    }

    // Calculate team average rating
    final totalRating = summaries.fold<double>(
      0.0,
      (sum, s) => sum + s.overallRating,
    );
    final averageRating = totalRating / summaries.length;

    // Find top performer
    final topPerformer = summaries.isNotEmpty ? summaries.first : null;

    // Calculate category averages
    final categoryAverages = <ProgressCategory, double>{};
    for (final category in ProgressCategory.values) {
      final categoryTotal = summaries.fold<double>(
        0.0,
        (sum, s) => sum + (s.categoryRatings[category] ?? 0.0),
      );
      categoryAverages[category] = categoryTotal / summaries.length;
    }

    // Calculate grade distribution
    final gradeDistribution = <String, int>{};
    for (final summary in summaries) {
      final grade = summary.performanceGrade;
      gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
    }

    return {
      'totalPlayers': summaries.length,
      'averageRating': averageRating,
      'topPerformer': topPerformer,
      'categoryAverages': categoryAverages,
      'gradeDistribution': gradeDistribution,
    };
  }

  Future<void> scheduleNextAssessment(
    String progressId,
    DateTime nextAssessmentDate,
  ) async {
    await _ref.child(progressId).update({
      'next_assessment_date': nextAssessmentDate.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PlayerProgress>> getUpcomingAssessments({int days = 7}) async {
    final upcoming = <PlayerProgress>[];
    final cutoffDate = DateTime.now().add(Duration(days: days));

    try {
      final snapshot = await _ref.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['next_assessment_date'] != null) {
            final nextDate = DateTime.tryParse(data['next_assessment_date']);
            if (nextDate != null &&
                nextDate.isAfter(DateTime.now()) &&
                nextDate.isBefore(cutoffDate)) {
              final progress = PlayerProgress.fromMap(child.key ?? '', data);
              if (progress.isActive) {
                upcoming.add(progress);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting upcoming assessments: $e');
    }

    upcoming.sort(
      (a, b) => a.nextAssessmentDate!.compareTo(b.nextAssessmentDate!),
    );
    return upcoming;
  }
}
