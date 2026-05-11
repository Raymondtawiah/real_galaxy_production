class Team {
  final String? id;
  final String name;
  final String ageGroup;
  final String? coachId;
  final int playersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    this.id,
    required this.name,
    required this.ageGroup,
    this.coachId,
    this.playersCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age_group': ageGroup,
      'coach_id': coachId,
      'players_count': playersCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Team.fromMap(String id, Map<String, dynamic> map) {
    return Team(
      id: id,
      name: map['name'] ?? '',
      ageGroup: map['age_group'] ?? '',
      coachId: map['coach_id'],
      playersCount: map['players_count'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Team copyWith({
    String? name,
    String? ageGroup,
    String? coachId,
    int? playersCount,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      coachId: coachId ?? this.coachId,
      playersCount: playersCount ?? this.playersCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static List<String> get ageGroups => [
    'U8',
    'U10',
    'U12',
    'U15',
    'U17',
    'U19',
  ];
}

