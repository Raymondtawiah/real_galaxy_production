import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/match.dart';
import 'package:real_galaxy/models/team.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/services/firebase_service.dart';

class MatchesScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const MatchesScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Match> _matches = [];
  List<Team> _teams = [];
  List<Player> _players = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _matches = await _firebaseService.getAllMatches();
      _teams = await _firebaseService.getAllTeams();
      _players = await _firebaseService.getAllPlayers();
      _matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
    } catch (e) {
      print('Error loading matches: $e');
    }
    setState(() => _isLoading = false);
  }

  String _getTeamName(String? teamId) {
    if (teamId == null) return 'TBD';
    final teams = _teams.where((t) => t.id == teamId).toList();
    return teams.isNotEmpty ? teams.first.name : 'Unknown';
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return Colors.blue;
      case MatchStatus.ongoing:
        return Colors.orange;
      case MatchStatus.completed:
        return Colors.green;
    }
  }

  String _getStatusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return 'Scheduled';
      case MatchStatus.ongoing:
        return 'Live';
      case MatchStatus.completed:
        return 'Completed';
    }
  }

  Future<void> _showAddMatchDialog() async {
    String? homeTeamId;
    String? awayTeamId;
    DateTime matchDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay matchTime = const TimeOfDay(hour: 10, minute: 0);
    final venueController = TextEditingController();
    CompetitionType compType = CompetitionType.friendly;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Schedule Match',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: homeTeamId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Home Team',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Team'),
                    ),
                    ..._teams.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => homeTeamId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: awayTeamId,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Away Team',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Team'),
                    ),
                    ..._teams.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => awayTeamId = v),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${matchDate.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryColor,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: matchDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => matchDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Time: ${matchTime.format(context)}',
                    style: const TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  trailing: const Icon(
                    Icons.access_time,
                    color: AppTheme.primaryColor,
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: matchTime,
                    );
                    if (time != null) setDialogState(() => matchTime = time);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: venueController,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CompetitionType>(
                  initialValue: compType,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Competition',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: CompetitionType.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.name[0].toUpperCase() + c.name.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => compType = v!),
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
                String? errorMsg;
                if (homeTeamId == null) {
                  errorMsg = 'Please select a home team';
                } else if (awayTeamId == null) {
                  errorMsg = 'Please select an away team';
                } else if (homeTeamId == awayTeamId) {
                  errorMsg = 'Home and away teams must be different';
                }
                if (errorMsg != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                  return;
                }
                try {
                  final combinedDate = DateTime(
                    matchDate.year,
                    matchDate.month,
                    matchDate.day,
                    matchTime.hour,
                    matchTime.minute,
                  );
                  final match = Match(
                    homeTeamId: homeTeamId!,
                    awayTeamId: awayTeamId!,
                    matchDate: combinedDate,
                    venue: venueController.text.isNotEmpty
                        ? venueController.text
                        : null,
                    competitionType: compType,
                  );
                  await _firebaseService.createMatch(match);
                  await _loadData();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating match: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateScoreDialog(Match match) async {
    int? homeScore = match.homeScore;
    int? awayScore = match.awayScore;
    MatchStatus status = match.status;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Update Match Result',
            style: TextStyle(color: AppTheme.onBackgroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _getTeamName(match.homeTeamId),
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          hintText: '-',
                          hintStyle: TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) => homeScore = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '-',
                      style: TextStyle(
                        color: AppTheme.onBackgroundColor,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          hintText: '-',
                          hintStyle: TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) => awayScore = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getTeamName(match.awayTeamId),
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MatchStatus>(
                  initialValue: status,
                  dropdownColor: AppTheme.surfaceVariantColor,
                  style: const TextStyle(color: AppTheme.onBackgroundColor),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
                  ),
                  items: MatchStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_getStatusLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
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
                final updatedMatch = match.copyWith(
                  homeScore: homeScore,
                  awayScore: awayScore,
                  status: status,
                );
                await _firebaseService.updateMatch(match.id!, updatedMatch);
                await _loadData();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditVenueDialog(Match match) async {
    final venueController = TextEditingController(text: match.venue ?? '');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Edit Venue',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: TextField(
          controller: venueController,
          style: const TextStyle(color: AppTheme.onBackgroundColor),
          decoration: const InputDecoration(
            labelText: 'Venue',
            labelStyle: TextStyle(color: AppTheme.onBackgroundMuted),
            hintText: 'Enter venue location',
            hintStyle: TextStyle(color: AppTheme.onBackgroundFaint),
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
              final updatedMatch = match.copyWith(
                venue: venueController.text.isNotEmpty
                    ? venueController.text
                    : null,
              );
              await _firebaseService.updateMatch(match.id!, updatedMatch);
              await _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMatch(Match match) async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Match',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: const Text(
          'Are you sure?',
          style: TextStyle(color: AppTheme.onBackgroundMuted),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onBackgroundMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _isDeleting ? null : () => Navigator.pop(context, true),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onBackgroundColor,
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && match.id != null) {
      setState(() => _isDeleting = true);
      try {
        await _firebaseService.deleteMatch(match.id!);
        await _loadData();
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  bool get _canManage {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin ||
        widget.userRole == Role.coach;
  }

  List<Match> get _filteredMatches {
    // For now, show all matches but add medical clearance warnings
    // In a real implementation, you'd filter matches based on player medical clearance
    return _matches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: _canManage
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _showAddMatchDialog,
              child: const Icon(Icons.add, color: AppTheme.onBackgroundColor),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _matches.isEmpty
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
                    'No matches scheduled',
                    style: TextStyle(
                      color: AppTheme.onBackgroundSubtle,
                      fontSize: 18,
                    ),
                  ),
                  if (_canManage)
                    const Text(
                      'Tap + to create a match',
                      style: TextStyle(color: AppTheme.onBackgroundFaint),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMatches.length,
              itemBuilder: (context, index) {
                final match = _filteredMatches[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          match.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: _getStatusColor(match.status),
                      ),
                    ),
                    title: Text(
                      '${_getTeamName(match.homeTeamId)} vs ${_getTeamName(match.awayTeamId)}',
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
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AppTheme.onBackgroundSubtle,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year} ${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppTheme.onBackgroundMuted,
                              ),
                            ),
                          ],
                        ),
                        if (match.venue != null && match.venue!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.onBackgroundSubtle,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  match.venue!,
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundSubtle,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  match.status,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusLabel(match.status),
                                style: TextStyle(
                                  color: _getStatusColor(match.status),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                match.competitionType.name[0].toUpperCase() +
                                    match.competitionType.name.substring(1),
                                style: const TextStyle(
                                  color: AppTheme.onBackgroundSubtle,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${match.homeScore ?? '-'} - ${match.awayScore ?? '-'}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: _canManage && !_isDeleting
                        ? PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppTheme.onBackgroundMuted,
                            ),
                            color: AppTheme.surfaceVariantColor,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'score',
                                child: Text(
                                  'Update Score',
                                  style: TextStyle(
                                    color: AppTheme.onBackgroundColor,
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'venue',
                                child: Text(
                                  'Edit Venue',
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
                              if (value == 'score') {
                                _showUpdateScoreDialog(match);
                              } else if (value == 'venue')
                                _showEditVenueDialog(match);
                              else if (value == 'delete')
                                _deleteMatch(match);
                            },
                          )
                        : _isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
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
