import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _email = '';
  Role _role = Role.parent;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = fb.FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      final db = FirebaseService();
      final profile = await db.getUserProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _name = profile.name;
          _email = profile.email;
          _role = profile.role;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Account', [
            _buildTile(Icons.person, 'Profile', () {
              showProfile(context);
            }),
            _buildTile(Icons.lock, 'Change Password', () {
              Navigator.pushNamed(context, '/change_password');
            }),
          ]),
          const SizedBox(height: 16),
          _buildSection('Security', [
            _buildTile(Icons.logout, 'Sign Out', () async {
              await AuthService().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            }),
          ]),
          const SizedBox(height: 16),
          _buildSection('About', [
            _buildTile(Icons.info, 'About Real Galaxy FC', () {
              showAbout(context);
            }),
            _buildTile(Icons.help, 'Help & Support', () {
              showHelp(context);
            }),
          ]),
        ],
      ),
    );
  }

  void showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('My Profile', style: TextStyle(color: AppTheme.onBackgroundColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow('Name', _name.isNotEmpty ? _name : 'Loading...'),
            _profileRow('Email', _email.isNotEmpty ? _email : 'Loading...'),
            _profileRow('Role', _role.displayName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.onBackgroundMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.onBackgroundColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Real Galaxy FC',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: AppTheme.onBackgroundMuted)),
            SizedBox(height: 8),
            Text(
              'Football Academy Management System',
              style: TextStyle(color: AppTheme.onBackgroundColor),
            ),
            SizedBox(height: 8),
            Text(
              'Real Galaxy Academy',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: support@realgalaxyacademy.com',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
            SizedBox(height: 8),
            Text(
              'Phone: +233 000 000 000',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
            SizedBox(height: 8),
            Text(
              'For technical support, please contact the system administrator.',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(color: AppTheme.onBackgroundColor)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.onBackgroundMuted),
      onTap: onTap,
    );
  }
}

