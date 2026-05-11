import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';

class DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const DashboardItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });
}

class OwnerDashboardItem extends StatelessWidget {
  final DashboardItem item;
  final Color sectionColor;
  final Role role;

  const OwnerDashboardItem({
    super.key,
    required this.item,
    required this.sectionColor,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: null,
          color: isOwner
              ? (item.isPrimary
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF8FAFC))
              : (item.isPrimary
                  ? sectionColor.withValues(alpha: 0.15)
                  : Colors.white),
          borderRadius: BorderRadius.circular(isOwner ? 24 : 16),
          border: isOwner
              ? Border.all(
                  color: item.isPrimary
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                      : const Color(0xFFE2E8F0),
                  width: item.isPrimary ? 2 : 1.5,
                )
              : Border.all(
                  color: item.isPrimary
                      ? sectionColor.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: item.isPrimary ? 1.5 : 1,
                ),
          boxShadow: isOwner
              ? [
                  BoxShadow(
                    color: item.isPrimary
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                        : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                    blurRadius: item.isPrimary ? 24 : 16,
                    offset: item.isPrimary
                        ? const Offset(0, 12)
                        : const Offset(0, 6),
                  ),
                  if (item.isPrimary)
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                ]
              : [
                  BoxShadow(
                    color: isOwner 
                        ? const Color(0xFFE5E7EB).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
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
                      ? (item.isPrimary
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFEFF6FF))
                      : (item.isPrimary
                          ? sectionColor
                          : sectionColor.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(isOwner ? 16 : 12),
                  border: isOwner && !item.isPrimary
                      ? Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        item.icon,
                        color: isOwner
                            ? (item.isPrimary
                                ? Colors.white
                                : const Color(0xFF3B82F6))
                            : (item.isPrimary ? Colors.white : sectionColor),
                        size: isOwner ? 28 : 24,
                      ),
                    ),
                    if (isOwner && item.isPrimary)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isOwner ? 12 : 12),
              Text(
                item.title,
                style: TextStyle(
                  color: isOwner
                      ? const Color(0xFF374151)
                      : Colors.white,
                  fontSize: isOwner ? 13 : 13,
                  fontWeight: isOwner
                      ? FontWeight.w700
                      : (item.isPrimary ? FontWeight.w600 : FontWeight.w500),
                  letterSpacing: isOwner ? -0.3 : 0,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isOwner && item.isPrimary) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
