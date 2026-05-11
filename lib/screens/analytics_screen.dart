import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/services/analytics_service.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  final Role userRole;

  const AnalyticsScreen({super.key, required this.userRole});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic> _overview = {};
  Map<String, double> _monthlyTrend = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      _overview = await _analyticsService.getAcademyOverview();
      _monthlyTrend = await _analyticsService.getMonthlyTrend(
        DateTime.now().year,
      );
      final trainingRate = await _analyticsService.getTrainingAttendanceRate();
      _overview['trainingAttendance'] = trainingRate;
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academy Overview',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Players',
                          '${_overview['totalPlayers'] ?? 0}',
                          Icons.people,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Teams',
                          '${_overview['totalTeams'] ?? 0}',
                          Icons.group,
                          AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Revenue',
                          '₵${NumberFormat('#,###').format(_overview['totalRevenue'] ?? 0)}',
                          Icons.attach_money,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pending Payments',
                          '${_overview['pendingPayments'] ?? 0}',
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Financial Overview',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Monthly Revenue Trend (GHS)',
                            style: TextStyle(color: AppTheme.onBackgroundMuted),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(height: 150, child: _buildBarChart()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (widget.userRole == Role.owner ||
                      widget.userRole == Role.director) ...[
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        color: AppTheme.onBackgroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildQuickStat(
                              'Active Players',
                              '${_overview['totalPlayers'] ?? 0}',
                            ),
                            _buildQuickStat(
                              'Training Attendance',
                              '${(_overview['trainingAttendance'] ?? 0).toStringAsFixed(1)}%',
                            ),
                            _buildQuickStat(
                              'Payment Collection Rate',
                              '${((_overview['totalRevenue'] ?? 0) / ((_overview['totalRevenue'] ?? 0) + (_overview['pendingPayments'] ?? 0)) * 100).toStringAsFixed(1)}%',
                            ),
                            _buildQuickStat(
                              'Total Revenue YTD',
                              '₵${NumberFormat('#,###').format(_overview['totalRevenue'] ?? 0)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.onBackgroundColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.onBackgroundSubtle,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final maxValue = _monthlyTrend.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (index) {
        final value = _monthlyTrend['${index + 1}'] ?? 0;
        final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 20,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              months[index],
              style: const TextStyle(
                color: AppTheme.onBackgroundFaint,
                fontSize: 9,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.onBackgroundMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onBackgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
