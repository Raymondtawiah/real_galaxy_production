enum MatchStatus { scheduled, ongoing, completed }

enum CompetitionType { friendly, league, tournament }

enum MatchEventType { goal, assist, yellowCard, redCard, substitution }

class MatchEvent {
  final String? id;
  final String playerId;
  final String? assistPlayerId;
  final MatchEventType eventType;
  final int minute;
  final String? teamId;
  final bool isHomeTeam;

  MatchEvent({
    this.id,
    required this.playerId,
    this.assistPlayerId,
    required this.eventType,
    required this.minute,
    this.teamId,
    this.isHomeTeam = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'assist_player_id': assistPlayerId,
      'event_type': eventType.name,
      'minute': minute,
      'team_id': teamId,
      'is_home_team': isHomeTeam,
    };
  }

  factory MatchEvent.fromMap(String id, Map<String, dynamic> map) {
    return MatchEvent(
      id: id,
      playerId: map['player_id'] ?? '',
      assistPlayerId: map['assist_player_id'],
      eventType: MatchEventType.values.firstWhere(
        (e) => e.name == map['event_type'],
        orElse: () => MatchEventType.goal,
      ),
      minute: map['minute'] ?? 0,
      teamId: map['team_id'],
      isHomeTeam: map['is_home_team'] ?? true,
    );
  }
}

class Match {
  final String? id;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime matchDate;
  final String? venue;
  final CompetitionType competitionType;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final List<String> homeStartingPlayers;
  final List<String> homeSubstitutes;
  final List<String> awayStartingPlayers;
  final List<String> awaySubstitutes;
  final List<Map<String, dynamic>> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchDate,
    this.venue,
    this.competitionType = CompetitionType.friendly,
    this.status = MatchStatus.scheduled,
    this.homeScore,
    this.awayScore,
    this.homeStartingPlayers = const [],
    this.homeSubstitutes = const [],
    this.awayStartingPlayers = const [],
    this.awaySubstitutes = const [],
    this.events = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'match_date': matchDate.toIso8601String(),
      'venue': venue,
      'competition_type': competitionType.name,
      'status': status.name,
      'home_score': homeScore,
      'away_score': awayScore,
      'home_starting_players': homeStartingPlayers,
      'home_substitutes': homeSubstitutes,
      'away_starting_players': awayStartingPlayers,
      'away_substitutes': awaySubstitutes,
      'events': events,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Match.fromMap(String id, Map<String, dynamic> map) {
    return Match(
      id: id,
      homeTeamId: map['home_team_id'] ?? '',
      awayTeamId: map['away_team_id'] ?? '',
      matchDate: map['match_date'] != null
          ? DateTime.tryParse(map['match_date']) ?? DateTime.now()
          : DateTime.now(),
      venue: map['venue'],
      competitionType: CompetitionType.values.firstWhere(
        (e) => e.name == (map['competition_type'] ?? 'friendly'),
        orElse: () => CompetitionType.friendly,
      ),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'scheduled'),
        orElse: () => MatchStatus.scheduled,
      ),
      homeScore: map['home_score'],
      awayScore: map['away_score'],
      homeStartingPlayers: map['home_starting_players'] != null
          ? List<String>.from(map['home_starting_players'])
          : [],
      homeSubstitutes: map['home_substitutes'] != null
          ? List<String>.from(map['home_substitutes'])
          : [],
      awayStartingPlayers: map['away_starting_players'] != null
          ? List<String>.from(map['away_starting_players'])
          : [],
      awaySubstitutes: map['away_substitutes'] != null
          ? List<String>.from(map['away_substitutes'])
          : [],
      events: map['events'] != null
          ? List<Map<String, dynamic>>.from(map['events'])
          : [],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Match copyWith({
    String? homeTeamId,
    String? awayTeamId,
    DateTime? matchDate,
    String? venue,
    CompetitionType? competitionType,
    MatchStatus? status,
    int? homeScore,
    int? awayScore,
    List<String>? homeStartingPlayers,
    List<String>? homeSubstitutes,
    List<String>? awayStartingPlayers,
    List<String>? awaySubstitutes,
    List<Map<String, dynamic>>? events,
  }) {
    return Match(
      id: id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      matchDate: matchDate ?? this.matchDate,
      venue: venue ?? this.venue,
      competitionType: competitionType ?? this.competitionType,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeStartingPlayers: homeStartingPlayers ?? this.homeStartingPlayers,
      homeSubstitutes: homeSubstitutes ?? this.homeSubstitutes,
      awayStartingPlayers: awayStartingPlayers ?? this.awayStartingPlayers,
      awaySubstitutes: awaySubstitutes ?? this.awaySubstitutes,
      events: events ?? this.events,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

