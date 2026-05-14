import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/player_progress.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/player_progress_service.dart';

class PlayerProgressManagementScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const PlayerProgressManagementScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PlayerProgressManagementScreen> createState() =>
      _PlayerProgressManagementScreenState();
}

class _PlayerProgressManagementScreenState
    extends State<PlayerProgressManagementScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final PlayerProgressService _progressService = PlayerProgressService();
  final TextEditingController _skillNameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _strengthsController = TextEditingController();
  final TextEditingController _improvementsController = TextEditingController();

  List<Player> _players = [];
  List<PlayerProgress> _selectedPlayerProgress = [];
  Player? _selectedPlayer;
  bool _isLoading = true;
  bool _isCreatingProgress = false;

  ProgressCategory _selectedCategory = ProgressCategory.technical;
  SkillLevel _currentLevel = SkillLevel.beginner;
  SkillLevel _targetLevel = SkillLevel.developing;
  double _rating = 5.0;
  DateTime? _nextAssessmentDate;
  String? _selectedSkillName;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _skillNameController.dispose();
    _commentsController.dispose();
    _strengthsController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allPlayers = await _firebaseService.getAllPlayers();
      // Ensure unique players based on ID
      _players = allPlayers.where((p) => p.id != null).toSet().toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadPlayerProgress(Player player) async {
    setState(() => _isLoading = true);
    try {
      _selectedPlayerProgress = await _progressService
          .getPlayerProgressByPlayer(player.id!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading player progress: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createProgress() async {
    if (_selectedPlayer == null ||
        _selectedSkillName == null ||
        _selectedSkillName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a player and skill name')),
      );
      return;
    }

    setState(() => _isCreatingProgress = true);
    try {
      final progress = PlayerProgress(
        playerId: _selectedPlayer!.id!,
        assessedBy: widget.userId,
        category: _selectedCategory,
        skillName: _skillNameController.text,
        currentLevel: _currentLevel,
        targetLevel: _targetLevel,
        rating: _rating,
        comments: _commentsController.text.isEmpty
            ? null
            : _commentsController.text,
        nextAssessmentDate: _nextAssessmentDate,
        strengths: _strengthsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        areasForImprovement: _improvementsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      await _progressService.createPlayerProgress(progress);

      // Send notification to parent
      await _progressService.createProgressUpdateNotification(
        _selectedPlayer!.id!,
        _selectedPlayer!.name,
        _selectedPlayer!.parentId,
        progress.skillName,
        progress.currentLevel,
        progress.rating,
      );

      _clearForm();
      await _loadPlayerProgress(_selectedPlayer!);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress recorded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating progress: $e')));
    }
    setState(() => _isCreatingProgress = false);
  }

  void _clearForm() {
    _skillNameController.clear();
    _commentsController.clear();
    _strengthsController.clear();
    _improvementsController.clear();
    _selectedCategory = ProgressCategory.technical;
    _selectedSkillName = null;
    _currentLevel = SkillLevel.beginner;
    _targetLevel = SkillLevel.developing;
    _rating = 5.0;
    _nextAssessmentDate = null;
  }

  List<String> _getSkillsForCategory(ProgressCategory category) {
    switch (category) {
      case ProgressCategory.technical:
        return [
          'Dribbling',
          'Passing',
          'Shooting',
          'Ball Control',
          'First Touch',
          'Heading',
          'Volleys',
          'Free Kicks',
        ];
      case ProgressCategory.physical:
        return [
          'Speed',
          'Stamina',
          'Strength',
          'Agility',
          'Balance',
          'Coordination',
          'Jumping',
          'Endurance',
        ];
      case ProgressCategory.tactical:
        return [
          'Positioning',
          'Game Awareness',
          'Decision Making',
          'Team Play',
          'Space Recognition',
          'Transition',
          'Pressing',
          'Off Ball Movement',
        ];
      case ProgressCategory.mental:
        return [
          'Focus',
          'Confidence',
          'Leadership',
          'Communication',
          'Resilience',
          'Discipline',
          'Work Ethic',
          'Positive Attitude',
        ];
      case ProgressCategory.social:
        return [
          'Teamwork',
          'Sportsmanship',
          'Respect',
          'Cooperation',
          'Empathy',
          'Conflict Resolution',
          'Inclusion',
          'Support Others',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Progress Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Add Progress', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildAddProgressTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _buildPlayerSelector(),
        Expanded(
          child: _selectedPlayer == null
              ? const Center(child: Text('Select a player to view progress'))
              : _buildPlayerProgressView(),
        ),
      ],
    );
  }

  Widget _buildPlayerSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<Player>(
        decoration: const InputDecoration(
          labelText: 'Select Player',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        initialValue: _selectedPlayer,
        items: _players.where((p) => p.id != null).toSet().map((player) {
          return DropdownMenuItem(
            value: player,
            child: Text('${player.name} (${player.position ?? 'No position'})'),
          );
        }).toList(),
        onChanged: (player) {
          setState(() {
            _selectedPlayer = player;
          });
          if (player != null) {
            _loadPlayerProgress(player);
          }
        },
      ),
    );
  }

  Widget _buildPlayerProgressView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedPlayerProgress.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No progress records found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedPlayerProgress.length,
      itemBuilder: (context, index) {
        final progress = _selectedPlayerProgress[index];
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
                      progress.skillName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        progress.categoryDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLevelChip('Current', progress.currentLevel),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    _buildLevelChip('Target', progress.targetLevel),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.progressPercentage / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress.progressPercentage >= 80
                        ? Colors.green
                        : progress.progressPercentage >= 50
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rating: ${progress.rating.toStringAsFixed(1)}/10.0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${progress.progressPercentage.toStringAsFixed(1)}% to target',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (progress.comments != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    progress.comments!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Assessed: ${progress.assessmentDate.toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelChip(String label, SkillLevel level) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            level.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerSelector(),
          const SizedBox(height: 16),
          if (_selectedPlayer != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Progress Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Skill Name',
                        border: OutlineInputBorder(),
                        hintText: 'Select a skill',
                      ),
                      initialValue: _selectedSkillName,
                      items: _getSkillsForCategory(_selectedCategory).map((
                        skill,
                      ) {
                        return DropdownMenuItem(
                          value: skill,
                          child: Text(skill),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSkillName = value;
                          _skillNameController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ProgressCategory>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCategory,
                      items: ProgressCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _selectedSkillName =
                              null; // Reset skill when category changes
                          _skillNameController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SkillLevel>(
                            decoration: const InputDecoration(
                              labelText: 'Current Level',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _currentLevel,
                            items: SkillLevel.values.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  _getShortLevelName(level),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _currentLevel = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<SkillLevel>(
                            decoration: const InputDecoration(
                              labelText: 'Target Level',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _targetLevel,
                            items: SkillLevel.values.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  _getShortLevelName(level),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _targetLevel = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating: ${_rating.toStringAsFixed(1)}/10.0'),
                        Slider(
                          value: _rating,
                          min: 1.0,
                          max: 10.0,
                          divisions: 18,
                          onChanged: (value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentsController,
                      decoration: const InputDecoration(
                        labelText: 'Comments (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Additional notes about the progress',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _strengthsController,
                      decoration: const InputDecoration(
                        labelText: 'Strengths (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Comma-separated strengths',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _improvementsController,
                      decoration: const InputDecoration(
                        labelText: 'Areas for Improvement (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Comma-separated areas to work on',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Next Assessment Date'),
                      subtitle: Text(
                        _nextAssessmentDate != null
                            ? _nextAssessmentDate!.toString().split(' ')[0]
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _nextAssessmentDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingProgress ? null : _createProgress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCreatingProgress
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Progress'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getShortLevelName(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.developing:
        return 'Developing';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.excellent:
        return 'Excellent';
    }
  }
}
