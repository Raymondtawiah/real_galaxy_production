import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_logo.dart';
import 'package:real_galaxy/components/owner_badge.dart';
import 'package:real_galaxy/models/role.dart';

class OwnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Role role;
  final VoidCallback? onLogout;
  final List<Widget>? actions;
  final bool showLogo;
  final bool showBadge;
  final Color? backgroundColor;

  const OwnerAppBar({
    super.key,
    required this.title,
    required this.role,
    this.onLogout,
    this.actions,
    this.showLogo = true,
    this.showBadge = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return AppBar(
      title: Row(
        children: [
          if (isOwner && showLogo) ...[
            const OwnerLogo.small(),
            const SizedBox(width: 12),
          ],
          if (isOwner && showBadge) ...[
            const OwnerBadge.small(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isOwner ? 18 : 16,
                fontWeight: isOwner ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? (isOwner ? const Color(0xFFDC143C) : const Color(0xFFDC143C)),
      elevation: isOwner ? 4 : 0,
      actions: [
        if (isOwner && onLogout != null)
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
        ...?actions,
      ],
    );
  }
}
