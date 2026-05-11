import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/match.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/player_match_performance.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class PlayerPerformanceScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const PlayerPerformanceScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PlayerPerformanceScreen> createState() =>
      _PlayerPerformanceScreenState();
}

class _PlayerPerformanceScreenState extends State<PlayerPerformanceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Match> _matches = [];
  List<Player> _players = [];
  List<Team> _teams = [];
  bool _isLoading = true;
  Match? _selectedMatch;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _matches = await _firebaseService.getAllMatches();
      final now = DateTime.now();
      final cutoff = now.add(const Duration(hours: 24));
      _matches = _matches.where((m) => m.matchDate.isBefore(cutoff)).toList();
      _matches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
      _players = await _firebaseService.getAllPlayers();
      _teams = await _firebaseService.getAllTeams();

      if (_matches.isNotEmpty) {
        _selectedMatch = _matches.first;
      }
    } catch (e) {
      print('Error loading data: $e');
    }
    setState(() => _isLoading = false);
  }

  String _getTeamName(String? teamId) {
    if (teamId == null) return 'Team';
    final teams = _teams.where((t) => t.id == teamId).toList();
    return teams.isNotEmpty ? teams.first.name : 'Team';
  }

  Future<List<PlayerMatchPerformance>> _getPerformanceForMatch(
    String matchId,
  ) async {
    return await _firebaseService.getPerformanceByMatch(matchId);
  }

  String _getPlayerName(String? playerId) {
    if (playerId == null) return 'Unknown';
    final players = _players.where((p) => p.id == playerId).toList();
    return players.isNotEmpty ? players.first.name : 'Unknown';
  }

  bool get _canEdit {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin ||
        widget.userRole == Role.coach;
  }

  Future<void> _showAddPerformanceDialog(Match match) async {
    String? playerId;
    int goals = 0, assists = 0, yellowCards = 0, redCards = 0;
    double rating = 5.0;
    final notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Record Performance',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: playerId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Player',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: _players
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => playerId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        'Goals',
                        goals,
                        (v) => setDialogState(() => goals = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatField(
                        'Assists',
                        assists,
                        (v) => setDialogState(() => assists = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        'Yellow Cards',
                        yellowCards,
                        (v) => setDialogState(() => yellowCards = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatField(
                        'Red Cards',
                        redCards,
                        (v) => setDialogState(() => redCards = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Rating: ',
                      style: TextStyle(color: AppTheme.onBackgroundMuted),
                    ),
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 1,
                        max: 10,
                        divisions: 18,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) => setDialogState(() => rating = v),
                      ),
                    ),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Coach Notes',
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
              onPressed: () async {
                if (playerId != null) {
                  final perf = PlayerMatchPerformance(
                    playerId: playerId!,
                    matchId: match.id!,
                    goals: goals,
                    assists: assists,
                    yellowCards: yellowCards,
                    redCards: redCards,
                    rating: rating,
                    coachNotes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );
                  await _firebaseService.createPlayerMatchPerformance(perf);
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

  Widget _buildStatField(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onBackgroundMuted,
            fontSize: 12,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.remove,
                color: AppTheme.onBackgroundSubtle,
              ),
              onPressed: () => onChanged(value > 0 ? value - 1 : 0),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                color: AppTheme.onBackgroundColor,
                fontSize: 18,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.onBackgroundSubtle),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Performance'),
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
                if (_matches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedMatch?.id,
                      dropdownColor: AppTheme.surfaceVariantColor,
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                      decoration: InputDecoration(
                        labelText: 'Select Match',
                        labelStyle: const TextStyle(
                          color: AppTheme.onBackgroundMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _matches.map((m) {
                        final homeTeam = _players.isNotEmpty
                            ? _getTeamName(m.homeTeamId)
                            : 'Team A';
                        final awayTeam = _players.isNotEmpty
                            ? _getTeamName(m.awayTeamId)
                            : 'Team B';
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text('$homeTeam vs $awayTeam'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMatch = _matches.firstWhere(
                            (m) => m.id == value,
                          );
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: _selectedMatch == null
                      ? const Center(
                          child: Text(
                            'No completed matches',
                            style: TextStyle(
                              color: AppTheme.onBackgroundSubtle,
                            ),
                          ),
                        )
                      : FutureBuilder<List<PlayerMatchPerformance>>(
                          future: _getPerformanceForMatch(_selectedMatch!.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              );
                            }
                            final performances = snapshot.data ?? [];
                            return Column(
                              children: [
                                if (_canEdit)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddPerformanceDialog(
                                            _selectedMatch!,
                                          ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Performance'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFDC143C,
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: performances.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No performances recorded',
                                            style: TextStyle(
                                              color:
                                                  AppTheme.onBackgroundSubtle,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: performances.length,
                                          itemBuilder: (context, index) {
                                            final perf = performances[index];
                                            return Card(
                                              color: AppTheme.surfaceColor,
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: const Color(
                                                    0xFFDC143C,
                                                  ).withValues(alpha: 0.2),
                                                  child: Text(
                                                    perf.goals.toString(),
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  _getPlayerName(perf.playerId),
                                                  style: const TextStyle(
                                                    color: AppTheme
                                                        .onBackgroundColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Row(
                                                  children: [
                                                    _buildPerfStat(
                                                      'G',
                                                      perf.goals,
                                                    ),
                                                    _buildPerfStat(
                                                      'A',
                                                      perf.assists,
                                                    ),
                                                    _buildPerfStat(
                                                      'Y',
                                                      perf.yellowCards,
                                                    ),
                                                    _buildPerfStat(
                                                      'R',
                                                      perf.redCards,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                    Text(
                                                      ' ${perf.rating.toStringAsFixed(1)}',
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPerfStat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.onBackgroundSubtle,
              fontSize: 12,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppTheme.onBackgroundMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
