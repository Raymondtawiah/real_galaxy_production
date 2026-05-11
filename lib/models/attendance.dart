enum AttendanceStatus { present, absent, late }

class Attendance {
  final String? id;
  final String playerId;
  final String sessionId;
  final AttendanceStatus status;
  final DateTime? recordedAt;

  Attendance({
    this.id,
    required this.playerId,
    required this.sessionId,
    required this.status,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'session_id': sessionId,
      'status': status.name,
      'recorded_at': recordedAt?.toIso8601String(),
    };
  }

  factory Attendance.fromMap(String id, Map<String, dynamic> map) {
    return Attendance(
      id: id,
      playerId: map['player_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'present'),
        orElse: () => AttendanceStatus.present,
      ),
      recordedAt: map['recorded_at'] != null
          ? DateTime.tryParse(map['recorded_at'])
          : null,
    );
  }
}

