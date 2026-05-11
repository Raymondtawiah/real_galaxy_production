class Video {
  final String? id;
  final String playerId;
  final String uploadedBy;
  final String videoUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;

  Video({
    this.id,
    required this.playerId,
    required this.uploadedBy,
    required this.videoUrl,
    this.thumbnailUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'uploaded_by': uploadedBy,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Video.fromMap(String id, Map<String, dynamic> map) {
    return Video(
      id: id,
      playerId: map['player_id'] ?? '',
      uploadedBy: map['uploaded_by'] ?? '',
      videoUrl: map['video_url'] ?? '',
      thumbnailUrl: map['thumbnail_url'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Video copyWith({
    String? playerId,
    String? uploadedBy,
    String? videoUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return Video(
      id: id,
      playerId: playerId ?? this.playerId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

