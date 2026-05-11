import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/training_session.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class TrainingSessionsScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const TrainingSessionsScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<TrainingSessionsScreen> createState() => _TrainingSessionsScreenState();
}

class _TrainingSessionsScreenState extends State<TrainingSessionsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<TrainingSession> _sessions = [];
  List<Team> _teams = [];
  List<User> _coaches = [];
  List<Player> _players = [];
  bool _isLoading = true;
  Team? _selectedTeam;

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
      final allUsers = await _getAllUsers();
      _coaches = allUsers.where((u) => u.role == Role.coach).toList();

      if (widget.userRole == Role.coach) {
        _sessions = await _firebaseService.getTrainingSessionsByCoach(
          widget.userId,
        );
      } else {
        _sessions = await _firebaseService.getAllTrainingSessions();
      }
      _sessions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('Error loading training sessions: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<List<User>> _getAllUsers() async {
    final users = <User>[];
    try {
      final snapshot = await _firebaseService.usersRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          users.add(
            User(
              id: child.key ?? '',
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              password: '',
              role: RoleExtension.fromString(data['role'] ?? 'coach'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    return users;
  }

  List<TrainingSession> get _filteredSessions {
    var filtered = _sessions;

    // Filter by team if selected
    if (_selectedTeam != null) {
      filtered = filtered.where((s) => s.teamId == _selectedTeam!.id).toList();
    }

    // For training sessions, we don't have direct player associations
    // In a real implementation, you'd check each participant's medical clearance
    // For now, we'll show all sessions but add medical clearance warnings
    return filtered;
  }

  Future<void> _showAddSessionDialog() async {
    String? selectedTeamId;
    String? selectedCoachId;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);
    String selectedFocus = TrainingSession.trainingFocuses.first;
    final notesController = TextEditingController();
    bool _isSaving = false;

    final validCoaches = _coaches
        .where((c) => c.id != null && c.id!.isNotEmpty)
        .toSet()
        .toList();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Schedule Training',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_teams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No teams available. Please create a team first.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTeamId,
                    dropdownColor: AppTheme.surfaceVariantColor,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    decoration: const InputDecoration(
                      labelText: 'Select Team',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    ),
                    items: _teams
                        .where((t) => t.id != null && t.id!.isNotEmpty)
                        .toSet()
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTeamId = value;
                        selectedCoachId = null; // Reset coach
                        if (value != null) {
                          final team = _teams
                              .where((t) => t.id == value)
                              .toList();
                          if (team.isNotEmpty &&
                              team.first.coachId != null &&
                              team.first.coachId!.isNotEmpty) {
                            // Only set if coach exists in valid coaches
                            final coachExists = validCoaches.any(
                              (c) => c.id == team.first.coachId,
                            );
                            if (coachExists) {
                              selectedCoachId = team.first.coachId;
                            }
                          }
                        }
                      });
                    },
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCoachId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Coach',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: validCoaches
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCoachId = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Time: ${selectedTime.format(context)}',
                    style: const TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  trailing: const Icon(
                    Icons.access_time,
                    color: AppTheme.primaryColor,
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedFocus,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Training Focus',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: TrainingSession.trainingFocuses
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedFocus = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onBackgroundMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: _isSaving
                  ? null
                  : () async {
                      setDialogState(() => _isSaving = true);
                      String? errorMsg;
                      if (selectedTeamId == null) {
                        errorMsg = 'Please select a team';
                      } else if (selectedCoachId == null) {
                        errorMsg = 'Please select a coach';
                      }
                      if (errorMsg != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                        setDialogState(() => _isSaving = false);
                        return;
                      }
                      try {
                        final session = TrainingSession(
                          teamId: selectedTeamId!,
                          coachId: selectedCoachId!,
                          date: selectedDate,
                          time:
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          trainingFocus: selectedFocus,
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                        );
                        await _firebaseService.createTrainingSession(session);
                        await _loadData();
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating session: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => _isSaving = false);
                        }
                      }
                    },
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.onBackgroundColor,
                        ),
                      ),
                    )
                  : const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSession(TrainingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Cancel Training',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Text(
          'Are you sure you want to cancel this training session?',
          style: TextStyle(color: AppTheme.onBackgroundMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && session.id != null) {
      await _firebaseService.deleteTrainingSession(session.id!);
      await _loadData();
    }
  }

  String _getTeamName(String teamId) {
    final teams = _teams.where((t) => t.id == teamId).toList();
    return teams.isNotEmpty ? teams.first.name : 'Unknown';
  }

  String _getCoachName(String? coachId) {
    if (coachId == null) return 'Not assigned';
    final coaches = _coaches.where((c) => c.id.toString() == coachId).toList();
    return coaches.isNotEmpty ? coaches.first.name : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin ||
        widget.userRole == Role.coach;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Sessions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _showAddSessionDialog,
              child: const Icon(Icons.add, color: AppTheme.onBackgroundColor),
            )
          : null,
      body: Column(
        children: [
          if (_teams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedTeam?.id,
                dropdownColor: AppTheme.surfaceVariantColor,
                style: const TextStyle(color: AppTheme.onBackgroundColor),
                decoration: InputDecoration(
                  labelText: 'Filter by Team',
                  labelStyle: const TextStyle(
                    color: AppTheme.onBackgroundMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Teams')),
                  ..._teams.map(
                    (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    final filtered = _teams
                        .where((t) => t.id == value)
                        .toList();
                    _selectedTeam = filtered.isNotEmpty ? filtered.first : null;
                  });
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _filteredSessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_note,
                          size: 64,
                          color: AppTheme.onBackgroundFaint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No training sessions scheduled',
                          style: TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                            fontSize: 18,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to schedule training',
                            style: TextStyle(color: AppTheme.onBackgroundFaint),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = _filteredSessions[index];
                      final isPast = session.date.isBefore(DateTime.now());
                      return Card(
                        color: AppTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.sports_soccer,
                              color: isPast
                                  ? Colors.grey
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            _getTeamName(session.teamId),
                            style: TextStyle(
                              color: AppTheme.onBackgroundColor,
                              fontWeight: FontWeight.bold,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.date.toLocal().toString().split(' ')[0]} at ${session.time}',
                                style: TextStyle(
                                  color: isPast
                                      ? AppTheme.onBackgroundFaint
                                      : AppTheme.onBackgroundMuted,
                                ),
                              ),
                              Text(
                                'Focus: ${session.trainingFocus}',
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                ),
                              ),
                              Text(
                                'Coach: ${_getCoachName(session.coachId)}',
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                ),
                              ),
                              if (session.notes != null &&
                                  session.notes!.isNotEmpty)
                                Text(
                                  'Notes: ${session.notes}',
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundFaint,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: canManage && !isPast
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSession(session),
                                )
                              : null,
                          isThreeLine: true,
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
