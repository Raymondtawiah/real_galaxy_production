import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';

class EnhancedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final Role role;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.icon,
    required this.role,
  });

  const EnhancedButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.padding,
    this.icon,
    required this.role,
    this.borderRadius,
  }) : backgroundColor = null,
       textColor = null;

  const EnhancedButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.padding,
    this.icon,
    required this.role,
    this.borderRadius,
  }) : backgroundColor = const Color(0xFF3B82F6),
       textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              (isOwner ? const Color(0xFFDC143C) : const Color(0xFFDC143C)),
          foregroundColor: textColor ?? Colors.white,
          elevation: isOwner ? 4 : 0,
          shadowColor: isOwner ? const Color(0xFFE5E7EB) : null,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ??
                (isOwner
                    ? BorderRadius.circular(12)
                    : BorderRadius.circular(8)),
          ),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: isOwner ? 16 : 14,
                      fontWeight: isOwner ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
