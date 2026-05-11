import 'package:flutter/material.dart';

class OwnerBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const OwnerBadge({
    super.key,
    this.text = 'OWNER',
    this.backgroundColor = const Color(0xFF3B82F6),
    this.textColor = Colors.white,
    this.borderColor = Colors.white,
    this.fontSize = 10,
    this.padding,
    this.borderRadius,
  });

  const OwnerBadge.pro({
    super.key,
    this.text = 'PRO',
    this.backgroundColor = const Color(0xFF10B981),
    this.textColor = const Color(0xFF10B981),
    this.borderColor = const Color(0xFF10B981),
    this.fontSize = 9,
    this.padding,
    this.borderRadius,
  });

  const OwnerBadge.small({
    super.key,
    this.text = 'OWNER',
    this.backgroundColor = const Color(0xFF3B82F6),
    this.textColor = Colors.white,
    this.borderColor = Colors.white,
    this.fontSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
