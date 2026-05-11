import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/report.dart';
import 'package:real_galaxy/services/report_service.dart';
import 'package:real_galaxy/services/player_service.dart';
import 'package:real_galaxy/services/team_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const ReportsScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final PlayerServiceImpl _playerService = PlayerServiceImpl();
  final TeamServiceImplementation _teamService = TeamServiceImplementation();
  List<Report> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    // Start with loading state
    setState(() => _isLoading = true);

    try {
      // Get reports with timeout
      final reports = await _reportService.getAllReports().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );

      // Sort and update UI progressively
      reports.sort((a, b) => a.generatedAt.compareTo(b.generatedAt));

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      // Ensure loading state is cleared even on error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showGenerateReportDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Generate Report',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.userRole == Role.owner ||
                widget.userRole == Role.director ||
                widget.userRole == Role.admin)
              ListTile(
                leading: const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'Player Progress Report',
                  style: TextStyle(color: AppTheme.onBackgroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _generatePlayerProgressReport();
                },
              ),
            if (widget.userRole == Role.owner ||
                widget.userRole == Role.director ||
                widget.userRole == Role.admin ||
                widget.userRole == Role.coach)
              ListTile(
                leading: const Icon(Icons.groups, color: AppTheme.primaryColor),
                title: const Text(
                  'Team Performance Report',
                  style: TextStyle(color: AppTheme.onBackgroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _generateTeamPerformanceReport();
                },
              ),
            if (widget.userRole == Role.owner ||
                widget.userRole == Role.director ||
                widget.userRole == Role.admin)
              ListTile(
                leading: const Icon(
                  Icons.attach_money,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'Financial Summary Report',
                  style: TextStyle(color: AppTheme.onBackgroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _generateFinancialReport();
                },
              ),
            if (widget.userRole == Role.owner ||
                widget.userRole == Role.director)
              ListTile(
                leading: const Icon(
                  Icons.summarize,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'Monthly Academy Report',
                  style: TextStyle(color: AppTheme.onBackgroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _generateMonthlyReport();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlayerProgressReport() async {
    final players = await _playerService.getAllPlayers();
    if (players.isEmpty) {
      _showSnackBar('No players available');
      return;
    }

    final selectedPlayer = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Select Player',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                players[index].name,
                style: const TextStyle(color: AppTheme.onBackgroundColor),
              ),
              onTap: () => Navigator.pop(context, players[index]),
            ),
          ),
        ),
      ),
    );

    if (selectedPlayer != null) {
      setState(() => _isLoading = true);
      await _reportService.generatePlayerProgressReport(
        playerId: selectedPlayer.id!,
        playerName: selectedPlayer.name,
        generatedBy: widget.userId,
      );
      await _loadReports();
      _showSnackBar('Report generated successfully');
    }
  }

  Future<void> _generateTeamPerformanceReport() async {
    final teams = await _teamService.getAllTeams();
    if (teams.isEmpty) {
      _showSnackBar('No teams available');
      return;
    }

    final selectedTeam = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Select Team',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                teams[index].name,
                style: const TextStyle(color: AppTheme.onBackgroundColor),
              ),
              subtitle: Text(
                teams[index].ageGroup,
                style: const TextStyle(color: AppTheme.onBackgroundSubtle),
              ),
              onTap: () => Navigator.pop(context, teams[index]),
            ),
          ),
        ),
      ),
    );

    if (selectedTeam != null) {
      setState(() => _isLoading = true);
      await _reportService.generateTeamPerformanceReport(
        teamId: selectedTeam.id!,
        teamName: selectedTeam.name,
        generatedBy: widget.userId,
      );
      await _loadReports();
      _showSnackBar('Report generated successfully');
    }
  }

  Future<void> _generateFinancialReport() async {
    setState(() => _isLoading = true);
    await _reportService.generateFinancialSummaryReport(
      generatedBy: widget.userId,
    );
    await _loadReports();
    _showSnackBar('Financial report generated');
  }

  Future<void> _generateMonthlyReport() async {
    setState(() => _isLoading = true);
    await _reportService.generateMonthlyAcademyReport(
      generatedBy: widget.userId,
    );
    await _loadReports();
    _showSnackBar('Monthly report generated');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  void _showReportDetails(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          report.title,
          style: const TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: SingleChildScrollView(
          child: Text(
            report.content,
            style: const TextStyle(
              color: AppTheme.onBackgroundMuted,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate =
        widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin ||
        widget.userRole == Role.coach;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: canGenerate
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _showGenerateReportDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _reports.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppTheme.onBackgroundFaint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      color: AppTheme.onBackgroundSubtle,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reports will appear here',
                    style: TextStyle(color: AppTheme.onBackgroundFaint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        report.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      report.title,
                      style: const TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.typeDisplay,
                          style: const TextStyle(
                            color: AppTheme.onBackgroundSubtle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(report.generatedAt),
                          style: const TextStyle(
                            color: AppTheme.onBackgroundFaint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.onBackgroundSubtle,
                    ),
                    onTap: () => _showReportDetails(report),
                  ),
                );
              },
            ),
    );
  }
}
