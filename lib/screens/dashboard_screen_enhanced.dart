import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/screens/teams_screen.dart';
import 'package:real_galaxy/screens/players_screen.dart';
import 'package:real_galaxy/screens/training_sessions_screen.dart';
import 'package:real_galaxy/screens/attendance_screen.dart';
import 'package:real_galaxy/screens/medical_records_screen.dart';
import 'package:real_galaxy/screens/matches_screen.dart';
import 'package:real_galaxy/screens/player_performance_screen.dart';
import 'package:real_galaxy/screens/player_progress_management_screen.dart';
import 'package:real_galaxy/screens/analytics_screen.dart';
import 'package:real_galaxy/screens/reports_screen.dart';
import 'package:real_galaxy/screens/payment_status_screen.dart';
import 'package:real_galaxy/screens/create_staff_screen.dart';
import 'package:real_galaxy/screens/video_list_screen.dart';
import 'package:real_galaxy/screens/owner_notification_center.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:real_galaxy/components/dashboard_header.dart';
import 'package:real_galaxy/screens/my_children_screen.dart';
import 'package:real_galaxy/screens/parent_payment_screen.dart';
import 'package:real_galaxy/screens/payment_history_screen.dart';
import 'package:real_galaxy/screens/receipt_screen.dart';
import 'package:real_galaxy/services/user_permissions_service.dart';
import 'package:real_galaxy/models/user_permissions.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  final Role role;
  final String userId;

  const EnhancedDashboardScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final UserPermissionsService _permissionsService = UserPermissionsService();
  UserPermissions? _currentUserPermissions;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Load user permissions
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    // Ensure owners have all permissions
    if (widget.role == Role.owner) {
      await _permissionsService.ensureOwnerPermissions(widget.userId);
    }

    final permissions = await _permissionsService.getUserPermissions(
      widget.userId,
    );
    setState(() {
      _currentUserPermissions = permissions;
    });
  }

  bool _hasPermission(DashboardFeature feature) {
    // Owners should have access to everything
    if (widget.role == Role.owner) {
      return true;
    }
    return _currentUserPermissions?.hasPermission(feature) ?? false;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  IconData _getRoleIcon() {
    switch (widget.role) {
      case Role.owner:
        return Icons.star;
      case Role.director:
        return Icons.business;
      case Role.admin:
        return Icons.admin_panel_settings;
      case Role.coach:
        return Icons.sports_soccer;
      case Role.parent:
        return Icons.family_restroom;
    }
  }

  List<DashboardSection> _getDashboardSections() {
    final sections = <DashboardSection>[];

    // Owner-only sections
    if (widget.role == Role.owner) {
      sections.add(
        DashboardSection(
          title: 'Management',
          icon: Icons.admin_panel_settings,
          color: const Color(0xFF6366F1),
          items: [
            if (_hasPermission(DashboardFeature.createStaff)) ...[
              DashboardItem(
                title: 'Create Staff',
                icon: Icons.person_add,
                onTap: () => _nav(context, const CreateStaffScreen()),
              ),
              DashboardItem(
                title: 'Manage Users',
                icon: Icons.people,
                onTap: () => _navNamed(context, '/manage_users', {
                  'currentUserRole': widget.role.name,
                }),
              ),
            ] else ...[
              DashboardItem(
                title: 'Create Staff',
                icon: Icons.person_add,
                onTap: () => _showRestrictedAccessDialog(
                  DashboardFeature.createStaff,
                  'owner',
                ),
              ),
              DashboardItem(
                title: 'Manage Users',
                icon: Icons.people,
                onTap: () => _showRestrictedAccessDialog(
                  DashboardFeature.manageUsers,
                  'owner',
                ),
              ),
            ],
            DashboardItem(
              title: 'Payment Status',
              icon: Icons.payments,
              onTap: () => _nav(
                context,
                PaymentStatusScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Notification Center',
              icon: Icons.notifications,
              onTap: () => _nav(
                context,
                OwnerNotificationCenter(
                  userId: widget.userId,
                  role: widget.role,
                ),
              ),
            ),
            DashboardItem(
              title: 'Notification Management',
              icon: Icons.send,
              onTap: () => _navNamed(context, '/notification_management', {
                'userRole': widget.role.name,
                'userId': widget.userId,
              }),
            ),
          ],
        ),
      );
    }

    // Director and above sections
    if (widget.role == Role.owner || widget.role == Role.director) {
      sections.add(
        DashboardSection(
          title: 'Team Management',
          icon: Icons.sports_soccer,
          color: const Color(0xFF10B981),
          items: [
            DashboardItem(
              title: 'Players',
              icon: Icons.group,
              onTap: () => _nav(
                context,
                PlayersScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Teams',
              icon: Icons.groups,
              onTap: () => _nav(
                context,
                TeamsScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Training',
              icon: Icons.event,
              onTap: () => _nav(
                context,
                TrainingSessionsScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Attendance',
              icon: Icons.check_circle,
              onTap: () => _nav(
                context,
                AttendanceScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Matches',
              icon: Icons.sports_soccer,
              onTap: () => _nav(
                context,
                MatchesScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Performance',
              icon: Icons.analytics,
              onTap: () => _nav(
                context,
                PlayerPerformanceScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Videos',
              icon: Icons.videocam,
              onTap: () => _nav(
                context,
                VideoListScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Player Progress',
              icon: Icons.trending_up,
              onTap: () => _nav(
                context,
                PlayerProgressManagementScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Admin and above sections
    if (widget.role == Role.owner ||
        widget.role == Role.director ||
        widget.role == Role.admin) {
      sections.add(
        DashboardSection(
          title: 'Analytics',
          icon: Icons.insights,
          color: const Color(0xFFF59E0B),
          items: [
            DashboardItem(
              title: 'Medical Records',
              icon: Icons.medical_services,
              onTap: () => _nav(
                context,
                MedicalRecordsScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            if (_hasPermission(DashboardFeature.analytics)) ...[
              DashboardItem(
                title: 'Analytics',
                icon: Icons.insights,
                onTap: () =>
                    _nav(context, AnalyticsScreen(userRole: widget.role)),
              ),
              DashboardItem(
                title: 'Reports',
                icon: Icons.description,
                onTap: () => _nav(
                  context,
                  ReportsScreen(userRole: widget.role, userId: widget.userId),
                ),
              ),
            ] else ...[
              DashboardItem(
                title: 'Analytics',
                icon: Icons.insights,
                onTap: () => _showRestrictedAccessDialog(
                  DashboardFeature.analytics,
                  'admin',
                ),
              ),
              DashboardItem(
                title: 'Reports',
                icon: Icons.description,
                onTap: () => _showRestrictedAccessDialog(
                  DashboardFeature.reports,
                  'admin',
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Parent-specific sections
    if (widget.role == Role.parent) {
      sections.add(
        DashboardSection(
          title: 'My Children',
          icon: Icons.family_restroom,
          color: const Color(0xFF3B82F6),
          items: [
            DashboardItem(
              title: 'Player Profiles',
              icon: Icons.person,
              onTap: () =>
                  _nav(context, MyChildrenScreen(parentId: widget.userId)),
            ),
            DashboardItem(
              title: 'Training Schedule',
              icon: Icons.calendar_today,
              onTap: () => _nav(
                context,
                TrainingSessionsScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Attendance',
              icon: Icons.check_circle,
              onTap: () => _nav(
                context,
                AttendanceScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Performance',
              icon: Icons.trending_up,
              onTap: () => _nav(
                context,
                PlayerPerformanceScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Match Schedule',
              icon: Icons.event,
              onTap: () => _nav(
                context,
                MatchesScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Match Videos',
              icon: Icons.videocam,
              onTap: () => _nav(
                context,
                VideoListScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
          ],
        ),
      );

      sections.add(
        DashboardSection(
          title: 'Payments',
          icon: Icons.payment,
          color: const Color(0xFF10B981),
          items: [
            DashboardItem(
              title: 'Pay Monthly Fee',
              icon: Icons.payments,
              onTap: () => _nav(
                context,
                ParentPaymentScreen(parentId: widget.userId, parentUser: null),
              ),
            ),
            DashboardItem(
              title: 'Payment History',
              icon: Icons.history,
              onTap: () =>
                  _nav(context, PaymentHistoryScreen(parentId: widget.userId)),
            ),
            DashboardItem(
              title: 'View Receipts',
              icon: Icons.receipt,
              onTap: () =>
                  _nav(context, ReceiptScreen(parentId: widget.userId)),
            ),
          ],
        ),
      );
    }

    // Coach-specific sections
    if (widget.role == Role.coach) {
      sections.add(
        DashboardSection(
          title: 'Coaching Tools',
          icon: Icons.sports_soccer,
          color: const Color(0xFF10B981),
          items: [
            DashboardItem(
              title: 'My Teams',
              icon: Icons.groups,
              onTap: () => _nav(
                context,
                TeamsScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Training Sessions',
              icon: Icons.fitness_center,
              onTap: () => _nav(
                context,
                TrainingSessionsScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Attendance',
              icon: Icons.check_circle,
              onTap: () => _nav(
                context,
                AttendanceScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
            DashboardItem(
              title: 'Performance',
              icon: Icons.analytics,
              onTap: () => _nav(
                context,
                PlayerPerformanceScreen(
                  userRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            ),
            DashboardItem(
              title: 'Match Videos',
              icon: Icons.videocam,
              onTap: () => _nav(
                context,
                VideoListScreen(userRole: widget.role, userId: widget.userId),
              ),
            ),
          ],
        ),
      );
    }

    return sections;
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: widget.role == Role.owner
                  ? const Color(0xFF374151)
                  : AppTheme.onBackgroundColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 12,
              children: [
                _quickActionCard(
                  'Add Player',
                  Icons.person_add,
                  const Color(0xFF6366F1),
                  () => _nav(
                    context,
                    PlayersScreen(userRole: widget.role, userId: widget.userId),
                  ),
                ),
                _quickActionCard(
                  'Schedule Match',
                  Icons.event_note,
                  const Color(0xFF10B981),
                  () => _nav(
                    context,
                    MatchesScreen(userRole: widget.role, userId: widget.userId),
                  ),
                ),
                _quickActionCard(
                  'View Reports',
                  Icons.assessment,
                  const Color(0xFFF59E0B),
                  () => _nav(
                    context,
                    ReportsScreen(userRole: widget.role, userId: widget.userId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: widget.role == Role.owner
                    ? const Color(0xFF374151)
                    : AppTheme.onBackgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(DashboardSection section) {
    final isOwner = widget.role == Role.owner;

    return Container(
      margin: EdgeInsets.only(bottom: isOwner ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isOwner ? 20 : 0,
              vertical: isOwner ? 16 : 0,
            ),
            decoration: isOwner
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: isOwner ? 40 : 32,
                  height: isOwner ? 40 : 32,
                  decoration: BoxDecoration(
                    color: isOwner
                        ? const Color(0xFF3B82F6)
                        : section.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isOwner ? 12 : 8),
                    border: isOwner
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          )
                        : null,
                    boxShadow: isOwner
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    section.icon,
                    color: isOwner ? Colors.white : section.color,
                    size: isOwner ? 22 : 18,
                  ),
                ),
                SizedBox(width: isOwner ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          color: isOwner
                              ? const Color(0xFF374151)
                              : AppTheme.onBackgroundColor,
                          fontSize: isOwner ? 18 : 16,
                          fontWeight: isOwner
                              ? FontWeight.w800
                              : FontWeight.w600,
                          letterSpacing: isOwner ? -0.4 : -0.5,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Exclusive owner features',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'OWNER',
                      style: TextStyle(
                        color: const Color(0xFF3B82F6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: isOwner ? 24 : 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              mainAxisSpacing: isOwner ? 16 : 12,
              crossAxisSpacing: isOwner ? 16 : 12,
              childAspectRatio: isOwner ? 1.0 : 1.2,
            ),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _dashboardItem(item, section.color);
            },
          ),
        ],
      ),
    );
  }

  Widget _dashboardItem(DashboardItem item, Color sectionColor) {
    final isOwner = widget.role == Role.owner;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: null,
          color: isOwner
              ? const Color(0xFFEFF6FF)
              : sectionColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(isOwner ? 24 : 16),
          border: isOwner
              ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
              : Border.all(
                  color: AppTheme.outlineColor.withValues(alpha: 0.2),
                  width: 1,
                ),
          boxShadow: isOwner
              ? [
                  BoxShadow(
                    color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Container(
          padding: EdgeInsets.all(isOwner ? 16 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isOwner ? 48 : 48,
                height: isOwner ? 48 : 48,
                decoration: BoxDecoration(
                  color: isOwner
                      ? const Color(0xFF3B82F6)
                      : sectionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isOwner ? 16 : 12),
                  border: isOwner
                      ? Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: isOwner ? Colors.white : Colors.white,
                    size: isOwner ? 28 : 24,
                  ),
                ),
              ),
              SizedBox(height: isOwner ? 12 : 12),
              Text(
                item.title,
                style: TextStyle(
                  color: isOwner
                      ? const Color(0xFF374151)
                      : AppTheme.onBackgroundColor,
                  fontSize: isOwner ? 13 : 13,
                  fontWeight: isOwner ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isOwner ? -0.3 : 0,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _navNamed(
    BuildContext context,
    String route,
    Map<String, dynamic>? args,
  ) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  void _showRestrictedAccessDialog(
    DashboardFeature feature,
    String requiredRole,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Access Restricted'),
        content: Text(
          'The "${feature.featureDisplayName}" feature is only available to users with $requiredRole role or higher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOwnerLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role == Role.owner;

    return Scaffold(
      backgroundColor: isOwner
          ? const Color(0xFFF5F5F5)
          : AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          DashboardHeader(
            role: widget.role,
            fadeAnimation: _fadeAnimation,
            slideAnimation: _slideAnimation,
            onLogout: () => _showOwnerLogoutDialog(context),
            showLogoutButton: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActions(),
                        ..._getDashboardSections().map(_buildDashboardSection),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<DashboardItem> items;

  DashboardSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DashboardItem({required this.title, required this.icon, required this.onTap});
}
