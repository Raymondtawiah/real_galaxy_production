import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_logo.dart';
import 'package:real_galaxy/models/role.dart';

class DashboardHeader extends StatelessWidget {
  final Role role;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback? onLogout;
  final bool showLogoutButton;

  const DashboardHeader({
    super.key,
    required this.role,
    required this.fadeAnimation,
    required this.slideAnimation,
    this.onLogout,
    this.showLogoutButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return SliverAppBar(
      expandedHeight: isOwner ? 220 : 200,
      floating: false,
      pinned: true,
      backgroundColor: isOwner
          ? const Color(0xFFDC143C)
          : const Color(0xFFDC143C),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFDC143C),
                const Color(0xFFDC143C).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Container(
                      width: isOwner ? 80 : 80,
                      height: isOwner ? 80 : 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: isOwner
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFFDC143C,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: const OwnerLogo.medium(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                role.displayName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isOwner ? 28 : 24,
                                  fontWeight: isOwner
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  letterSpacing: isOwner ? -0.6 : -0.5,
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: const Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWelcomeMessage(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: isOwner ? 15 : 14,
                              fontWeight: isOwner
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Full Access • Premium Features',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                return const Icon(Icons.person, color: Colors.white, size: 32);
              },
            ),
          ),
          onSelected: (String value) {
            switch (value) {
              case 'profile':
                Navigator.of(context).pushNamed('/profile');
                break;
              case 'logout':
                onLogout?.call();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFDC143C)),
                  const SizedBox(width: 8),
                  const Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Color(0xFFDC143C)),
                  const SizedBox(width: 8),
                  const Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getWelcomeMessage() {
    switch (role) {
      case Role.owner:
        return 'Welcome back, Owner';
      case Role.director:
        return 'Welcome back, Director';
      case Role.admin:
        return 'Welcome back, Admin';
      case Role.coach:
        return 'Welcome back, Coach';
      case Role.parent:
        return 'Welcome back, Parent';
    }
  }
}
