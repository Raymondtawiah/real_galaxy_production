import 'package:flutter/material.dart';
import 'package:real_galaxy/components/owner_dashboard_item.dart';
import 'package:real_galaxy/models/role.dart';

class DashboardSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<DashboardItem> items;

  const DashboardSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class OwnerDashboardSection extends StatelessWidget {
  final DashboardSection section;
  final Role role;

  const OwnerDashboardSection({
    super.key,
    required this.section,
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
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
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
                              : Colors.white,
                          fontSize: isOwner ? 18 : 16,
                          fontWeight: isOwner ? FontWeight.w800 : FontWeight.w600,
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
              return OwnerDashboardItem(
                item: item,
                sectionColor: section.color,
                role: role,
              );
            },
          ),
        ],
      ),
    );
  }
}
