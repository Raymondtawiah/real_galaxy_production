enum DashboardFeature {
  createStaff,
  manageUsers,
  analytics,
  reports,
  playerProgress,
  notificationCenter,
  notificationManagement,
  teams,
  training,
  matches,
  attendance,
  performance,
  videos,
  medicalRecords,
  payments,
}

class UserPermissions {
  final String userId;
  final Map<DashboardFeature, bool> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? grantedBy;

  UserPermissions({
    required this.userId,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.grantedBy,
  });

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory UserPermissions.fromMap(String userId, Map<String, dynamic> map) {
    final permissionsData = map['permissions'] as Map<String, dynamic>? ?? {};
    final permissionsMap = <DashboardFeature, bool>{};

    for (final entry in permissionsData.entries) {
      final feature = DashboardFeature.values.firstWhere(
        (f) => f.name == entry.key,
        orElse: () => DashboardFeature.createStaff,
      );
      permissionsMap[feature] = entry.value as bool? ?? false;
    }

    return UserPermissions(
      userId: map['user_id'] ?? userId,
      permissions: permissionsMap,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      grantedBy: map['granted_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'permissions': permissions.map((key, value) => MapEntry(key.name, value)),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'granted_by': grantedBy,
    };
  }

  factory UserPermissions.fromJson(Map<String, dynamic> map) {
    final permissionsData = map['permissions'] as Map<String, dynamic>? ?? {};
    final permissionsMap = <DashboardFeature, bool>{};

    for (final entry in permissionsData.entries) {
      final feature = DashboardFeature.values.firstWhere(
        (f) => f.name == entry.key,
        orElse: () => DashboardFeature.createStaff,
      );
      permissionsMap[feature] = entry.value as bool? ?? false;
    }

    return UserPermissions(
      userId: map['user_id'] ?? '',
      permissions: permissionsMap,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      grantedBy: map['granted_by'],
    );
  }

  UserPermissions copyWith({
    String? userId,
    Map<DashboardFeature, bool>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? grantedBy,
  }) {
    return UserPermissions(
      userId: userId ?? this.userId,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      grantedBy: grantedBy ?? this.grantedBy,
    );
  }

  bool hasPermission(DashboardFeature feature) {
    return permissions[feature] ?? false;
  }

  void grantPermission(DashboardFeature feature) {
    permissions[feature] = true;
  }

  void revokePermission(DashboardFeature feature) {
    permissions[feature] = false;
  }
}

extension DashboardFeatureExtension on DashboardFeature {
  String get name {
    switch (this) {
      case DashboardFeature.createStaff:
        return 'createStaff';
      case DashboardFeature.manageUsers:
        return 'manageUsers';
      case DashboardFeature.analytics:
        return 'analytics';
      case DashboardFeature.reports:
        return 'reports';
      case DashboardFeature.playerProgress:
        return 'playerProgress';
      case DashboardFeature.notificationCenter:
        return 'notificationCenter';
      case DashboardFeature.notificationManagement:
        return 'notificationManagement';
      case DashboardFeature.teams:
        return 'teams';
      case DashboardFeature.training:
        return 'training';
      case DashboardFeature.matches:
        return 'matches';
      case DashboardFeature.attendance:
        return 'attendance';
      case DashboardFeature.performance:
        return 'performance';
      case DashboardFeature.videos:
        return 'videos';
      case DashboardFeature.medicalRecords:
        return 'medicalRecords';
      case DashboardFeature.payments:
        return 'payments';
    }
  }

  String get featureDisplayName {
    switch (this) {
      case DashboardFeature.createStaff:
        return 'Create Staff';
      case DashboardFeature.manageUsers:
        return 'Manage Users';
      case DashboardFeature.analytics:
        return 'Analytics';
      case DashboardFeature.reports:
        return 'Reports';
      case DashboardFeature.playerProgress:
        return 'Player Progress';
      case DashboardFeature.notificationCenter:
        return 'Notification Center';
      case DashboardFeature.notificationManagement:
        return 'Notification Management';
      case DashboardFeature.teams:
        return 'Teams';
      case DashboardFeature.training:
        return 'Training';
      case DashboardFeature.matches:
        return 'Matches';
      case DashboardFeature.attendance:
        return 'Attendance';
      case DashboardFeature.performance:
        return 'Performance';
      case DashboardFeature.videos:
        return 'Videos';
      case DashboardFeature.medicalRecords:
        return 'Medical Records';
      case DashboardFeature.payments:
        return 'Payments';
    }
  }

  static DashboardFeature fromString(String value) {
    switch (value) {
      case 'createStaff':
        return DashboardFeature.createStaff;
      case 'manageUsers':
        return DashboardFeature.manageUsers;
      case 'analytics':
        return DashboardFeature.analytics;
      case 'reports':
        return DashboardFeature.reports;
      case 'playerProgress':
        return DashboardFeature.playerProgress;
      case 'notificationCenter':
        return DashboardFeature.notificationCenter;
      case 'notificationManagement':
        return DashboardFeature.notificationManagement;
      case 'teams':
        return DashboardFeature.teams;
      case 'training':
        return DashboardFeature.training;
      case 'matches':
        return DashboardFeature.matches;
      case 'attendance':
        return DashboardFeature.attendance;
      case 'performance':
        return DashboardFeature.performance;
      case 'videos':
        return DashboardFeature.videos;
      case 'medicalRecords':
        return DashboardFeature.medicalRecords;
      case 'payments':
        return DashboardFeature.payments;
      default:
        return DashboardFeature.createStaff;
    }
  }
}
