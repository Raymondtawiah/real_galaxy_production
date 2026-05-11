class MatchReport {
  final String? id;
  final String matchId;
  final String? summary;
  final String? keyEvents;
  final String? bestPlayerId;
  final String? coachAnalysis;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchReport({
    this.id,
    required this.matchId,
    this.summary,
    this.keyEvents,
    this.bestPlayerId,
    this.coachAnalysis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'summary': summary,
      'key_events': keyEvents,
      'best_player_id': bestPlayerId,
      'coach_analysis': coachAnalysis,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MatchReport.fromMap(String id, Map<String, dynamic> map) {
    return MatchReport(
      id: id,
      matchId: map['match_id'] ?? '',
      summary: map['summary'],
      keyEvents: map['key_events'],
      bestPlayerId: map['best_player_id'],
      coachAnalysis: map['coach_analysis'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  MatchReport copyWith({
    String? summary,
    String? keyEvents,
    String? bestPlayerId,
    String? coachAnalysis,
  }) {
    return MatchReport(
      id: id,
      matchId: matchId,
      summary: summary ?? this.summary,
      keyEvents: keyEvents ?? this.keyEvents,
      bestPlayerId: bestPlayerId ?? this.bestPlayerId,
      coachAnalysis: coachAnalysis ?? this.coachAnalysis,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

