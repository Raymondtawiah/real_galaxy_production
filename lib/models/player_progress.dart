enum ProgressCategory { technical, physical, tactical, mental, social }

enum SkillLevel { beginner, developing, intermediate, advanced, excellent }

class PlayerProgress {
  final String? id;
  final String playerId;
  final String assessedBy;
  final ProgressCategory category;
  final String skillName;
  final SkillLevel currentLevel;
  final SkillLevel targetLevel;
  final double rating; // 1.0 to 10.0
  final String? comments;
  final DateTime assessmentDate;
  final DateTime? nextAssessmentDate;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final Map<String, dynamic> metrics;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerProgress({
    this.id,
    required this.playerId,
    required this.assessedBy,
    required this.category,
    required this.skillName,
    required this.currentLevel,
    required this.targetLevel,
    required this.rating,
    this.comments,
    DateTime? assessmentDate,
    this.nextAssessmentDate,
    this.strengths = const [],
    this.areasForImprovement = const [],
    this.metrics = const {},
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : assessmentDate = assessmentDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'assessed_by': assessedBy,
      'category': category.name,
      'skill_name': skillName,
      'current_level': currentLevel.name,
      'target_level': targetLevel.name,
      'rating': rating,
      'comments': comments,
      'assessment_date': assessmentDate.toIso8601String(),
      'next_assessment_date': nextAssessmentDate?.toIso8601String(),
      'strengths': strengths,
      'areas_for_improvement': areasForImprovement,
      'metrics': metrics,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PlayerProgress.fromMap(String id, Map<String, dynamic> map) {
    return PlayerProgress(
      id: id,
      playerId: map['player_id'] ?? '',
      assessedBy: map['assessed_by'] ?? '',
      category: ProgressCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'technical'),
        orElse: () => ProgressCategory.technical,
      ),
      skillName: map['skill_name'] ?? '',
      currentLevel: SkillLevel.values.firstWhere(
        (e) => e.name == (map['current_level'] ?? 'beginner'),
        orElse: () => SkillLevel.beginner,
      ),
      targetLevel: SkillLevel.values.firstWhere(
        (e) => e.name == (map['target_level'] ?? 'developing'),
        orElse: () => SkillLevel.developing,
      ),
      rating: (map['rating'] ?? 0.0).toDouble(),
      comments: map['comments'],
      assessmentDate: map['assessment_date'] != null
          ? DateTime.tryParse(map['assessment_date']) ?? DateTime.now()
          : DateTime.now(),
      nextAssessmentDate: map['next_assessment_date'] != null
          ? DateTime.tryParse(map['next_assessment_date'])
          : null,
      strengths: List<String>.from(map['strengths'] ?? []),
      areasForImprovement: List<String>.from(
        map['areas_for_improvement'] ?? [],
      ),
      metrics: Map<String, dynamic>.from(map['metrics'] ?? {}),
      isActive:
          map['is_active'] == 1 ||
          map['is_active'] == true ||
          map['is_active'] == '1' ||
          map['is_active'] == null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PlayerProgress copyWith({
    String? id,
    String? playerId,
    String? assessedBy,
    ProgressCategory? category,
    String? skillName,
    SkillLevel? currentLevel,
    SkillLevel? targetLevel,
    double? rating,
    String? comments,
    DateTime? assessmentDate,
    DateTime? nextAssessmentDate,
    List<String>? strengths,
    List<String>? areasForImprovement,
    Map<String, dynamic>? metrics,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerProgress(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      assessedBy: assessedBy ?? this.assessedBy,
      category: category ?? this.category,
      skillName: skillName ?? this.skillName,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      rating: rating ?? this.rating,
      comments: comments ?? this.comments,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      nextAssessmentDate: nextAssessmentDate ?? this.nextAssessmentDate,
      strengths: strengths ?? this.strengths,
      areasForImprovement: areasForImprovement ?? this.areasForImprovement,
      metrics: metrics ?? this.metrics,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progressPercentage {
    if (currentLevel.index >= targetLevel.index) return 100.0;
    final totalLevels = SkillLevel.values.length - 1;
    final currentProgress = (currentLevel.index / totalLevels) * 100;
    final targetProgress = (targetLevel.index / totalLevels) * 100;
    return (currentProgress / targetProgress) * 100;
  }

  String get categoryDisplay {
    switch (category) {
      case ProgressCategory.technical:
        return 'Technical Skills';
      case ProgressCategory.physical:
        return 'Physical Fitness';
      case ProgressCategory.tactical:
        return 'Tactical Understanding';
      case ProgressCategory.mental:
        return 'Mental Strength';
      case ProgressCategory.social:
        return 'Social Skills';
    }
  }

  String get levelDisplay {
    switch (currentLevel) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.developing:
        return 'Developing';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.excellent:
        return 'Excellent';
    }
  }
}

class PlayerProgressSummary {
  final String playerId;
  final String playerName;
  final double overallRating;
  final Map<ProgressCategory, double> categoryRatings;
  final List<PlayerProgress> recentAssessments;
  final DateTime lastUpdated;
  final int totalAssessments;

  PlayerProgressSummary({
    required this.playerId,
    required this.playerName,
    required this.overallRating,
    required this.categoryRatings,
    required this.recentAssessments,
    required this.lastUpdated,
    required this.totalAssessments,
  });

  String get performanceGrade {
    if (overallRating >= 9.0) return 'A+';
    if (overallRating >= 8.0) return 'A';
    if (overallRating >= 7.0) return 'B+';
    if (overallRating >= 6.0) return 'B';
    if (overallRating >= 5.0) return 'C+';
    if (overallRating >= 4.0) return 'C';
    if (overallRating >= 3.0) return 'D';
    return 'F';
  }

  String get performanceStatus {
    if (overallRating >= 8.0) return 'Excellent';
    if (overallRating >= 6.0) return 'Good';
    if (overallRating >= 4.0) return 'Average';
    return 'Needs Improvement';
  }
}
