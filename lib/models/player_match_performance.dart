class PlayerMatchPerformance {
  final String? id;
  final String playerId;
  final String matchId;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final double rating;
  final String? coachNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerMatchPerformance({
    this.id,
    required this.playerId,
    required this.matchId,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.rating = 5.0,
    this.coachNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'match_id': matchId,
      'goals': goals,
      'assists': assists,
      'yellow_cards': yellowCards,
      'red_cards': redCards,
      'rating': rating,
      'coach_notes': coachNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PlayerMatchPerformance.fromMap(String id, Map<String, dynamic> map) {
    return PlayerMatchPerformance(
      id: id,
      playerId: map['player_id'] ?? '',
      matchId: map['match_id'] ?? '',
      goals: map['goals'] ?? 0,
      assists: map['assists'] ?? 0,
      yellowCards: map['yellow_cards'] ?? 0,
      redCards: map['red_cards'] ?? 0,
      rating: (map['rating'] ?? 5.0).toDouble(),
      coachNotes: map['coach_notes'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PlayerMatchPerformance copyWith({
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    double? rating,
    String? coachNotes,
  }) {
    return PlayerMatchPerformance(
      id: id,
      playerId: playerId,
      matchId: matchId,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      rating: rating ?? this.rating,
      coachNotes: coachNotes ?? this.coachNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

