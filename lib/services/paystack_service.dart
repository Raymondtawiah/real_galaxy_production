import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PaystackService {
  static const String _baseUrl = 'https://api.paystack.co';

  // Ghana Cedis secret key - Use environment variable or build-time variable
  static String get _secretKey {
    // Check for build-time variable first (production builds)
    const buildTimeKey = String.fromEnvironment('PAYSTACK_SECRET_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }

    // Check for environment variables
    const testKey = String.fromEnvironment(
      'PAYSTACK_TEST_KEY',
      defaultValue: '',
    );
    if (testKey.isNotEmpty) {
      return testKey;
    }

    // Development fallback - use test key for flutter run
    if (kDebugMode) {
      return 'sk_test_21b7954c3d95e8e81837b8861ebeab7c67170c4a';
    }

    // Production requires environment variables
    throw Exception(
      'Paystack keys not configured. Please set PAYSTACK_SECRET_KEY environment variable.',
    );
  }

  // For testing, use: sk_testk_21b7954c3d95e8e81837b8861ebeab7c67170c4a
  // For production, use your live key
  static const String _currency = 'GHS';
  static const String _callbackUrl = 'realgalaxy://payment';
  String get callbackUrl => _callbackUrl;

  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  PaystackService._internal();

  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amount,
    required String reference,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final amountInKobo = (amount * 100).toInt();
      debugPrint('Initializing Paystack payment:');
      debugPrint('  Email: $email');
      debugPrint('  Amount: $amountInKobo ($amount GHS)');
      debugPrint('  Reference: $reference');
      debugPrint('  Currency: $_currency');

      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amountInKobo,
          'reference': reference,
          'callback_url': callbackUrl,
          'currency': _currency,
          'metadata': metadata,
        }),
      );

      debugPrint('Paystack response: ${response.statusCode}');
      debugPrint('Paystack body: ${response.body}');

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Paystack initialization error: $e');
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    try {
      debugPrint('Verifying Paystack transaction: $reference');

      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      debugPrint('Verify response: ${response.statusCode}');
      debugPrint('Verify body: ${response.body}');

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Paystack verification error: $e');
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  Future<bool> verifyPayment(String reference, {double? expectedAmount}) async {
    final result = await verifyTransaction(reference);

    debugPrint('Verify result: $result');

    if (result['status'] == true) {
      final data = result['data'];
      final status = data['status'] as String?;
      debugPrint('Transaction status: $status');

      if (status != 'success') return false;

      if (expectedAmount != null) {
        final amountPaid = (data['amount'] as num?)?.toDouble();
        if (amountPaid != null && amountPaid != expectedAmount * 100) {
          debugPrint(
            'Amount mismatch: expected ${expectedAmount * 100}, got $amountPaid',
          );
          return false;
        }
      }

      return true;
    }
    return false;
  }

  String generateReference() {
    return 'RG_${DateTime.now().millisecondsSinceEpoch}';
  }
}
