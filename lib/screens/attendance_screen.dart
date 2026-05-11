import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/training_session.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/attendance.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class AttendanceScreen extends StatefulWidget {
  final Role userRole;
  final String userId;
  final String? assignedTeamId;

  const AttendanceScreen({
    super.key,
    required this.userRole,
    required this.userId,
    this.assignedTeamId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<TrainingSession> _sessions = [];
  List<Team> _teams = [];
  List<Player> _players = [];
  final Map<String, Map<String, AttendanceStatus>> _attendanceMap = {};
  bool _isLoading = true;
  TrainingSession? _selectedSession;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _teams = await _firebaseService.getAllTeams();
      _players = await _firebaseService.getAllPlayers();

      if (widget.assignedTeamId != null) {
        _sessions = await _firebaseService.getTrainingSessionsByTeam(
          widget.assignedTeamId!,
        );
        _players = await _firebaseService.getPlayersByTeam(
          widget.assignedTeamId!,
        );
        if (_sessions.isNotEmpty) {
          final teamIds = _sessions.map((s) => s.teamId).toSet();
          for (var teamId in teamIds) {
            final teamPlayers = await _firebaseService.getPlayersByTeam(teamId);
            _players.addAll(teamPlayers);
          }
          _players = _players.toSet().toList();
          _selectedSession = _sessions.first;
        }
      } else {
        _sessions = await _firebaseService.getAllTrainingSessions();
        _players = await _firebaseService.getAllPlayers();
      }

      _sessions.sort((a, b) => b.date.compareTo(a.date));

      if (_selectedSession != null) {
        await _loadAttendance(_selectedSession!.id!);
      }
    } catch (e) {
      print('Error loading attendance data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendance(String sessionId) async {
    try {
      final records = await _firebaseService.getAttendanceBySession(sessionId);
      final map = <String, AttendanceStatus>{};
      for (var record in records) {
        map[record.playerId] = record.status;
      }
      setState(() {
        _attendanceMap[sessionId] = map;
      });
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  Future<void> _markAttendance(Player player, AttendanceStatus status) async {
    if (_selectedSession?.id == null) return;

    final now = DateTime.now();
    final sessionTime = _selectedSession!.date;

    // Allow attendance marking within 30 minutes before or 2 hours after session start
    final windowStart = sessionTime.subtract(const Duration(minutes: 30));
    final windowEnd = sessionTime.add(const Duration(hours: 2));

    if (now.isBefore(windowStart)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Attendance can only be marked 30 minutes before the session starts',
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
      return;
    }

    if (now.isAfter(windowEnd)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Attendance marking has closed (2 hours after session)',
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
      return;
    }

    try {
      final attendance = Attendance(
        playerId: player.id!,
        sessionId: _selectedSession!.id!,
        status: status,
      );
      await _firebaseService.recordAttendance(attendance);
      setState(() {
        _attendanceMap[_selectedSession!.id!] ??= {};
        _attendanceMap[_selectedSession!.id!]![player.id!] = status;
      });
    } catch (e) {
      print('Error marking attendance: $e');
    }
  }

  String _getTeamName(String teamId) {
    final teams = _teams.where((t) => t.id == teamId).toList();
    return teams.isNotEmpty ? teams.first.name : 'Unknown';
  }

  AttendanceStatus? _getPlayerStatus(String playerId) {
    if (_selectedSession?.id == null) return null;
    return _attendanceMap[_selectedSession!.id!]?[playerId];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                if (_sessions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedSession?.id,
                      dropdownColor: AppTheme.surfaceVariantColor,
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                      decoration: InputDecoration(
                        labelText: 'Select Session',
                        labelStyle: const TextStyle(
                          color: AppTheme.onBackgroundMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _sessions.map((s) {
                        final teamName = _getTeamName(s.teamId);
                        final dateStr = s.date.toLocal().toString().split(
                          ' ',
                        )[0];
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('$teamName - $dateStr'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          final filtered = _sessions
                              .where((s) => s.id == value)
                              .toList();
                          _selectedSession = filtered.isNotEmpty
                              ? filtered.first
                              : null;
                        });
                        if (value != null) {
                          _loadAttendance(value);
                        }
                      },
                    ),
                  ),
                if (_selectedSession != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          'Present',
                          _players
                              .where(
                                (p) =>
                                    _getPlayerStatus(p.id!) ==
                                        AttendanceStatus.present &&
                                    p.medicalClearance,
                              )
                              .length,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          'Absent',
                          _players
                              .where(
                                (p) =>
                                    _getPlayerStatus(p.id!) ==
                                        AttendanceStatus.absent &&
                                    p.medicalClearance,
                              )
                              .length,
                          Colors.red,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          'Late',
                          _players
                              .where(
                                (p) =>
                                    _getPlayerStatus(p.id!) ==
                                        AttendanceStatus.late &&
                                    p.medicalClearance,
                              )
                              .length,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedSession == null
                      ? const Center(
                          child: Text(
                            'No training session selected',
                            style: TextStyle(
                              color: AppTheme.onBackgroundSubtle,
                            ),
                          ),
                        )
                      : _players.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_off,
                                size: 64,
                                color: AppTheme.onBackgroundFaint,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No players in this team',
                                style: TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            final player = _players[index];
                            final status = _getPlayerStatus(player.id!);

                            return Card(
                              color: AppTheme.surfaceColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(
                                        0xFFDC143C,
                                      ).withValues(alpha: 0.2),
                                      backgroundImage:
                                          player.imageUrl != null &&
                                              player.imageUrl!.isNotEmpty
                                          ? NetworkImage(player.imageUrl!)
                                          : null,
                                      child:
                                          player.imageUrl != null &&
                                              player.imageUrl!.isNotEmpty
                                          ? null
                                          : Text(
                                              player.name
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.name,
                                            style: const TextStyle(
                                              color: AppTheme.onBackgroundColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Position: ${player.position ?? "N/A"}',
                                            style: const TextStyle(
                                              color:
                                                  AppTheme.onBackgroundSubtle,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusButton(
                                      player,
                                      AttendanceStatus.present,
                                      status == AttendanceStatus.present,
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                    _buildStatusButton(
                                      player,
                                      AttendanceStatus.late,
                                      status == AttendanceStatus.late,
                                      Icons.access_time,
                                      Colors.orange,
                                    ),
                                    _buildStatusButton(
                                      player,
                                      AttendanceStatus.absent,
                                      status == AttendanceStatus.absent,
                                      Icons.cancel,
                                      Colors.red,
                                    ),
                                  ],
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

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    Player player,
    AttendanceStatus status,
    bool isSelected,
    IconData icon,
    Color color,
  ) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? color : AppTheme.onBackgroundFaint),
      onPressed: () => _markAttendance(player, status),
    );
  }
}
