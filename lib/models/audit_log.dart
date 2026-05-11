enum AuditAction {
  createPlayer,
  updatePlayer,
  deletePlayer,
  createTeam,
  updateTeam,
  deleteTeam,
  createTraining,
  updateTraining,
  deleteTraining,
  recordAttendance,
  createMatch,
  updateMatch,
  createPayment,
  updatePayment,
  processRefund,
  createUser,
  updateUser,
  deleteUser,
  login,
  logout,
  sendNotification,
  generateReport,
}

enum EntityType {
  player,
  team,
  training,
  attendance,
  match,
  payment,
  refund,
  user,
  notification,
  report,
}

class AuditLog {
  final String? id;
  final String userId;
  final String userRole;
  final AuditAction action;
  final EntityType entityType;
  final String? entityId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLog({
    this.id,
    required this.userId,
    required this.userRole,
    required this.action,
    required this.entityType,
    this.entityId,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_role': userRole,
      'action': action.name,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AuditLog.fromMap(String id, Map<String, dynamic> map) {
    return AuditLog(
      id: id,
      userId: map['user_id'] ?? '',
      userRole: map['user_role'] ?? '',
       action: AuditAction.values.firstWhere(
         (e) => e.name == map['action'],
         orElse: () => AuditAction.updatePlayer,
       ),
      entityType: EntityType.values.firstWhere(
        (e) => e.name == map['entity_type'],
        orElse: () => EntityType.player,
      ),
      entityId: map['entity_id'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

   String get actionDisplay {
     switch (action) {
       case AuditAction.createPlayer:
         return 'Created player';
       case AuditAction.updatePlayer:
         return 'Updated player';
       case AuditAction.deletePlayer:
         return 'Deleted player';
       case AuditAction.createTeam:
         return 'Created team';
       case AuditAction.updateTeam:
         return 'Updated team';
       case AuditAction.deleteTeam:
         return 'Deleted team';
       case AuditAction.createTraining:
         return 'Created training session';
       case AuditAction.updateTraining:
         return 'Updated training session';
       case AuditAction.deleteTraining:
         return 'Deleted training session';
       case AuditAction.recordAttendance:
         return 'Recorded attendance';
       case AuditAction.createMatch:
         return 'Created match';
       case AuditAction.updateMatch:
         return 'Updated match';
       case AuditAction.createPayment:
         return 'Created payment';
       case AuditAction.updatePayment:
         return 'Updated payment';
       case AuditAction.processRefund:
         return 'Processed refund';
       case AuditAction.createUser:
         return 'Created user';
       case AuditAction.updateUser:
         return 'Updated user';
       case AuditAction.deleteUser:
         return 'Deleted user';
       case AuditAction.login:
         return 'Logged in';
       case AuditAction.logout:
         return 'Logged out';
       case AuditAction.sendNotification:
         return 'Sent notification';
       case AuditAction.generateReport:
         return 'Generated report';
     }
   }
}

