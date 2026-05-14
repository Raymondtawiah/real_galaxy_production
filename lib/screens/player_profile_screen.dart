import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/video.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/screens/player_progress_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  final Role userRole;
  final String userId;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Player? _player;
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print(
      'PlayerProfileScreen initialized for playerId: ${widget.playerId}, userRole: ${widget.userRole.name}',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    print('Starting to load player data for ID: ${widget.playerId}');
    setState(() => _isLoading = true);
    try {
      print('Fetching player from Firebase...');
      _player = await _firebaseService.getPlayer(widget.playerId);
      print('Player loaded: ${_player?.name ?? "NULL"}');
      _videos = await _firebaseService.getVideosByPlayer(widget.playerId);
      print('Videos loaded: ${_videos.length}');
    } catch (e) {
      print('Error loading player profile: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    setState(() => _isLoading = false);
    print(
      'Loading complete. Is loading: $_isLoading, Player is null: ${_player == null}',
    );
  }

  bool get _canUpload {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin;
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoUploadScreen(
          userRole: widget.userRole,
          userId: widget.userId,
          initialPlayerId: widget.playerId,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Widget _buildProgressButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _navigateToProgress,
        icon: const Icon(Icons.trending_up, size: 20),
        label: const Text(
          'View Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToProgress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerProgressScreen(
          playerId: widget.playerId,
          userRole: widget.userRole,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_player?.name ?? 'Player Profile'),
        actions: _canUpload
            ? [
                IconButton(
                  icon: const Icon(Icons.video_call),
                  onPressed: _navigateToUpload,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _player == null
          ? const Center(child: Text('Player not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlayerInfo(),
                  const SizedBox(height: 16),
                  if (widget.userRole == Role.parent) ...[
                    _buildProgressButton(),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Videos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildVideos(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_player!.imageUrl != null && _player!.imageUrl!.isNotEmpty)
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage: NetworkImage(_player!.imageUrl!),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Handle Firebase Storage errors gracefully
                      print('Error loading player image: $exception');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _player!.name.isNotEmpty
                            ? _player!.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      _player!.name.isNotEmpty
                          ? _player!.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _player!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_player!.position != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Position: ${_player!.position}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      ...[
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${_player!.age}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Team: ${_player!.teamId ?? "Not assigned"}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideos() {
    if (_videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No videos found for this player'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Video video) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: video.thumbnailUrl != null
                ? Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.video_file, size: 50),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.video_file, size: 50),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video ${video.id?.substring(0, 8) ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${video.createdAt.day}/${video.createdAt.month}/${video.createdAt.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoUploadScreen extends StatefulWidget {
  final Role userRole;
  final String userId;
  final String? initialPlayerId;

  const VideoUploadScreen({
    super.key,
    required this.userRole,
    required this.userId,
    this.initialPlayerId,
  });

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlayerId;
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  List<Player> _players = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlayerId = widget.initialPlayerId;
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      _players = await _firebaseService.getAllPlayers();
      setState(() {});
    } catch (e) {
      print('Error loading players: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a player'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final video = Video(
        playerId: _selectedPlayerId!,
        uploadedBy: widget.userId,
        videoUrl: _videoUrlController.text.trim(),
        thumbnailUrl: _thumbnailUrlController.text.trim().isNotEmpty
            ? _thumbnailUrlController.text.trim()
            : null,
      );

      await _firebaseService.createVideo(video);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error uploading video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Player',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedPlayerId,
                      items: _players.map((player) {
                        return DropdownMenuItem(
                          value: player.id,
                          child: Text(player.name),
                        );
                      }).toList(),
                      onChanged: widget.initialPlayerId == null
                          ? (value) => setState(() => _selectedPlayerId = value)
                          : null,
                      validator: (value) =>
                          value == null ? 'Please select a player' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter video URL'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _thumbnailUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _uploadVideo,
                      child: const Text('Upload Video'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }
}
