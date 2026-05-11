import '../models/role.dart';

class PermissionService {
  static bool canAccessPlayer(
    Role userRole,
    String? playerParentId,
    String userId,
  ) {
    switch (userRole) {
      case Role.owner:
      case Role.director:
      case Role.admin:
        return true;
      case Role.coach:
        return true;
      case Role.parent:
        return playerParentId == userId;
    }
  }

  static bool canCreatePlayer(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canUpdatePlayer(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canDeletePlayer(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canAccessTeam(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canCreateTeam(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canDeleteTeam(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canAccessTraining(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canCreateTraining(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canAccessAttendance(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canUpdateAttendance(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canAccessMatch(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canCreateMatch(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canUpdateMatchScore(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canAccessPayment(Role userRole, String? parentId, String userId) {
    switch (userRole) {
      case Role.owner:
      case Role.director:
      case Role.admin:
        return true;
      case Role.parent:
        return parentId == userId;
      default:
        return false;
    }
  }

  static bool canManagePayment(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canAccessAnalytics(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canAccessReports(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canGenerateReports(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canManageUsers(Role userRole) {
    return userRole == Role.owner;
  }

  static bool canCreateStaff(Role userRole) {
    return userRole == Role.owner;
  }

  static bool canAccessMedicalRecords(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canUpdateMedicalRecords(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canManageRefund(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canAccessAuditLogs(Role userRole) {
    return userRole == Role.owner || userRole == Role.director;
  }

  static bool canAccessCompetition(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin ||
        userRole == Role.coach;
  }

  static bool canManageCompetition(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canUploadVideo(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canViewAllVideos(Role userRole) {
    return userRole == Role.owner ||
        userRole == Role.director ||
        userRole == Role.admin;
  }

  static bool canViewPlayerVideos(
    Role userRole,
    String? playerParentId,
    String userId,
  ) {
    switch (userRole) {
      case Role.owner:
      case Role.director:
      case Role.admin:
        return true;
      case Role.coach:
        return true;
      case Role.parent:
        return playerParentId == userId;
    }
  }
}
