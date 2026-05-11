import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_logo.dart';
import 'package:real_galaxy/components/owner_badge.dart';
import 'package:real_galaxy/models/role.dart';

class OwnerHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool showLogo;
  final bool showBadge;
  final VoidCallback? onLogout;
  final Role role;

  const OwnerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.showLogo = true,
    this.showBadge = true,
    this.onLogout,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return Row(
      children: [
        if (isOwner && showLogo) ...[
          const OwnerLogo.medium(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isOwner ? 32 : 28,
                        fontWeight: isOwner ? FontWeight.w800 : FontWeight.bold,
                        color: isOwner ? const Color(0xFF374151) : Colors.white,
                        letterSpacing: isOwner ? -0.5 : 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isOwner && showBadge) ...[
                    const SizedBox(width: 8),
                    const OwnerBadge.pro(),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: isOwner
                            ? const Color(0xFF64748B)
                            : Colors.white70,
                        fontSize: isOwner ? 16 : 14,
                        fontWeight: isOwner
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isOwner && badgeText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (isOwner && onLogout != null) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const OwnerBadge.small(),
                const SizedBox(width: 8),
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
            ),
          ),
        ],
      ],
    );
  }
}
