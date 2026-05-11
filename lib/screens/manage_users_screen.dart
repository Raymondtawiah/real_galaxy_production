import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class ManageUsersScreen extends StatefulWidget {
  final Role currentUserRole;

  const ManageUsersScreen({super.key, required this.currentUserRole});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseService _db = FirebaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final ref = _db.usersRef;
      final snapshot = await ref.get();
      final List<Map<String, dynamic>> usersList = [];
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          data['uid'] = child.key;

          final userRole = RoleExtension.fromString(data['role'] ?? 'parent');

          // Filter based on current user's role
          bool shouldShow = true;

          if (widget.currentUserRole == Role.director) {
            // Director cannot see owner
            if (userRole == Role.owner) shouldShow = false;
          } else if (widget.currentUserRole == Role.admin) {
            // Admin cannot see owner and director
            if (userRole == Role.owner || userRole == Role.director) {
              shouldShow = false;
            }
          } else if (widget.currentUserRole == Role.coach) {
            // Coach cannot see owner, director, and admin
            if (userRole == Role.owner ||
                userRole == Role.director ||
                userRole == Role.admin) {
              shouldShow = false;
            }
          }

          // Owner sees all users

          if (!shouldShow) continue;

          usersList.add(data);
        }
      }
      setState(() {
        _users = usersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String uid, bool isActive, String userRole) async {
    // Prevent deactivating based on role hierarchy
    bool canToggle = true;

    if (widget.currentUserRole == Role.director) {
      if (userRole == 'owner') canToggle = false;
    } else if (widget.currentUserRole == Role.admin) {
      if (userRole == 'owner' || userRole == 'director') canToggle = false;
    } else if (widget.currentUserRole == Role.coach) {
      if (userRole == 'owner' ||
          userRole == 'director' ||
          userRole == 'admin') {
        canToggle = false;
      }
    }

    if (!canToggle) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot deactivate higher role'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
      return;
    }

    try {
      await _db.setUserActive(uid, isActive);
      setState(() {
        final index = _users.indexWhere((u) => u['uid'] == uid);
        if (index != -1) {
          _users[index]['is_active'] = isActive ? 1 : 0;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _users.isEmpty
          ? const Center(
              child: Text(
                'No users found',
                style: TextStyle(color: AppTheme.onBackgroundMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final role = RoleExtension.fromString(user['role'] ?? 'parent');
                final isActiveRaw = user['is_active'];
                final bool isActive =
                    isActiveRaw == 1 ||
                    isActiveRaw == true ||
                    isActiveRaw == '1';
                final uid = user['uid'] ?? '';
                final userRoleStr = user['role'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? AppTheme.successColor : Colors.red,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(
                        _getRoleIcon(role),
                        color: AppTheme.onBackgroundColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['email'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        if (user['phone_number'] != null &&
                            user['phone_number'].toString().isNotEmpty)
                          Text(
                            user['phone_number'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.onBackgroundMuted,
                            ),
                          ),
                        Text(
                          role.displayName,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.successColor
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppTheme.successColor,
                          activeTrackColor: AppTheme.successColor.withValues(
                            alpha: 0.3,
                          ),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: (value) =>
                              _toggleActive(uid, value, userRoleStr),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  IconData _getRoleIcon(Role role) {
    switch (role) {
      case Role.owner:
        return Icons.business;
      case Role.director:
        return Icons.supervisor_account;
      case Role.admin:
        return Icons.admin_panel_settings;
      case Role.coach:
        return Icons.sports_soccer;
      case Role.parent:
        return Icons.family_restroom;
    }
  }
}
