enum CompetitionType { league, tournament }

class Competition {
  final String? id;
  final String name;
  final CompetitionType type;
  final String? season;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Competition({
    this.id,
    required this.name,
    required this.type,
    this.season,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'season': season,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Competition.fromMap(String id, Map<String, dynamic> map) {
    return Competition(
      id: id,
      name: map['name'] ?? '',
      type: CompetitionType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'league'),
        orElse: () => CompetitionType.league,
      ),
      season: map['season'],
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date']) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date']) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class LeagueTableEntry {
  final String? id;
  final String competitionId;
  final String teamId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int rank;

  LeagueTableEntry({
    this.id,
    required this.competitionId,
    required this.teamId,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.rank = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  Map<String, dynamic> toMap() {
    return {
      'competition_id': competitionId,
      'team_id': teamId,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goals_for': goalsFor,
      'goals_against': goalsAgainst,
      'points': points,
      'rank': rank,
    };
  }

  factory LeagueTableEntry.fromMap(String id, Map<String, dynamic> map) {
    return LeagueTableEntry(
      id: id,
      competitionId: map['competition_id'] ?? '',
      teamId: map['team_id'] ?? '',
      played: map['played'] ?? 0,
      won: map['won'] ?? 0,
      drawn: map['drawn'] ?? 0,
      lost: map['lost'] ?? 0,
      goalsFor: map['goals_for'] ?? 0,
      goalsAgainst: map['goals_against'] ?? 0,
      points: map['points'] ?? 0,
      rank: map['rank'] ?? 0,
    );
  }

  LeagueTableEntry copyWith({
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
    int? rank,
  }) {
    return LeagueTableEntry(
      id: id,
      competitionId: competitionId,
      teamId: teamId,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
      rank: rank ?? this.rank,
    );
  }
}

