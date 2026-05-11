import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permission status: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _fcm.getToken();
    print('FCM token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Background message: ${message.notification?.title}');
  }

  static Future<void> initializeStatic() async {
    final service = FirebaseMessagingService._internal();
    await service.initialize();
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> associateTokenWithUser(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _ref.child('fcm_tokens').child(userId).set({
          'token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('FCM token associated with user $userId');
      }
    } catch (e) {
      print('Error associating FCM token: $e');
    }
  }

  Future<void> removeToken(String userId) async {
    try {
      await _ref.child('fcm_tokens').child(userId).remove();
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }
}

