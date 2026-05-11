import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_dashboard_layout.dart';
import 'package:real_galaxy/components/owner_dashboard_section.dart';
import 'package:real_galaxy/components/owner_dashboard_item.dart';
import 'package:real_galaxy/components/owner_quick_actions.dart';
import 'package:real_galaxy/components/owner_stats_overview.dart';
import 'package:real_galaxy/models/role.dart';

class OwnerDashboardExample extends StatelessWidget {
  const OwnerDashboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Define quick actions
    final quickActions = [
      QuickAction(
        title: 'Create Staff',
        icon: Icons.person_add,
        onTap: () => Navigator.pushNamed(context, '/create-staff'),
        color: const Color(0xFF3B82F6),
      ),
      QuickAction(
        title: 'Add Player',
        icon: Icons.person,
        onTap: () => Navigator.pushNamed(context, '/add-player'),
        color: const Color(0xFF10B981),
      ),
      QuickAction(
        title: 'Schedule Match',
        icon: Icons.event,
        onTap: () => Navigator.pushNamed(context, '/schedule-match'),
        color: const Color(0xFFDC143C),
      ),
      QuickAction(
        title: 'View Analytics',
        icon: Icons.analytics,
        onTap: () => Navigator.pushNamed(context, '/analytics'),
        color: const Color(0xFF8B5CF6),
      ),
    ];

    // Define stats
    final stats = [
      StatItem(
        title: 'Total Players',
        value: '156',
        icon: Icons.people,
        color: const Color(0xFF3B82F6),
        percentage: 85,
        subtitle: '+12 this month',
      ),
      StatItem(
        title: 'Active Staff',
        value: '24',
        icon: Icons.badge,
        color: const Color(0xFF10B981),
        percentage: 92,
        subtitle: 'All departments',
      ),
      StatItem(
        title: 'This Month',
        value: '8',
        icon: Icons.event,
        color: const Color(0xFFDC143C),
        percentage: 67,
        subtitle: 'Matches scheduled',
      ),
      StatItem(
        title: 'Revenue',
        value: '\$12.5k',
        icon: Icons.attach_money,
        color: const Color(0xFF8B5CF6),
        percentage: 78,
        subtitle: '+15% growth',
      ),
    ];

    // Define dashboard sections
    final sections = [
      DashboardSection(
        title: 'Management',
        icon: Icons.settings,
        color: const Color(0xFF3B82F6),
        items: [
          DashboardItem(
            title: 'Create Staff',
            icon: Icons.person_add,
            onTap: () => Navigator.pushNamed(context, '/create-staff'),
            isPrimary: true,
          ),
          DashboardItem(
            title: 'Manage Users',
            icon: Icons.people,
            onTap: () => Navigator.pushNamed(context, '/manage-users'),
          ),
          DashboardItem(
            title: 'Add Player',
            icon: Icons.person,
            onTap: () => Navigator.pushNamed(context, '/add-player'),
            isPrimary: true,
          ),
          DashboardItem(
            title: 'Team Roster',
            icon: Icons.group,
            onTap: () => Navigator.pushNamed(context, '/team-roster'),
          ),
        ],
      ),
      DashboardSection(
        title: 'Operations',
        icon: Icons.build,
        color: const Color(0xFF10B981),
        items: [
          DashboardItem(
            title: 'Schedule Match',
            icon: Icons.event,
            onTap: () => Navigator.pushNamed(context, '/schedule-match'),
            isPrimary: true,
          ),
          DashboardItem(
            title: 'Training Sessions',
            icon: Icons.fitness_center,
            onTap: () => Navigator.pushNamed(context, '/training'),
          ),
          DashboardItem(
            title: 'Attendance',
            icon: Icons.check_circle,
            onTap: () => Navigator.pushNamed(context, '/attendance'),
          ),
          DashboardItem(
            title: 'Performance',
            icon: Icons.trending_up,
            onTap: () => Navigator.pushNamed(context, '/performance'),
            isPrimary: true,
          ),
        ],
      ),
      DashboardSection(
        title: 'Analytics',
        icon: Icons.analytics,
        color: const Color(0xFF8B5CF6),
        items: [
          DashboardItem(
            title: 'View Analytics',
            icon: Icons.bar_chart,
            onTap: () => Navigator.pushNamed(context, '/analytics'),
            isPrimary: true,
          ),
          DashboardItem(
            title: 'Reports',
            icon: Icons.description,
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
          DashboardItem(
            title: 'Payment Status',
            icon: Icons.payment,
            onTap: () => Navigator.pushNamed(context, '/payments'),
          ),
          DashboardItem(
            title: 'Medical Records',
            icon: Icons.local_hospital,
            onTap: () => Navigator.pushNamed(context, '/medical'),
          ),
        ],
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Dashboard'),
            backgroundColor: const Color(0xFFDC143C),
            elevation: 4,
            actions: [
              IconButton(
                onPressed: () => _showLogoutDialog(context),
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
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                OwnerStatsOverview(stats: stats, role: Role.owner),
                OwnerQuickActions(actions: quickActions, role: Role.owner),
                ...sections.map((section) {
                  return OwnerDashboardSection(
                    section: section,
                    role: Role.owner,
                  );
                }),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-staff'),
        backgroundColor: const Color(0xFFDC143C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
