import 'package:real_galaxy/models/role.dart';

class RolePermissionsService {
  static bool canAccessFeature(Role role, String feature) {
    switch (feature) {
      // Management features - Owner only
      case 'create_staff':
      case 'manage_users':
      case 'payment_status':
        return role == Role.owner;

      // Analytics features - Admin and above
      case 'analytics':
      case 'reports':
      case 'medical_records':
        return role == Role.owner ||
            role == Role.director ||
            role == Role.admin;

      // Team management features - Director and above
      case 'manage_teams':
      case 'manage_players':
      case 'manage_training':
      case 'manage_attendance':
      case 'manage_matches':
        return role == Role.owner || role == Role.director;

      // Performance features - Coach and above
      case 'view_performance':
      case 'manage_performance':
        return role == Role.owner ||
            role == Role.director ||
            role == Role.admin ||
            role == Role.coach;

      // Video features - Coach and above
      case 'view_videos':
      case 'manage_videos':
        return role == Role.owner ||
            role == Role.director ||
            role == Role.admin ||
            role == Role.coach;

      // Communication features - All roles
      case 'messages':
      case 'notifications':
        return true;

      // Parent-specific features
      case 'view_children':
      case 'view_child_performance':
      case 'view_child_attendance':
      case 'view_child_training':
        return role == Role.parent;

      // Coach-specific features
      case 'my_teams':
      case 'my_training_sessions':
        return role == Role.coach;

      // Basic viewing permissions
      case 'view_profile':
      case 'view_dashboard':
        return true;

      default:
        return false;
    }
  }

  static bool canCreateUser(Role creatorRole, Role targetRole) {
    switch (creatorRole) {
      case Role.owner:
        // Owner can create Director, Admin, Coach
        return targetRole == Role.director ||
            targetRole == Role.admin ||
            targetRole == Role.coach;

      case Role.director:
        // Director can create Admin, Coach
        return targetRole == Role.admin || targetRole == Role.coach;

      case Role.admin:
        // Admin can create Coach
        return targetRole == Role.coach;

      case Role.coach:
      case Role.parent:
        // Coach and Parent cannot create users
        return false;

      default:
        return false;
    }
  }

  static bool canDeactivateUser(Role actorRole, Role targetRole) {
    switch (actorRole) {
      case Role.owner:
        // Owner can deactivate everyone except themselves
        return targetRole != Role.owner;

      case Role.director:
        // Director can deactivate Admin, Coach, Parent
        return targetRole == Role.admin ||
            targetRole == Role.coach ||
            targetRole == Role.parent;

      case Role.admin:
        // Admin can deactivate Coach, Parent
        return targetRole == Role.coach || targetRole == Role.parent;

      case Role.coach:
      case Role.parent:
        // Coach and Parent cannot deactivate users
        return false;

      default:
        return false;
    }
  }

  static List<String> getAllowedFeatures(Role role) {
    final features = <String>[];

    // Basic features for all roles
    features.addAll([
      'view_profile',
      'view_dashboard',
      'messages',
      'notifications',
    ]);

    switch (role) {
      case Role.owner:
        features.addAll([
          'create_staff',
          'manage_users',
          'payment_status',
          'analytics',
          'reports',
          'medical_records',
          'manage_teams',
          'manage_players',
          'manage_training',
          'manage_attendance',
          'manage_matches',
          'view_performance',
          'manage_performance',
          'view_videos',
          'manage_videos',
        ]);
        break;

      case Role.director:
        features.addAll([
          'analytics',
          'reports',
          'medical_records',
          'manage_teams',
          'manage_players',
          'manage_training',
          'manage_attendance',
          'manage_matches',
          'view_performance',
          'manage_performance',
          'view_videos',
          'manage_videos',
        ]);
        break;

      case Role.admin:
        features.addAll([
          'analytics',
          'reports',
          'medical_records',
          'view_performance',
          'manage_performance',
          'view_videos',
          'manage_videos',
        ]);
        break;

      case Role.coach:
        features.addAll([
          'my_teams',
          'my_training_sessions',
          'view_performance',
          'manage_performance',
          'view_videos',
          'manage_videos',
        ]);
        break;

      case Role.parent:
        features.addAll([
          'view_children',
          'view_child_performance',
          'view_child_attendance',
          'view_child_training',
        ]);
        break;
    }

    return features;
  }

  static String getRoleDisplayName(Role role) {
    switch (role) {
      case Role.owner:
        return 'Owner';
      case Role.director:
        return 'Director';
      case Role.admin:
        return 'Administrator';
      case Role.coach:
        return 'Coach';
      case Role.parent:
        return 'Parent';
    }
  }

  static String getRoleDescription(Role role) {
    switch (role) {
      case Role.owner:
        return 'Full system access and user management';
      case Role.director:
        return 'Team management and analytics';
      case Role.admin:
        return 'Administrative tasks and reports';
      case Role.coach:
        return 'Training and performance management';
      case Role.parent:
        return 'View child information and progress';
    }
  }
}
