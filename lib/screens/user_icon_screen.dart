import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/components/owner_logo.dart';

class UserIconScreen extends StatelessWidget {
  const UserIconScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Real Galaxy FC'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
        elevation: 0,
        actions: [
          // User Icon with Dropdown Menu
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Image.asset(
                'assets/images/user_icon.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  );
                },
              ),
            ),
            onSelected: (String value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).pushNamed('/profile');
                  break;
                case 'logout':
                  _handleLogout(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Message
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const OwnerLogo.large(),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, ${user?.name ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: ${user?.role.name ?? 'User'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.onBackgroundMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Instructions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'How to access your profile:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.touch_app, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the user icon in the top-right corner',
                          style: TextStyle(color: AppTheme.onBackgroundMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select "Profile" to view your information',
                          style: TextStyle(color: AppTheme.onBackgroundMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select "Logout" to sign out',
                          style: TextStyle(color: AppTheme.onBackgroundMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
