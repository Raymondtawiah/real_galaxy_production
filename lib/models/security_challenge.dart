
enum ChallengeCategory {
  low,    // Public-ish info
  moderate, // Semi-private
  high,   // Sensitive
}

class SecurityQuestion {
  final String id;
  final String question;
  final ChallengeCategory category;
  final String fieldPath; // Dot notation to access data, e.g. 'player.name'
  final String? teamId; // If question is team-specific

  SecurityQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.fieldPath,
    this.teamId,
  });
}

class ChallengeSet {
  final String id;
  final List<SecurityQuestion> questions;
  final int version;

  ChallengeSet({
    required this.id,
    required this.questions,
    required this.version,
  });
}

