import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/notification_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const MedicalRecordsScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  List<Player> _players = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      _players = await _firebaseService.getAllPlayers();
    } catch (e) {
      print('Error loading players: $e');
    }
    setState(() => _isLoading = false);
  }

  bool get _canEdit {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin ||
        widget.userRole == Role.coach;
  }

  List<Player> get _filteredPlayers {
    if (_searchQuery.isEmpty) return _players;
    return _players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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

  Future<void> _showMedicalDialog(Player player) async {
    HealthStatus selectedStatus = player.healthStatus;
    final injuryDetailsController = TextEditingController(
      text: player.injuryDetails ?? '',
    );
    final doctorNotesController = TextEditingController(
      text: player.doctorNotes ?? '',
    );
    final recoveryPlanController = TextEditingController(
      text: player.recoveryPlan ?? '',
    );
    bool medicalClearance = player.medicalClearance;
    DateTime? lastCheck = player.lastMedicalCheck;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            '${player.name} - Medical Record',
            style: const TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Status',
                  style: TextStyle(color: AppTheme.onBackgroundMuted),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<HealthStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  items: HealthStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_getHealthStatusLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: injuryDetailsController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Injury Details',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: doctorNotesController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Notes',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: recoveryPlanController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Plan',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: lastCheck ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => lastCheck = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Last Medical Check',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                    ),
                    child: Text(
                      lastCheck != null
                          ? '${lastCheck!.day}/${lastCheck!.month}/${lastCheck!.year}'
                          : 'Select Date',
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Medical Clearance',
                    style: TextStyle(color: AppTheme.onBackgroundColor),
                  ),
                  value: medicalClearance,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setDialogState(() => medicalClearance = value);
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
            if (_canEdit)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                onPressed: () async {
                  final updatedPlayer = player.copyWith(
                    healthStatus: selectedStatus,
                    injuryDetails: injuryDetailsController.text.isNotEmpty
                        ? injuryDetailsController.text
                        : null,
                    doctorNotes: doctorNotesController.text.isNotEmpty
                        ? doctorNotesController.text
                        : null,
                    recoveryPlan: recoveryPlanController.text.isNotEmpty
                        ? recoveryPlanController.text
                        : null,
                    lastMedicalCheck: lastCheck,
                    medicalClearance: medicalClearance,
                  );
                  await _firebaseService.updatePlayer(
                    player.id!,
                    updatedPlayer,
                  );
                  if (selectedStatus == HealthStatus.injured ||
                      selectedStatus == HealthStatus.notFit) {
                    await _notificationService.createInjuryAlert(
                      'Injury Update',
                      '${player.name} has been marked as ${_getHealthStatusLabel(selectedStatus)}. Please check the medical records for details.',
                      player.parentId ?? '',
                    );
                  }
                  await _loadPlayers();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
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
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
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
                ? const Center(
                    child: Text(
                      'No players found',
                      style: TextStyle(color: AppTheme.onBackgroundSubtle),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      return Card(
                        color: AppTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getHealthStatusColor(
                              player.healthStatus,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              Icons.medical_services,
                              color: _getHealthStatusColor(player.healthStatus),
                            ),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(
                              color: AppTheme.onBackgroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Health: ',
                                    style: TextStyle(
                                      color: AppTheme.onBackgroundMuted,
                                    ),
                                  ),
                                  Container(
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
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Clearance: ',
                                    style: TextStyle(
                                      color: AppTheme.onBackgroundMuted,
                                    ),
                                  ),
                                  Icon(
                                    player.medicalClearance
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: player.medicalClearance
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                ],
                              ),
                              if (player.lastMedicalCheck != null)
                                Text(
                                  'Last Check: ${player.lastMedicalCheck!.day}/${player.lastMedicalCheck!.month}/${player.lastMedicalCheck!.year}',
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundSubtle,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () => _showMedicalDialog(player),
                          ),
                          isThreeLine: true,
                          onTap: () => _showMedicalDialog(player),
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
