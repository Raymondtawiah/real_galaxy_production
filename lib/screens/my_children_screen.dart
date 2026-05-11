import 'dart:io';
import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/player_progress.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/player_progress_service.dart';
import 'package:real_galaxy/screens/child_progress_screen.dart';

class MyChildrenScreen extends StatefulWidget {
  final String parentId;

  const MyChildrenScreen({super.key, required this.parentId});

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PlayerProgressService _progressService = PlayerProgressService();
  List<Player> _players = [];
  List<Team> _teams = [];
  Map<String, PlayerProgressSummary> _playerProgressSummaries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Loading children for parentId: ${widget.parentId}');
      _teams = await _firebaseService.getAllTeams();
      debugPrint('Teams loaded: ${_teams.length}');

      // Get all players and filter by parentId (fallback if index doesn't exist)
      final allPlayers = await _firebaseService.getAllPlayers();
      debugPrint('All players in system: ${allPlayers.length}');

      _players = allPlayers
          .where((p) => p.parentId == widget.parentId)
          .toList();
      debugPrint('Filtered players for parent: ${_players.length}');
      for (var p in _players) {
        debugPrint('  - Player: ${p.name}, parentId: ${p.parentId}');
      }

      // Load progress summaries for each player
      _playerProgressSummaries.clear();
      for (final player in _players) {
        try {
          final summary = await _progressService.getPlayerProgressSummary(
            player.id!,
          );
          _playerProgressSummaries[player.id!] = summary;
        } catch (e) {
          debugPrint('Error loading progress for ${player.name}: $e');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading children: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showAddChildDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String gender = 'Male';
    String? position;
    DateTime? dateOfBirth;
    final emergencyNameController = TextEditingController();
    final emergencyPhoneController = TextEditingController();
    bool hasMedicalIssue = false;
    final medicalNoteController = TextEditingController();
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Register Child',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Child Name',
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
                TextField(
                  controller: ageController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
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
                InkWell(
                  onTap: () async {
                    final dob = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365 * 6),
                      ),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 20),
                      ),
                      lastDate: DateTime.now().subtract(
                        const Duration(days: 365 * 4),
                      ),
                    );
                    if (dob != null) {
                      setDialogState(() => dateOfBirth = dob);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.onBackgroundSubtle,
                        ),
                      ),
                    ),
                    child: Text(
                      dateOfBirth != null
                          ? '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                          : 'Select Date',
                      style: TextStyle(
                        color: dateOfBirth != null
                            ? AppTheme.onBackgroundColor
                            : AppTheme.onBackgroundSubtle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: ['Male', 'Female']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => gender = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: position,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Preferred Position (Optional)',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(
                      value: 'Goalkeeper',
                      child: Text('Goalkeeper'),
                    ),
                    DropdownMenuItem(
                      value: 'Defender',
                      child: Text('Defender'),
                    ),
                    DropdownMenuItem(
                      value: 'Midfielder',
                      child: Text('Midfielder'),
                    ),
                    DropdownMenuItem(value: 'Forward', child: Text('Forward')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => position = value);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Medical Information',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text(
                    'Any medical issues?',
                    style: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  value: hasMedicalIssue,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setDialogState(() => hasMedicalIssue = value);
                  },
                ),
                if (hasMedicalIssue) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: medicalNoteController,
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Medical details',
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
                ],
                const SizedBox(height: 16),
                const Text(
                  'Emergency Contact',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emergencyNameController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
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
                TextField(
                  controller: emergencyPhoneController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
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
                const Text(
                  'Child Photo',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.photo_library,
                          color: AppTheme.primaryColor,
                        ),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.onBackgroundColor,
                          side: const BorderSide(color: AppTheme.outlineColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (photo != null) {
                            setDialogState(() {
                              selectedImage = File(photo.path);
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppTheme.primaryColor,
                        ),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.onBackgroundColor,
                          side: const BorderSide(color: AppTheme.outlineColor),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: FileImage(selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        selectedImage = null;
                      });
                    },
                    child: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
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
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    ageController.text.isNotEmpty) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final age = int.tryParse(ageController.text) ?? 0;
                  if (dateOfBirth == null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Please select date of birth'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                    return;
                  }
                  try {
                    final player = Player(
                      name: nameController.text.trim(),
                      age: age,
                      dateOfBirth: dateOfBirth,
                      gender: gender,
                      position: position,
                      parentId: widget.parentId,
                      healthStatus: hasMedicalIssue
                          ? HealthStatus.injured
                          : HealthStatus.fit,
                      injuryDetails: hasMedicalIssue
                          ? medicalNoteController.text.trim()
                          : null,
                      emergencyContactName:
                          emergencyNameController.text.isNotEmpty
                          ? emergencyNameController.text.trim()
                          : null,
                      emergencyContactPhone:
                          emergencyPhoneController.text.isNotEmpty
                          ? emergencyPhoneController.text.trim()
                          : null,
                    );
                    debugPrint('Creating player: ${player.toMap()}');
                    final playerId = await _firebaseService.createPlayer(
                      player,
                    );
                    debugPrint('Player created with ID: $playerId');
                    if (selectedImage != null) {
                      await _firebaseService.uploadPlayerImageFile(
                        playerId,
                        selectedImage!,
                      );
                    }
                    await _loadData();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Child registered successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e, stackTrace) {
                    debugPrint('Error creating player: $e');
                    debugPrint('Stack trace: $stackTrace');
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditChildDialog(Player player) async {
    final nameController = TextEditingController(text: player.name);
    final ageController = TextEditingController(text: player.age.toString());
    String gender = player.gender;
    String? position = player.position;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Edit Child',
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
                    labelText: 'Child Name',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: ['Male', 'Female']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => gender = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: position,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(
                      value: 'Goalkeeper',
                      child: Text('Goalkeeper'),
                    ),
                    DropdownMenuItem(
                      value: 'Defender',
                      child: Text('Defender'),
                    ),
                    DropdownMenuItem(
                      value: 'Midfielder',
                      child: Text('Midfielder'),
                    ),
                    DropdownMenuItem(value: 'Forward', child: Text('Forward')),
                  ],
                  onChanged: (v) => setDialogState(() => position = v),
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
              onPressed: () async {
                if (nameController.text.isNotEmpty && player.id != null) {
                  final age = int.tryParse(ageController.text) ?? player.age;
                  final updatedPlayer = player.copyWith(
                    name: nameController.text,
                    age: age,
                    gender: gender,
                    position: position,
                  );
                  await _firebaseService.updatePlayer(
                    player.id!,
                    updatedPlayer,
                  );
                  await _loadData();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTeamName(String? teamId) {
    if (teamId == null) return 'No team';
    final team = _teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => Team(id: '', name: 'Unknown Team', ageGroup: 'Unknown'),
    );
    return team.name;
  }

  Color _getProgressColor(double rating) {
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
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

  Widget _buildProgressSummary(PlayerProgressSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Rating:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    summary.overallRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grade:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProgressColor(
                    summary.overallRating,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.performanceGrade,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(summary.overallRating),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assessments:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${summary.totalAssessments} completed',
                style: const TextStyle(color: AppTheme.onBackgroundMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChildDialog,
            tooltip: 'Register Child',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _players.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.child_care,
                    size: 64,
                    color: AppTheme.onBackgroundFaint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No children registered yet',
                    style: TextStyle(
                      color: AppTheme.onBackgroundSubtle,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to register your child',
                    style: TextStyle(color: AppTheme.onBackgroundFaint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading:
                        player.imageUrl != null && player.imageUrl!.isNotEmpty
                        ? CircleAvatar(
                            backgroundColor: const Color(
                              0xFFDC143C,
                            ).withValues(alpha: 0.2),
                            backgroundImage: NetworkImage(player.imageUrl!),
                          )
                        : CircleAvatar(
                            backgroundColor: const Color(
                              0xFFDC143C,
                            ).withValues(alpha: 0.2),
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 20,
                              ),
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
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${player.age} | ${player.gender}',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundMuted,
                          ),
                        ),
                        Text(
                          'Position: ${player.position ?? "Not specified"}',
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Status: ',
                              style: TextStyle(
                                color: AppTheme.onBackgroundSubtle,
                              ),
                            ),
                            Container(
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
                              ),
                            ),
                          ],
                        ),
                        if (player.emergencyContactName != null ||
                            player.emergencyContactPhone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Emergency: ${player.emergencyContactName ?? ""} ${player.emergencyContactPhone ?? ""}',
                            style: const TextStyle(
                              color: AppTheme.onBackgroundSubtle,
                            ),
                          ),
                        ],
                        if (player.injuryDetails != null &&
                            player.injuryDetails!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Medical: ${player.injuryDetails}',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ],
                    ),
                    trailing: _playerProgressSummaries.containsKey(player.id)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: _getProgressColor(
                                  _playerProgressSummaries[player.id!]!
                                      .overallRating,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _playerProgressSummaries[player.id!]!
                                    .performanceGrade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(
                                    _playerProgressSummaries[player.id!]!
                                        .overallRating,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : null,
                    children: [
                      // Progress content in dropdown
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_playerProgressSummaries.containsKey(
                              player.id,
                            )) ...[
                              _buildProgressSummary(
                                _playerProgressSummaries[player.id!]!,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChildProgressScreen(player: player),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.assessment, size: 16),
                                label: const Text('View Detailed Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'No progress data available yet.',
                                style: TextStyle(
                                  color: AppTheme.onBackgroundMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
