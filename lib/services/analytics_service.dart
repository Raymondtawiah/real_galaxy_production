import 'package:firebase_database/firebase_database.dart';
import '../models/payment.dart';
import '../models/player_match_performance.dart';
import 'base_service.dart';

class AnalyticsService {
  final DatabaseReference _paymentsRef = FirebaseDatabase.instance.ref(
    'payments',
  );
  final DatabaseReference _playersRef = FirebaseDatabase.instance.ref(
    'players',
  );
  final DatabaseReference _matchesRef = FirebaseDatabase.instance.ref(
    'matches',
  );
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref(
    'attendance',
  );
  final DatabaseReference _playerPerfRef = FirebaseDatabase.instance.ref(
    'player_match_performance',
  );

  // Financial Analytics
  Future<double> getTotalRevenue() async {
    double total = 0;
    try {
      final snapshot = await _paymentsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['status'] == 'paid') {
            total += (data['amount'] ?? 0).toDouble();
          }
        }
      }
    } catch (e) {
      print('Error getting total revenue: $e');
    }
    return total;
  }

  Future<double> getMonthlyRevenue(int year, int month) async {
    double total = 0;
    try {
      final snapshot = await _paymentsRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['status'] == 'paid' && data['paid_at'] != null) {
            final paidAt = DateTime.tryParse(data['paid_at']);
            if (paidAt != null &&
                paidAt.year == year &&
                paidAt.month == month) {
              total += (data['amount'] ?? 0).toDouble();
            }
          }
        }
      }
    } catch (e) {
      print('Error getting monthly revenue: $e');
    }
    return total;
  }

  Future<Map<String, double>> getMonthlyTrend(int year) async {
    final trend = <String, double>{};
    for (int month = 1; month <= 12; month++) {
      final revenue = await getMonthlyRevenue(year, month);
      trend['$month'] = revenue;
    }
    return trend;
  }

  Future<int> getPendingPaymentsCount() async {
    int count = 0;
    try {
      final snapshot = await _paymentsRef
          .orderByChild('status')
          .equalTo('pending')
          .get();
      if (snapshot.exists) {
        count = snapshot.children.length;
      }
    } catch (e) {
      print('Error getting pending payments: $e');
    }
    return count;
  }

  // Player Analytics
  Future<Map<String, dynamic>> getPlayerStats(String playerId) async {
    int goals = 0;
    int assists = 0;
    double avgRating = 0;
    int totalMatches = 0;

    try {
      final snapshot = await _playerPerfRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (snapshot.exists) {
        totalMatches = snapshot.children.length;
        double totalRating = 0;
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          goals += (data['goals'] ?? 0) as int;
          assists += (data['assists'] ?? 0) as int;
          if (data['rating'] != null) {
            totalRating += (data['rating'] as num).toDouble();
          }
        }
        avgRating = totalMatches > 0 ? totalRating / totalMatches : 0;
      }
    } catch (e) {
      print('Error getting player stats: $e');
    }

    return {
      'goals': goals,
      'assists': assists,
      'avgRating': avgRating,
      'totalMatches': totalMatches,
    };
  }

  Future<double> getPlayerAttendanceRate(String playerId) async {
    int totalSessions = 0;
    int presentCount = 0;

    try {
      final snapshot = await _attendanceRef
          .orderByChild('player_id')
          .equalTo(playerId)
          .get();
      if (snapshot.exists) {
        totalSessions = snapshot.children.length;
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['status'] == 'present') {
            presentCount++;
          }
        }
      }
    } catch (e) {
      print('Error getting player attendance: $e');
    }

    return totalSessions > 0 ? (presentCount / totalSessions) * 100 : 0;
  }

  // Team Analytics
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    int wins = 0;
    int losses = 0;
    int draws = 0;
    int goalsScored = 0;
    int goalsConceded = 0;

    try {
      final snapshot = await _matchesRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['home_team_id'] == teamId ||
              data['away_team_id'] == teamId) {
            final homeTeamId = data['home_team_id'];
            final awayTeamId = data['away_team_id'];
            final homeScore = (data['home_score'] ?? 0) as int;
            final awayScore = (data['away_score'] ?? 0) as int;

            if (homeTeamId == teamId) {
              goalsScored += homeScore;
              goalsConceded += awayScore;
              if (homeScore > awayScore) {
                wins++;
              } else if (homeScore < awayScore)
                losses++;
              else
                draws++;
            } else if (awayTeamId == teamId) {
              goalsScored += awayScore;
              goalsConceded += homeScore;
              if (awayScore > homeScore) {
                wins++;
              } else if (awayScore < homeScore)
                losses++;
              else
                draws++;
            }
          }
        }
      }
    } catch (e) {
      print('Error getting team stats: $e');
    }

    return {
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goalsScored': goalsScored,
      'goalsConceded': goalsConceded,
      'totalMatches': wins + losses + draws,
    };
  }

  // Academy Overview
  Future<Map<String, dynamic>> getAcademyOverview() async {
    int totalPlayers = 0;
    int totalTeams = 0;
    int totalRevenue = 0;
    int pendingPayments = 0;

    try {
      final playersSnap = await _playersRef.get();
      if (playersSnap.exists) totalPlayers = playersSnap.children.length;

      final teamsRef = FirebaseDatabase.instance.ref('teams');
      final teamsSnap = await teamsRef.get();
      if (teamsSnap.exists) totalTeams = teamsSnap.children.length;

      final revenue = await getTotalRevenue();
      totalRevenue = revenue.toInt();

      pendingPayments = await getPendingPaymentsCount();
    } catch (e) {
      print('Error getting academy overview: $e');
    }

    return {
      'totalPlayers': totalPlayers,
      'totalTeams': totalTeams,
      'totalRevenue': totalRevenue,
      'pendingPayments': pendingPayments,
    };
  }

  Future<double> getTrainingAttendanceRate() async {
    int totalSessions = 0;
    int presentCount = 0;

    try {
      final snapshot = await _attendanceRef.get();
      if (snapshot.exists) {
        totalSessions = snapshot.children.length;
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['status'] == 'present') {
            presentCount++;
          }
        }
      }
    } catch (e) {
      print('Error getting training attendance: $e');
    }

    return totalSessions > 0 ? (presentCount / totalSessions) * 100 : 0;
  }
}

