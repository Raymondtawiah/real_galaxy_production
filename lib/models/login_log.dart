class LoginLog {
  final String? id;
  final String userId;
  final String ipAddress;
  final String? deviceInfo;
  final bool success;
  final DateTime timestamp;

  LoginLog({
    this.id,
    required this.userId,
    required this.ipAddress,
    this.deviceInfo,
    required this.success,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
      'success': success ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LoginLog.fromMap(String id, Map<String, dynamic> map) {
    return LoginLog(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      ipAddress: map['ip_address'] ?? '',
      deviceInfo: map['device_info'],
      success: map['success'] == true || map['success'] == 1,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

