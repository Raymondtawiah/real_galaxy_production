enum ReportType {
  playerProgress,
  teamPerformance,
  financialSummary,
  monthlyAcademy,
}

class Report {
  final String? id;
  final ReportType type;
  final String title;
  final String content;
  final String? playerId;
  final String? teamId;
  final DateTime generatedAt;
  final String generatedBy;

  Report({
    this.id,
    required this.type,
    required this.title,
    required this.content,
    this.playerId,
    this.teamId,
    DateTime? generatedAt,
    required this.generatedBy,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'content': content,
      'player_id': playerId,
      'team_id': teamId,
      'generated_at': generatedAt.toIso8601String(),
      'generated_by': generatedBy,
    };
  }

  factory Report.fromMap(String id, Map<String, dynamic> map) {
    return Report(
      id: id,
      type: ReportType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReportType.monthlyAcademy,
      ),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      playerId: map['player_id'],
      teamId: map['team_id'],
      generatedAt: map['generated_at'] != null
          ? DateTime.tryParse(map['generated_at']) ?? DateTime.now()
          : DateTime.now(),
      generatedBy: map['generated_by'] ?? '',
    );
  }

  String get typeDisplay {
    switch (type) {
      case ReportType.playerProgress:
        return 'Player Progress';
      case ReportType.teamPerformance:
        return 'Team Performance';
      case ReportType.financialSummary:
        return 'Financial Summary';
      case ReportType.monthlyAcademy:
        return 'Monthly Academy';
    }
  }

  String get typeIcon {
    switch (type) {
      case ReportType.playerProgress:
        return '👤';
      case ReportType.teamPerformance:
        return '⚽';
      case ReportType.financialSummary:
        return '💰';
      case ReportType.monthlyAcademy:
        return '📊';
    }
  }
}

