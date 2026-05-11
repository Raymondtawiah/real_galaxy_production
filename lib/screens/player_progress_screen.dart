import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/match.dart';
import 'package:real_galaxy/models/training_session.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/fcm_service.dart';

class PlayerProgressScreen extends StatefulWidget {
  final String playerId;
  final Role userRole;
  final String userId;

  const PlayerProgressScreen({
    super.key,
    required this.playerId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PlayerProgressScreen> createState() => _PlayerProgressScreenState();
}

class _PlayerProgressScreenState extends State<PlayerProgressScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FCMService _fcmService = FCMService();

  Player? _player;
  List<Match> _matches = [];
  List<TrainingSession> _trainingSessions = [];
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _player = await _firebaseService.getPlayer(widget.playerId);
      _matches = await _firebaseService.getAllMatches();
      _trainingSessions = await _firebaseService.getAllTrainingSessions();

      // Filter matches and sessions for this player
      _matches = _matches
          .where(
            (match) =>
                match.homeStartingPlayers.contains(widget.playerId) ||
                match.homeSubstitutes.contains(widget.playerId) ||
                match.awayStartingPlayers.contains(widget.playerId) ||
                match.awaySubstitutes.contains(widget.playerId),
          )
          .toList();
      _trainingSessions = _trainingSessions
          .where((session) => session.teamId == _player?.teamId)
          .toList();

      // Load attendance data
      _attendanceData = await _loadAttendanceData();
    } catch (e) {
      print('Error loading player progress: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _loadAttendanceData() async {
    // This would load attendance records for the player
    // For now, return mock data
    return [
      {'date': '2024-01-15', 'status': 'present', 'type': 'training'},
      {'date': '2024-01-16', 'status': 'present', 'type': 'match'},
      {'date': '2024-01-17', 'status': 'absent', 'type': 'training'},
      {'date': '2024-01-18', 'status': 'present', 'type': 'training'},
      {'date': '2024-01-19', 'status': 'late', 'type': 'match'},
    ];
  }

  double get _attendanceRate {
    if (_attendanceData.isEmpty) return 0.0;
    final presentCount = _attendanceData
        .where((d) => d['status'] == 'present' || d['status'] == 'late')
        .length;
    return (presentCount / _attendanceData.length) * 100;
  }

  int get _totalMatches => _matches.length;
  int get _totalTraining => _trainingSessions.length;
  int get _goalsScored {
    int goals = 0;
    for (final match in _matches) {
      for (final event in match.events) {
        if (event['player_id'] == widget.playerId &&
            event['event_type'] == 'goal') {
          goals++;
        }
      }
    }
    return goals;
  }

  Future<void> _sendProgressNotification() async {
    if (_player == null) return;

    try {
      await _fcmService.sendProgressUpdate(
        playerId: widget.playerId,
        playerName: _player!.name,
        attendanceRate: _attendanceRate,
        matchesPlayed: _totalMatches,
        goalsScored: _goalsScored,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress notification sent to parents'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_player?.name ?? 'Player Progress'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.userRole == Role.owner ||
              widget.userRole == Role.director ||
              widget.userRole == Role.admin)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: _sendProgressNotification,
              tooltip: 'Send Progress Notification',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.sports_soccer), text: 'Performance'),
            Tab(icon: Icon(Icons.event), text: 'Attendance'),
            Tab(icon: Icon(Icons.trending_up), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _player == null
          ? const Center(child: Text('Player not found'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildAttendanceTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _player!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Age: ${_calculateAge(_player!.dateOfBirth ?? DateTime.now())} years',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Position: ${_player!.position ?? "Not specified"}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatusChip(
                      'Medical Clearance',
                      _player!.medicalClearance ? 'Cleared' : 'Not Cleared',
                      _player!.medicalClearance ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      'Active',
                      _player!.isActive ? 'Yes' : 'No',
                      _player!.isActive ? Colors.blue : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Attendance Rate',
                '${_attendanceRate.toStringAsFixed(1)}%',
                Icons.pie_chart,
                Colors.green,
              ),
              _buildStatCard(
                'Matches Played',
                '$_totalMatches',
                Icons.sports_soccer,
                Colors.blue,
              ),
              _buildStatCard(
                'Training Sessions',
                '$_totalTraining',
                Icons.fitness_center,
                Colors.orange,
              ),
              _buildStatCard(
                'Goals Scored',
                '$_goalsScored',
                Icons.emoji_events,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_matches.isEmpty)
            const Center(
              child: Text(
                'No matches recorded yet',
                style: TextStyle(color: AppTheme.onBackgroundMuted),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text('Match vs ${match.awayTeamId}'),
                    subtitle: Text(
                      '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Home',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
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

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: Column(
              children: [
                const Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onBackgroundColor,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _attendanceRate / 100,
                  backgroundColor: AppTheme.outlineColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _attendanceRate >= 80
                        ? Colors.green
                        : _attendanceRate >= 60
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_attendanceRate.toStringAsFixed(1)}% Attendance Rate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _attendanceRate >= 80
                        ? Colors.green
                        : _attendanceRate >= 60
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Attendance
          const Text(
            'Recent Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_attendanceData.isEmpty)
            const Center(
              child: Text(
                'No attendance records found',
                style: TextStyle(color: AppTheme.onBackgroundMuted),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceData.length,
              itemBuilder: (context, index) {
                final record = _attendanceData[index];
                Color statusColor;
                IconData statusIcon;

                switch (record['status']) {
                  case 'present':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'late':
                    statusColor = Colors.orange;
                    statusIcon = Icons.access_time;
                    break;
                  case 'absent':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(record['date']),
                    subtitle: Text(record['type']),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        record['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),

          // Performance Metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: Column(
              children: [
                _buildMetricRow('Consistency', '85%', Colors.green),
                _buildMetricRow('Skill Development', '78%', Colors.blue),
                _buildMetricRow('Teamwork', '92%', Colors.purple),
                _buildMetricRow('Discipline', '88%', Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress Areas
          const Text(
            'Areas of Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildProgressArea('Technical Skills', 0.8),
              _buildProgressArea('Physical Fitness', 0.75),
              _buildProgressArea('Tactical Understanding', 0.85),
              _buildProgressArea('Mental Strength', 0.9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onBackgroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.onBackgroundColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressArea(String area, double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onBackgroundColor,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progress >= 0.8
                        ? Colors.green
                        : progress >= 0.6
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.outlineColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.8
                    ? Colors.green
                    : progress >= 0.6
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
