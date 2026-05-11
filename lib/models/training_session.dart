class TrainingSession {
  final String? id;
  final String teamId;
  final String coachId;
  final DateTime date;
  final String time;
  final String trainingFocus;
  final String? notes;
  final DateTime createdAt;

  TrainingSession({
    this.id,
    required this.teamId,
    required this.coachId,
    required this.date,
    required this.time,
    required this.trainingFocus,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'team_id': teamId,
      'coach_id': coachId,
      'date': date.toIso8601String(),
      'time': time,
      'training_focus': trainingFocus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainingSession.fromMap(String id, Map<String, dynamic> map) {
    return TrainingSession(
      id: id,
      teamId: map['team_id'] ?? '',
      coachId: map['coach_id'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      time: map['time'] ?? '',
      trainingFocus: map['training_focus'] ?? '',
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<String> get trainingFocuses => [
    'Passing',
    'Dribbling',
    'Shooting',
    'Fitness',
    'Tactics',
    'Defense',
    'Goalkeeping',
    'Set Pieces',
    'Match Practice',
    'Conditioning',
  ];
}

