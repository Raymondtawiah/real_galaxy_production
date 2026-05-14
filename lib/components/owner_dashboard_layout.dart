import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_header.dart';
import 'package:real_galaxy/components/owner_dashboard_section.dart';
import 'package:real_galaxy/components/owner_quick_actions.dart';
import 'package:real_galaxy/components/owner_logo.dart';
import 'package:real_galaxy/components/owner_badge.dart';
import 'package:real_galaxy/models/role.dart';

class OwnerDashboardLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final List<DashboardSection> sections;
  final List<QuickAction> quickActions;
  final Role role;
  final VoidCallback? onLogout;
  final Widget? floatingActionButton;
  final bool showQuickActions;
  final bool showHeader;

  const OwnerDashboardLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.sections,
    required this.quickActions,
    required this.role,
    this.onLogout,
    this.floatingActionButton,
    this.showQuickActions = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return Scaffold(
      backgroundColor: isOwner
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF000000),
      appBar: AppBar(
        title: Row(
          children: [
            if (isOwner) ...[
              const OwnerBadge.small(),
              const SizedBox(width: 12),
            ],
            Text(title),
          ],
        ),
        backgroundColor: isOwner
            ? const Color(0xFFDC143C)
            : const Color(0xFFDC143C),
        elevation: isOwner ? 4 : 0,
        actions: [
          if (isOwner && onLogout != null) ...[
            IconButton(
              onPressed: onLogout,
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
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (isOwner && showHeader)
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: false,
              backgroundColor: const Color(0xFFDC143C),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDC143C),
                        Color(0xFFDC143C),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const OwnerLogo.large(),
                          const SizedBox(height: 16),
                          Text(
                            role.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome back, Owner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Full Access • Premium Features',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.all(isOwner ? 20 : 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!isOwner && showHeader) ...[
                  OwnerHeader(
                    title: title,
                    subtitle: subtitle,
                    badgeText: badgeText,
                    showLogo: true,
                    showBadge: true,
                    role: role,
                  ),
                  const SizedBox(height: 32),
                ],
                if (showQuickActions && quickActions.isNotEmpty) ...[
                  OwnerQuickActions(
                    actions: quickActions,
                    role: role,
                  ),
                ],
                ...sections.map((section) {
                  return OwnerDashboardSection(
                    section: section,
                    role: role,
                  );
                }),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
