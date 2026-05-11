import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/data_consistency_service.dart';

class TeamsScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const TeamsScreen({super.key, required this.userRole, required this.userId});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final DataConsistencyService _dataConsistencyService =
      DataConsistencyService();
  List<Team> _teams = [];
  List<User> _coaches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _teams = await _firebaseService.getAllTeams();
      final allUsers = await _getAllUsers();
      _coaches = allUsers
          .where((u) => u.role == Role.coach && (u.id?.isNotEmpty ?? false))
          .toList();
    } catch (e) {
      print('Error loading teams: $e');
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

  Future<void> _showAddTeamDialog() async {
    final nameController = TextEditingController();
    String selectedAgeGroup = Team.ageGroups.first;
    String? selectedCoachId;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Add New Team',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.onBackgroundSubtle,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedAgeGroup,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Age Group',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: Team.ageGroups
                      .map(
                        (age) => DropdownMenuItem(value: age, child: Text(age)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedAgeGroup = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCoachId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Assign Coach (Optional)',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'none_coach',
                      child: Text('None'),
                    ),
                    ..._coaches.map(
                      (coach) => DropdownMenuItem(
                        value: coach.id.toString(),
                        child: Text(coach.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(
                      () =>
                          selectedCoachId = value == 'none_coach' ? '' : value,
                    );
                  },
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
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      if (nameController.text.isNotEmpty) {
                        final team = Team(
                          name: nameController.text,
                          ageGroup: selectedAgeGroup,
                          coachId: selectedCoachId,
                        );
                        await _firebaseService.createTeam(team);
                        await _loadData();
                        if (mounted) Navigator.pop(context);
                      }
                    },
              child: isSaving
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
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTeamDialog(Team team) async {
    final nameController = TextEditingController(text: team.name);
    String selectedAgeGroup = team.ageGroup;
    String? selectedCoachId = team.coachId;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Edit Team',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.onBackgroundSubtle,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedAgeGroup,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Age Group',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: Team.ageGroups
                      .map(
                        (age) => DropdownMenuItem(value: age, child: Text(age)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedAgeGroup = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCoachId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Assign Coach',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'none_coach',
                      child: Text('None'),
                    ),
                    ..._coaches.map(
                      (coach) => DropdownMenuItem(
                        value: coach.id.toString(),
                        child: Text(coach.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(
                      () =>
                          selectedCoachId = value == 'none_coach' ? '' : value,
                    );
                  },
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
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      if (nameController.text.isNotEmpty && team.id != null) {
                        final updatedTeam = team.copyWith(
                          name: nameController.text,
                          ageGroup: selectedAgeGroup,
                          coachId: selectedCoachId,
                        );
                        await _firebaseService.updateTeam(
                          team.id!,
                          updatedTeam,
                        );
                        await _loadData();
                        if (mounted) Navigator.pop(context);
                      }
                    },
              child: isSaving
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
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTeam(Team team) async {
    final canDelete = await _dataConsistencyService.canDeleteTeam(team.id!);
    if (!canDelete) {
      final message = await _dataConsistencyService.getDeleteTeamBlocker(
        team.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Team',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: Text(
          'Are you sure you want to delete ${team.name}?',
          style: const TextStyle(color: AppTheme.onBackgroundMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && team.id != null) {
      await _firebaseService.deleteTeam(team.id!);
      await _loadData();
    }
  }

  String _getCoachName(String? coachId) {
    if (coachId == null) return 'Not Assigned';
    final coach = _coaches.where((c) => c.id.toString() == coachId).firstOrNull;
    return coach?.name ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _showAddTeamDialog,
              child: const Icon(Icons.add, color: AppTheme.onBackgroundColor),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _teams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: AppTheme.onBackgroundFaint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No teams yet',
                    style: TextStyle(
                      color: AppTheme.onBackgroundSubtle,
                      fontSize: 18,
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to create a team',
                      style: TextStyle(color: AppTheme.onBackgroundFaint),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      team.name,
                      style: const TextStyle(
                        color: AppTheme.onBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age Group: ${team.ageGroup}',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        Text(
                          'Coach: ${_getCoachName(team.coachId)}',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                          ),
                        ),
                        Text(
                          'Players: ${team.playersCount}',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                          ),
                        ),
                      ],
                    ),
                    trailing: canManage
                        ? PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppTheme.onBackgroundMuted,
                            ),
                            color: AppTheme.surfaceVariantColor,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: AppTheme.onBackgroundColor,
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditTeamDialog(team);
                              } else if (value == 'delete') {
                                _deleteTeam(team);
                              }
                            },
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
