import 'package:flutter/material.dart';
import 'package:real_galaxy/screens/login_screen.dart';
import 'package:real_galaxy/screens/manage_users_screen.dart';
import 'package:real_galaxy/screens/simple_password_reset_screen.dart';
import 'package:real_galaxy/screens/register_screen.dart';
import 'package:real_galaxy/screens/settings_screen.dart';
import 'package:real_galaxy/screens/create_staff_screen.dart';
import 'package:real_galaxy/screens/splash_screen.dart';
import 'package:real_galaxy/screens/user_profile_screen.dart';
import 'package:real_galaxy/screens/player_profile_screen.dart';
import 'package:real_galaxy/screens/dashboard_screen_enhanced.dart';
import 'package:real_galaxy/screens/player_progress_screen.dart';
import 'package:real_galaxy/screens/notification_management_screen.dart';
import 'package:real_galaxy/models/role.dart';

class AppRoute {
  static MaterialPageRoute<dynamic> appRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/auth':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/password_reset':
        return MaterialPageRoute(
          builder: (_) => const SimplePasswordResetScreen(),
        );
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/owner/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedDashboardScreen(
            role: Role.owner,
            userId: args?['userId'] ?? '',
          ),
        );
      case '/director/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedDashboardScreen(
            role: Role.director,
            userId: args?['userId'] ?? '',
          ),
        );
      case '/admin/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedDashboardScreen(
            role: Role.admin,
            userId: args?['userId'] ?? '',
          ),
        );
      case '/coach/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedDashboardScreen(
            role: Role.coach,
            userId: args?['userId'] ?? '',
          ),
        );
      case '/parent/dashboard':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedDashboardScreen(
            role: Role.parent,
            userId: args?['userId'] ?? '',
          ),
        );
      case '/create_staff':
        return MaterialPageRoute(builder: (_) => const CreateStaffScreen());
      case '/manage_users':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ManageUsersScreen(
            currentUserRole: RoleExtension.fromString(
              args?['currentUserRole'] ?? 'admin',
            ),
          ),
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case '/player_profile':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlayerProfileScreen(
            playerId: args?['playerId'] ?? '',
            userRole: RoleExtension.fromString(args?['userRole'] ?? 'parent'),
            userId: args?['userId'] ?? '',
          ),
        );
      case '/player_progress':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlayerProgressScreen(
            playerId: args?['playerId'] ?? '',
            userRole: RoleExtension.fromString(args?['userRole'] ?? 'parent'),
            userId: args?['userId'] ?? '',
          ),
        );
      case '/notification_management':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => NotificationManagementScreen(
            userRole: RoleExtension.fromString(args?['userRole'] ?? 'parent'),
            userId: args?['userId'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
