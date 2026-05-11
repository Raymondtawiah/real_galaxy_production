enum Role { owner, director, admin, coach, parent }

extension RoleExtension on Role {
  String get name {
    switch (this) {
      case Role.owner:
        return 'owner';
      case Role.director:
        return 'director';
      case Role.admin:
        return 'admin';
      case Role.coach:
        return 'coach';
      case Role.parent:
        return 'parent';
    }
  }

  String get displayName {
    switch (this) {
      case Role.owner:
        return 'Owner';
      case Role.director:
        return 'Director';
      case Role.admin:
        return 'Admin';
      case Role.coach:
        return 'Coach';
      case Role.parent:
        return 'Parent';
    }
  }

  String get route {
    switch (this) {
      case Role.owner:
        return '/owner/dashboard';
      case Role.director:
        return '/director/dashboard';
      case Role.admin:
        return '/admin/dashboard';
      case Role.coach:
        return '/coach/dashboard';
      case Role.parent:
        return '/parent/dashboard';
    }
  }

  static Role fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Role.owner;
      case 'director':
        return Role.director;
      case 'admin':
        return Role.admin;
      case 'coach':
        return Role.coach;
      case 'parent':
        return Role.parent;
      default:
        return Role.parent;
    }
  }
}
