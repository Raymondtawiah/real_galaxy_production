import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/role_permissions_service.dart';

class RoleAccessGuard extends StatelessWidget {
  final Widget child;
  final Role userRole;
  final String requiredFeature;
  final Widget? fallback;
  final String? accessDeniedMessage;

  const RoleAccessGuard({
    super.key,
    required this.child,
    required this.userRole,
    required this.requiredFeature,
    this.fallback,
    this.accessDeniedMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Owners should have access to everything
    if (userRole == Role.owner) {
      return child;
    }

    final hasAccess = RolePermissionsService.canAccessFeature(
      userRole,
      requiredFeature,
    );

    if (hasAccess) {
      return child;
    }

    // Show fallback if provided, otherwise show access denied message
    if (fallback != null) {
      return fallback!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            accessDeniedMessage ?? 'Access Denied',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have permission to access this feature.\nContact your administrator for access.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final Role userRole;
  final List<Role> allowedRoles;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    required this.child,
    required this.userRole,
    required this.allowedRoles,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = allowedRoles.contains(userRole);

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

class RoleConditionalBuilder extends StatelessWidget {
  final Role userRole;
  final Widget Function(BuildContext context, Role role) builder;
  final Widget? fallback;

  const RoleConditionalBuilder({
    super.key,
    required this.userRole,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, userRole);
  }
}

class UserRoleBadge extends StatelessWidget {
  final Role role;
  final bool showDescription;

  const UserRoleBadge({
    super.key,
    required this.role,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRoleColor(role).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            RolePermissionsService.getRoleDisplayName(role),
            style: TextStyle(
              color: _getRoleColor(role),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showDescription) ...[
            const SizedBox(height: 4),
            Text(
              RolePermissionsService.getRoleDescription(role),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getRoleColor(role).withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.owner:
        return const Color(0xFFDC143C);
      case Role.director:
        return const Color(0xFF6366F1);
      case Role.admin:
        return const Color(0xFFF59E0B);
      case Role.coach:
        return const Color(0xFF10B981);
      case Role.parent:
        return const Color(0xFF3B82F6);
    }
  }
}
