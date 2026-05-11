/// Result of a password reset operation
class PasswordResetResult {
  final bool success;
  final String message;
  final String? userId;
  final String? resetToken;

  PasswordResetResult({
    required this.success,
    required this.message,
    this.userId,
    this.resetToken,
  });
}
