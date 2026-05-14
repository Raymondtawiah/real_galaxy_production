import 'dart:io';

import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/models/video.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const VideoListScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Video> _videos = [];
  final Map<String, Player> _playerCache = {};
  bool _isLoading = true;
  String? _selectedPlayerId;
  List<Player> _availablePlayers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadAvailablePlayers();
  }

  Future<void> _loadAvailablePlayers() async {
    try {
      _availablePlayers = await _firebaseService.getAllPlayers();
      setState(() {});
    } catch (e) {
      print('Error loading available players: $e');
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      List<Video> videos;
      switch (widget.userRole) {
        case Role.owner:
        case Role.director:
        case Role.admin:
          videos = await _firebaseService.getAllVideos();
          break;
        case Role.coach:
          videos = await _firebaseService.getAllVideos();
          break;
        case Role.parent:
          videos = await _firebaseService.getVideosForParent(widget.userId);
          break;
      }

      final playerIds = videos.map((v) => v.playerId).toSet();
      for (var playerId in playerIds) {
        if (playerId.isNotEmpty) {
          final player = await _firebaseService.getPlayer(playerId);
          if (player != null) {
            _playerCache[playerId] = player;
          }
        }
      }

      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading videos: $e');
      setState(() => _isLoading = false);
    }
  }

  bool get _canUpload {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin;
  }

  bool get _canDelete {
    return widget.userRole == Role.owner ||
        widget.userRole == Role.director ||
        widget.userRole == Role.admin;
  }

  List<Video> get _filteredVideos {
    if (_searchQuery.isEmpty) return _videos;
    final query = _searchQuery.toLowerCase();
    return _videos.where((video) {
      final player = _playerCache[video.playerId];
      final playerName = player?.name.toLowerCase() ?? '';
      return playerName.contains(query);
    }).toList();
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoUploadScreen(userRole: widget.userRole, userId: widget.userId),
      ),
    );
    if (result == true) {
      _loadVideos();
    }
  }

  Future<void> _navigateToVideoPlayer(Video video) async {
    String playUrl = video.videoUrl;

    // Convert gs:// URLs to HTTPS download URLs if needed
    if (playUrl.startsWith('gs://')) {
      try {
        setState(() => _isLoading = true);
        final ref = FirebaseStorage.instance.refFromURL(playUrl);
        playUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get video URL: $e'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            VideoPlayerScreen(video: video.copyWith(videoUrl: playUrl)),
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _deleteVideo(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Video',
          style: TextStyle(color: AppTheme.onBackgroundColor),
        ),
        content: Text(
          'Are you sure you want to delete this video?',
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

    if (confirm == true && video.id != null) {
      try {
        await _firebaseService.deleteVideo(video.id!);
        if (mounted) {
          setState(() {
            _videos.removeWhere((v) => v.id == video.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video deleted'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildVideoCard(Video video, Player? player) {
    return InkWell(
      onTap: () => _navigateToVideoPlayer(video),
      borderRadius: BorderRadius.circular(8),
      child: Card(
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
                    player?.name ?? 'Unknown Player',
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
            if (_canDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteVideo(video),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: _canUpload
            ? [
                IconButton(
                  onPressed: _navigateToUpload,
                  icon: const Icon(Icons.add),
                  tooltip: 'Upload Video',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? const Center(child: Text('No videos found'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    style: const TextStyle(color: AppTheme.onBackgroundColor),
                    decoration: InputDecoration(
                      hintText: 'Search by player name...',
                      hintStyle: const TextStyle(
                        color: AppTheme.onBackgroundSubtle,
                      ),
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
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                Expanded(
                  child: _filteredVideos.isEmpty
                      ? const Center(
                          child: Text(
                            'No videos match your search',
                            style: TextStyle(
                              color: AppTheme.onBackgroundSubtle,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _filteredVideos.length,
                          itemBuilder: (context, index) {
                            final video = _filteredVideos[index];
                            final player = _playerCache[video.playerId];
                            return _buildVideoCard(video, player);
                          },
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

  const VideoUploadScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlayerId;
  File? _selectedVideoFile;
  File? _selectedThumbnailFile;
  List<Player> _players = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      setState(() => _selectedVideoFile = file);
    }
  }

  Future<void> _pickThumbnailFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      setState(() => _selectedThumbnailFile = file);
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a player'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Upload video file to Firebase Storage
      final videoFileName =
          '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
      final videoRef = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child(videoFileName);

      await videoRef.putFile(_selectedVideoFile!);
      final videoUrl = await videoRef.getDownloadURL();

      // Upload thumbnail if provided
      String? thumbnailUrl;
      if (_selectedThumbnailFile != null) {
        final thumbnailFileName =
            '${DateTime.now().millisecondsSinceEpoch}_thumbnail.jpg';
        final thumbnailRef = FirebaseStorage.instance
            .ref()
            .child('thumbnails')
            .child(thumbnailFileName);

        await thumbnailRef.putFile(_selectedThumbnailFile!);
        thumbnailUrl = await thumbnailRef.getDownloadURL();
      }

      // Create video record
      final video = Video(
        playerId: _selectedPlayerId!,
        uploadedBy: widget.userId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
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
                      onChanged: (value) =>
                          setState(() => _selectedPlayerId = value),
                      validator: (value) =>
                          value == null ? 'Please select a player' : null,
                    ),
                    const SizedBox(height: 16),
                    // Video file selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video File',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedVideoFile != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected: ${_selectedVideoFile!.path.split('/').last}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ElevatedButton.icon(
                            onPressed: _pickVideoFile,
                            icon: const Icon(Icons.video_file),
                            label: Text(
                              _selectedVideoFile == null
                                  ? 'Select Video File'
                                  : 'Change Video',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Thumbnail file selection (optional)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thumbnail (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedThumbnailFile != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected: ${_selectedThumbnailFile!.path.split('/').last}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          OutlinedButton.icon(
                            onPressed: _pickThumbnailFile,
                            icon: const Icon(Icons.image),
                            label: Text(
                              _selectedThumbnailFile == null
                                  ? 'Select Thumbnail (Optional)'
                                  : 'Change Thumbnail',
                            ),
                          ),
                        ],
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
    super.dispose();
  }
}
