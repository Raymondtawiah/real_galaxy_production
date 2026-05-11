import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';

class QuickAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class OwnerQuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  final Role role;

  const OwnerQuickActions({
    super.key,
    required this.actions,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return Container(
      margin: EdgeInsets.only(bottom: isOwner ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isOwner ? 20 : 16,
              vertical: isOwner ? 16 : 12,
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
                        : Colors.white.withValues(alpha: 0.2),
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
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: isOwner ? Colors.white : const Color(0xFFDC143C),
                    size: isOwner ? 22 : 18,
                  ),
                ),
                SizedBox(width: isOwner ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: isOwner
                              ? const Color(0xFF374151)
                              : Colors.white,
                          fontSize: isOwner ? 18 : 16,
                          fontWeight: isOwner ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: isOwner ? -0.4 : -0.5,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Frequently used features',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'QUICK',
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
          SizedBox(height: isOwner ? 20 : 16),
          SizedBox(
            height: isOwner ? 120 : 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isOwner ? 20 : 16),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return Container(
                  width: isOwner ? 140 : 120,
                  margin: EdgeInsets.only(right: isOwner ? 16 : 12),
                  decoration: BoxDecoration(
                    color: isOwner
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isOwner ? 16 : 12),
                    border: isOwner
                        ? Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          )
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                    boxShadow: isOwner
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(isOwner ? 16 : 12),
                      child: Padding(
                        padding: EdgeInsets.all(isOwner ? 16 : 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isOwner ? 48 : 40,
                              height: isOwner ? 48 : 40,
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? (action.color ?? const Color(0xFF3B82F6))
                                        .withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(isOwner ? 12 : 8),
                                border: isOwner
                                    ? Border.all(
                                        color: (action.color ?? const Color(0xFF3B82F6))
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                action.icon,
                                color: isOwner
                                    ? (action.color ?? const Color(0xFF3B82F6))
                                    : const Color(0xFFDC143C),
                                size: isOwner ? 24 : 20,
                              ),
                            ),
                            SizedBox(height: isOwner ? 12 : 8),
                            Text(
                              action.title,
                              style: TextStyle(
                                color: isOwner
                                    ? const Color(0xFF374151)
                                    : Colors.white,
                                fontSize: isOwner ? 14 : 12,
                                fontWeight: isOwner ? FontWeight.w600 : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
