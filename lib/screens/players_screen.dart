import 'dart:io';
import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class PlayersScreen extends StatefulWidget {
  final Role userRole;
  final String userId;
  final String? assignedTeamId;

  const PlayersScreen({
    super.key,
    required this.userRole,
    required this.userId,
    this.assignedTeamId,
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Player> _players = [];
  List<Team> _teams = [];
  bool _isLoading = true;
  Team? _selectedTeam;
  String _searchQuery = '';
  bool _showInactivePlayers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _teams = await _firebaseService.getAllTeams();

      if (widget.assignedTeamId != null) {
        _players = await _firebaseService.getPlayersByTeam(
          widget.assignedTeamId!,
        );
        _selectedTeam = _teams
            .where((t) => t.id == widget.assignedTeamId)
            .toList()
            .firstOrNull;
      } else {
        _players = await _firebaseService.getAllPlayers();
      }
    } catch (e) {
      print('Error loading players: $e');
    }
    setState(() => _isLoading = false);
  }

  List<Player> get _filteredPlayers {
    var filtered = _players;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.position?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }
    if (_selectedTeam != null) {
      filtered = filtered.where((p) => p.teamId == _selectedTeam!.id).toList();
    }
    // Filter based on inactive players toggle
    if (!_showInactivePlayers) {
      filtered = filtered.where((p) => p.isActive).toList();
    }
    return filtered;
  }

  Future<void> _showAddPlayerDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final positionController = TextEditingController();
    final jerseyNumberController = TextEditingController();
    final injuryDetailsController = TextEditingController();
    final doctorNotesController = TextEditingController();
    final recoveryPlanController = TextEditingController();
    Team? selectedTeam;
    HealthStatus selectedHealth = HealthStatus.fit;
    PlayerStatus selectedStatus = PlayerStatus.active;
    DateTime? selectedDob;
    File? imageFile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Add Player',
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
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          labelStyle: TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedTeam?.id,
                        dropdownColor: AppTheme.surfaceVariantColor,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Team',
                          labelStyle: TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        items: _teams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeam = value == null
                                ? null
                                : _teams.firstWhere((t) => t.id == value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlayerStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: PlayerStatus.values
                      .map(
                        (s) => DropdownMenuItem<PlayerStatus>(
                          value: s,
                          child: Text(s.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedStatus = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthStatus>(
                  initialValue: selectedHealth,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Health',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: HealthStatus.values
                      .map(
                        (h) => DropdownMenuItem<HealthStatus>(
                          value: h,
                          child: Text(h.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedHealth = value!),
                ),
                const SizedBox(height: 12),
                if (widget.userRole == Role.parent)
                  TextField(
                    controller: injuryDetailsController,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    decoration: const InputDecoration(
                      labelText: 'Injury Details',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onBackgroundSubtle),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  final parentId = widget.userRole == Role.parent
                      ? widget.userId
                      : '';
                  final player = Player(
                    id: '',
                    name: nameController.text.trim(),
                    dateOfBirth: selectedDob ?? DateTime.now(),
                    age: int.tryParse(ageController.text) ?? 0,
                    gender: 'Male',
                    position: positionController.text.trim().isNotEmpty
                        ? positionController.text.trim()
                        : null,
                    teamId: selectedTeam?.id,
                    status: selectedStatus,
                    healthStatus: selectedHealth,
                    injuryDetails:
                        injuryDetailsController.text.trim().isNotEmpty
                        ? injuryDetailsController.text.trim()
                        : null,
                    doctorNotes: doctorNotesController.text.trim().isNotEmpty
                        ? doctorNotesController.text.trim()
                        : null,
                    recoveryPlan: recoveryPlanController.text.trim().isNotEmpty
                        ? recoveryPlanController.text.trim()
                        : null,
                    medicalClearance: selectedHealth == HealthStatus.fit,
                    parentId: parentId,
                    isActive: true,
                    isDeleted: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await _firebaseService.createPlayer(player);
                  await _loadData();
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Player added successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Add',
                style: TextStyle(color: AppTheme.onBackgroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPlayerDialog(Player player) async {
    final nameController = TextEditingController(text: player.name);
    final ageController = TextEditingController(text: player.age.toString());
    final positionController = TextEditingController(
      text: player.position ?? '',
    );
    final injuryDetailsController = TextEditingController(
      text: player.injuryDetails ?? '',
    );
    final doctorNotesController = TextEditingController(
      text: player.doctorNotes ?? '',
    );
    final recoveryPlanController = TextEditingController(
      text: player.recoveryPlan ?? '',
    );
    Team? selectedTeam = _teams.isNotEmpty && player.teamId != null
        ? _teams.firstWhere(
            (t) => t.id == player.teamId,
            orElse: () => _teams.first,
          )
        : null;
    HealthStatus selectedHealth = player.healthStatus;
    PlayerStatus selectedStatus = player.status;
    DateTime? selectedDob = player.dateOfBirth;
    File? imageFile;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            'Edit Player',
            style: const TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: ageController,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Age',
                          labelStyle: TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedTeam?.id,
                        dropdownColor: AppTheme.surfaceVariantColor,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Team',
                          labelStyle: TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        items: _teams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeam = value == null
                                ? null
                                : _teams.firstWhere((t) => t.id == value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: InputDecoration(
                    labelText: 'Position',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlayerStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: PlayerStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedStatus = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthStatus>(
                  initialValue: selectedHealth,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: InputDecoration(
                    labelText: 'Health',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outlineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: HealthStatus.values
                      .map(
                        (h) => DropdownMenuItem(value: h, child: Text(h.name)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedHealth = value!),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Player Photo',
                      style: TextStyle(color: AppTheme.onBackgroundMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              imageFile!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (player.imageUrl != null &&
                            player.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              player.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.onBackgroundSubtle,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 512,
                                    maxHeight: 512,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      imageFile = File(picked.path);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo, size: 18),
                                label: const Text('Choose Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceVariantColor,
                                  foregroundColor: AppTheme.onBackgroundColor,
                                  minimumSize: const Size.fromHeight(36),
                                ),
                              ),
                              if (player.imageUrl != null || imageFile != null)
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      imageFile = null;
                                    });
                                  },
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onBackgroundSubtle),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Name is required'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final updatedPlayer = player.copyWith(
                          name: nameController.text.trim(),
                          age: int.parse(ageController.text.trim()),
                          position: positionController.text.trim().isEmpty
                              ? null
                              : positionController.text.trim(),
                          teamId: selectedTeam?.id,
                          healthStatus: selectedHealth,
                          status: selectedStatus,
                          dateOfBirth: selectedDob,
                          injuryDetails:
                              injuryDetailsController.text.trim().isEmpty
                              ? null
                              : injuryDetailsController.text.trim(),
                          doctorNotes: doctorNotesController.text.trim().isEmpty
                              ? null
                              : doctorNotesController.text.trim(),
                          recoveryPlan:
                              recoveryPlanController.text.trim().isEmpty
                              ? null
                              : recoveryPlanController.text.trim(),
                        );

                        await _firebaseService.updatePlayer(
                          player.id!,
                          updatedPlayer,
                        );

                        await _loadData();
                        if (mounted) {
                          Navigator.pop(context);
                          // Show success message after dialog is closed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Player updated successfully'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          // Show error message while dialog is still open
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.onBackgroundColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Update',
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== NEW: Soft-Delete Action Methods =====
  Future<void> _deactivatePlayer(Player player) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _firebaseService.deactivatePlayer(player.id!);
      await _loadData();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Player deactivated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deactivating player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activatePlayer(Player player) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _firebaseService.activatePlayer(player.id!);
      await _loadData();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Player activated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error activating player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _archivePlayer(Player player) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _firebaseService.archivePlayer(player.id!);
      await _loadData();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Player archived successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error archiving player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restorePlayer(Player player) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _firebaseService.restorePlayer(player.id!);
      await _loadData();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Player restored successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error restoring player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== Helper Methods =====
  String _getTeamName(String? teamId) {
    if (teamId == null) return 'Unassigned';
    final teams = _teams.where((t) => t.id == teamId).toList();
    final team = teams.isNotEmpty ? teams.first : null;
    return team?.name ?? 'Unknown';
  }

  Color _getStatusColor(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.active:
        return Colors.green;
      case PlayerStatus.injured:
        return Colors.orange;
      case PlayerStatus.suspended:
        return Colors.red;
    }
  }

  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.fit:
        return Colors.green;
      case HealthStatus.minorInjury:
        return Colors.yellow;
      case HealthStatus.injured:
        return Colors.red;
      case HealthStatus.recovering:
        return Colors.orange;
      case HealthStatus.notFit:
        return Colors.red;
    }
  }

  String _getHealthStatusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.fit:
        return 'Fit';
      case HealthStatus.minorInjury:
        return 'Minor Injury';
      case HealthStatus.injured:
        return 'Injured';
      case HealthStatus.recovering:
        return 'Recovering';
      case HealthStatus.notFit:
        return 'Not Fit';
    }
  }

  // Build action menu based on player state
  List<PopupMenuEntry<String>> _buildPlayerActions(Player player) {
    final actions = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'edit',
        child: Text(
          'Edit',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
      ),
    ];

    // Only add management actions for owner (deactivate/activate) and other roles (archive)
    if (widget.userRole == Role.owner) {
      if (player.isDeleted) {
        // Archived player
        actions.add(
          const PopupMenuItem(
            value: 'restore',
            child: Text('Restore', style: TextStyle(color: Colors.green)),
          ),
        );
      } else if (!player.isActive) {
        // Inactive player
        actions.addAll([
          const PopupMenuItem(
            value: 'activate',
            child: Text('Activate', style: TextStyle(color: Colors.green)),
          ),
          const PopupMenuItem(
            value: 'archive',
            child: Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ]);
      } else {
        // Active player
        actions.addAll([
          const PopupMenuItem(
            value: 'deactivate',
            child: Text('Deactivate', style: TextStyle(color: Colors.orange)),
          ),
          const PopupMenuItem(
            value: 'archive',
            child: Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ]);
      }
    } else if (widget.userRole != Role.parent && !player.isDeleted) {
      // Other admin roles can only archive (not deactivate/activate)
      actions.add(
        const PopupMenuItem(
          value: 'archive',
          child: Text('Archive', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
        actions: [
          if (widget.userRole == Role.parent)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddPlayerDialog,
              tooltip: 'Add Player',
            ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _showAddPlayerDialog,
              child: const Icon(Icons.add, color: AppTheme.onBackgroundColor),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppTheme.onBackgroundColor),
              decoration: InputDecoration(
                hintText: 'Search players...',
                hintStyle: const TextStyle(color: AppTheme.onBackgroundFaint),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.onBackgroundSubtle,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Show inactive players toggle - owner only
          if (widget.userRole == Role.owner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Switch(
                    value: _showInactivePlayers,
                    onChanged: (value) =>
                        setState(() => _showInactivePlayers = value),
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Show Inactive Players',
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (_teams.isNotEmpty && widget.assignedTeamId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      final found = _teams.where((t) => t.id == value).toList();
                      _selectedTeam = found.isNotEmpty ? found.first : null;
                    } else {
                      _selectedTeam = null;
                    }
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
                : _filteredPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.group,
                          size: 64,
                          color: AppTheme.onBackgroundFaint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No players found',
                          style: TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                            fontSize: 18,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add a player',
                            style: TextStyle(color: AppTheme.onBackgroundFaint),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      return Card(
                        color: player.isDeleted
                            ? AppTheme.surfaceVariantColor.withValues(
                                alpha: 0.5,
                              )
                            : (!player.isActive
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : AppTheme.surfaceColor),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading:
                              player.imageUrl != null &&
                                  player.imageUrl!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundColor: !player.isActive
                                      ? Colors.grey
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                  backgroundImage: NetworkImage(
                                    player.imageUrl!,
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: !player.isActive
                                      ? Colors.grey
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                  child: Text(
                                    player.name.isNotEmpty
                                        ? player.name
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: !player.isActive
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                          title: Text(
                            player.name +
                                (player.isDeleted
                                    ? ' (Archived)'
                                    : (!player.isActive ? ' (Inactive)' : '')),
                            style: TextStyle(
                              color: player.isDeleted || !player.isActive
                                  ? AppTheme.onBackgroundSubtle
                                  : AppTheme.onBackgroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Age: ${player.age} | ${player.gender}',
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundMuted,
                                ),
                              ),
                              Text(
                                'Position: ${player.position ?? "N/A"}',
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                ),
                              ),
                              Text(
                                'Team: ${_getTeamName(player.teamId)}',
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      color: AppTheme.onBackgroundSubtle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          player.status,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        player.status.name.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(player.status),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (player.isDeleted) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ARCHIVED',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Health: ',
                                    style: TextStyle(
                                      color: AppTheme.onBackgroundSubtle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getHealthStatusColor(
                                          player.healthStatus,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getHealthStatusLabel(
                                          player.healthStatus,
                                        ),
                                        style: TextStyle(
                                          color: _getHealthStatusColor(
                                            player.healthStatus,
                                          ),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: canManage || widget.userRole == Role.parent
                              ? PopupMenuButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.onBackgroundMuted,
                                  ),
                                  color: AppTheme.surfaceVariantColor,
                                  itemBuilder: (context) =>
                                      _buildPlayerActions(player),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      if (player.isDeleted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cannot edit archived player',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                      _showEditPlayerDialog(player);
                                    } else if (value == 'activate') {
                                      _activatePlayer(player);
                                    } else if (value == 'deactivate') {
                                      _deactivatePlayer(player);
                                    } else if (value == 'archive') {
                                      _archivePlayer(player);
                                    } else if (value == 'restore') {
                                      _restorePlayer(player);
                                    }
                                  },
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
