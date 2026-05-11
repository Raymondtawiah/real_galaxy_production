import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';

class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? percentage;
  final String? subtitle;

  const StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.percentage,
    this.subtitle,
  });
}

class OwnerStatsOverview extends StatelessWidget {
  final List<StatItem> stats;
  final Role role;

  const OwnerStatsOverview({
    super.key,
    required this.stats,
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
                    Icons.analytics,
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
                        'Overview',
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
                          'Key metrics at a glance',
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
                      'STATS',
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              mainAxisSpacing: isOwner ? 16 : 12,
              crossAxisSpacing: isOwner ? 16 : 12,
              childAspectRatio: 1.2,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
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
                child: Padding(
                  padding: EdgeInsets.all(isOwner ? 16 : 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isOwner ? 40 : 32,
                        height: isOwner ? 40 : 32,
                        decoration: BoxDecoration(
                          color: stat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isOwner ? 10 : 8),
                          border: isOwner
                              ? Border.all(
                                  color: stat.color.withValues(alpha: 0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Icon(
                          stat.icon,
                          color: stat.color,
                          size: isOwner ? 20 : 16,
                        ),
                      ),
                      SizedBox(height: isOwner ? 12 : 8),
                      Text(
                        stat.value,
                        style: TextStyle(
                          color: isOwner
                              ? const Color(0xFF374151)
                              : Colors.white,
                          fontSize: isOwner ? 24 : 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: isOwner ? 4 : 2),
                      Text(
                        stat.title,
                        style: TextStyle(
                          color: isOwner
                              ? const Color(0xFF64748B)
                              : Colors.white70,
                          fontSize: isOwner ? 12 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (stat.subtitle != null) ...[
                        SizedBox(height: isOwner ? 4 : 2),
                        Text(
                          stat.subtitle!,
                          style: TextStyle(
                            color: isOwner
                                ? const Color(0xFF94A3B8)
                                : Colors.white54,
                            fontSize: isOwner ? 10 : 8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (stat.percentage != null) ...[
                        SizedBox(height: isOwner ? 8 : 4),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: stat.percentage! / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: stat.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
