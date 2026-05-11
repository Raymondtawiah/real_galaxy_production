import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/user.dart' as app_user;
import 'package:real_galaxy/models/login_log.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/cloud_functions_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseService _db = FirebaseService();
  final CloudFunctionsService _cf = CloudFunctionsService();

  static const String _sessionKey = 'auth_session';
  static const String _mustChangePasswordKey = 'must_change_password';

  // Stream of authentication state changes
  Stream<app_user.User?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser != null) {
          final userProfile = await _db.getUserProfile(firebaseUser.uid);
          return userProfile;
        }
        return null;
      });

  // Check if currently authenticated
  Future<bool> isLoggedIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _db.getUserProfile(user.uid);
      return profile != null;
    }
    return false;
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String ipAddress,
    required String deviceInfo,
  }) async {
    fb.UserCredential? credential;
    app_user.User? user;

    try {
      // ===== STEP 1: RATE LIMIT CHECK (fail early) =====
      final canAttempt = await _db.canAttemptLogin(email);
      if (!canAttempt) {
        await _safeLogLogin(
          userId: '',
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: false,
        );
        return {
          'success': false,
          'message': 'Too many login attempts. Please try again later.',
        };
      }

      // ===== STEP 2: FIREBASE AUTHENTICATION =====
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on fb.FirebaseAuthException catch (e) {
        await _db.recordFailedAttempt(email);
        await _safeLogLogin(
          userId: '',
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: false,
        );
        String msg = 'Invalid email or password.';
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          // generic
        } else if (e.code == 'too-many-requests') {
          msg = 'Too many attempts. Try again later.';
        } else {
          msg = 'Authentication failed.';
        }
        return {'success': false, 'message': msg};
      }

      if (credential.user == null) {
        await _safeLogLogin(
          userId: '',
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: false,
        );
        return {'success': false, 'message': 'Authentication failed.'};
      }

      // ===== STEP 3: FETCH USER PROFILE (MUST SUCCEED) =====
      user = await _db.getUserProfile(credential.user!.uid);
      if (user == null) {
        await _auth.signOut();
        await _safeLogLogin(
          userId: '',
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: false,
        );
        return {
          'success': false,
          'message': 'User profile not found. Contact admin.',
        };
      }

      // ===== STEP 4: CHECK IF ACTIVE =====
      if (!user.isActive) {
        await _auth.signOut();
        await _safeLogLogin(
          userId: '',
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: false,
        );
        return {
          'success': false,
          'message': 'Your account has been deactivated. Contact admin.',
        };
      }

      // ===== STEP 5: AUXILIARY OPERATIONS (non-blocking, errors swallowed) =====
      final effectiveMustChange = user.mustChangePassword;

      // These must NOT throw to the outer catch
      await _safeClearAttempts(email);
      await _safeLogLogin(
        userId: user.id ?? '',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        success: true,
      );

      // Save session (non-critical, wrap in try-catch)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sessionKey, true);
        await prefs.setBool(_mustChangePasswordKey, effectiveMustChange);
      } catch (e) {
        print('Failed to save session: $e');
      }

      // Send notification (fire-and-forget, errors ignored)
      _safeSendNotification(
        name: user.name,
        email: email,
        role: user.role.name,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );

      // ===== SUCCESS =====
      return {
        'success': true,
        'user': user,
        'redirect': user.role.route,
        'mustChangePassword': effectiveMustChange,
      };
    } catch (e) {
      // ONLY unexpected/uncaught errors reach here
      print('Unexpected login error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Helper: safe logLogin that never throws
  Future<void> _safeLogLogin({
    required String userId,
    required String ipAddress,
    required String deviceInfo,
    required bool success,
  }) async {
    try {
      await _db.logLogin(
        LoginLog(
          userId: userId,
          ipAddress: ipAddress,
          deviceInfo: deviceInfo,
          success: success,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Failed to log login: $e');
    }
  }

  // Helper: safe clearAttempts that never throws
  Future<void> _safeClearAttempts(String email) async {
    try {
      await _db.clearAttempts(email);
    } catch (e) {
      print('Failed to clear attempts: $e');
    }
  }

  // Helper: safe notification send that never throws
  Future<void> _safeSendNotification({
    required String name,
    required String email,
    required String role,
    required String ipAddress,
    required String deviceInfo,
  }) async {
    try {
      await _cf.sendLoginNotification(
        name: name,
        email: email,
        role: role,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
    } catch (e) {
      print('Failed to send login notification: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Initialize default owner
  Future<void> initializeDefaultOwner() async {
    try {
      final exists = await _db.ownerExists();
      if (exists) return;
      await _cf.createDefaultOwner();
    } catch (e) {
      print('Error initializing default owner: $e');
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Not authenticated.'};
      }

      // Re-authenticate
      final cred = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);

      // Update DB flag and last password change timestamp
      final profile = await _db.getUserProfile(user.uid);
      if (profile != null) {
        await _db.setUserProfile(
          user.uid,
          profile.copyWith(
            mustChangePassword: false,
            updatedAt: DateTime.now(),
            lastPasswordChange: DateTime.now(),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mustChangePasswordKey, false);

      return {'success': true, 'message': 'Password changed successfully.'};
    } on fb.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Failed to change password.',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred.'};
    }
  }

  // Get current user profile
  Future<app_user.User?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _db.getUserProfile(user.uid);
    }
    return null;
  }

  Future<bool> mustChangePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mustChangePasswordKey) ?? false;
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    required String name,
    String? phoneNumber,
  }) async {
    await _db.updateUserProfile(userId, name, phoneNumber: phoneNumber);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
