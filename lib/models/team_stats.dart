class TeamStats {
  final String? id;
  final String teamId;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int goalsScored;
  final int goalsConceded;
  final int points;
  final DateTime updatedAt;

  TeamStats({
    this.id,
    required this.teamId,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.goalsScored = 0,
    this.goalsConceded = 0,
    this.points = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'team_id': teamId,
      'matches_played': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goals_scored': goalsScored,
      'goals_conceded': goalsConceded,
      'points': points,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TeamStats.fromMap(String id, Map<String, dynamic> map) {
    return TeamStats(
      id: id,
      teamId: map['team_id'] ?? '',
      matchesPlayed: map['matches_played'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      goalsScored: map['goals_scored'] ?? 0,
      goalsConceded: map['goals_conceded'] ?? 0,
      points: map['points'] ?? 0,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TeamStats copyWith({
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? goalsScored,
    int? goalsConceded,
    int? points,
  }) {
    return TeamStats(
      id: id,
      teamId: teamId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      goalsScored: goalsScored ?? this.goalsScored,
      goalsConceded: goalsConceded ?? this.goalsConceded,
      points: points ?? this.points,
      updatedAt: DateTime.now(),
    );
  }

  int get goalDifference => goalsScored - goalsConceded;
}

