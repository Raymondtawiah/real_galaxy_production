import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  static final CloudFunctionsService _instance =
      CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Send login notification email via Callable function
  Future<void> sendLoginNotification({
    required String name,
    required String email,
    required String role,
    required String ipAddress,
    required String deviceInfo,
  }) async {
    try {
      await _functions.httpsCallable('sendLoginNotification').call({
        'name': name,
        'email': email,
        'role': role,
        'ipAddress': ipAddress,
        'deviceInfo': deviceInfo,
      });
    } catch (e) {
      print('Cloud Function error (sendLoginNotification): $e');
      rethrow;
    }
  }

  // Create default owner account (callable)
  Future<void> createDefaultOwner() async {
    try {
      await _functions.httpsCallable('createDefaultOwner').call({});
    } catch (e) {
      print('Cloud Function error (createDefaultOwner): $e');
      rethrow;
    }
  }

  // Optional: send password reset email
  Future<void> sendPasswordReset({
    required String email,
    required String resetToken,
  }) async {
    try {
      await _functions.httpsCallable('sendPasswordReset').call({
        'email': email,
        'token': resetToken,
      });
    } catch (e) {
      print('Cloud Function error (sendPasswordReset): $e');
      rethrow;
    }
  }

  // Generic callable function caller
  Future<Map<String, dynamic>> callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(functionName).call(data);
      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Cloud Function error ($functionName): $e');
      rethrow;
    }
  }
}

