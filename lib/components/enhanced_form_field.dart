import 'package:flutter/material.dart';
import 'package:real_galaxy/models/role.dart';

class EnhancedFormField extends StatelessWidget {
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final Role role;

  const EnhancedFormField({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == Role.owner;

    return Container(
      decoration: isOwner
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        style: TextStyle(
          color: isOwner ? const Color(0xFF374151) : Colors.white,
          fontSize: isOwner ? 16 : 14,
          fontWeight: isOwner ? FontWeight.w500 : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: isOwner ? const Color(0xFF64748B) : Colors.white70,
            fontWeight: isOwner ? FontWeight.w500 : FontWeight.normal,
          ),
          hintStyle: TextStyle(
            color: isOwner ? const Color(0xFF94A3B8) : Colors.white38,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: isOwner ? const Color(0xFF3B82F6) : const Color(0xFFDC143C),
                  size: isOwner ? 24 : 20,
                )
              : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: isOwner ? BorderRadius.circular(16) : BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: isOwner ? BorderRadius.circular(16) : BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: isOwner ? BorderRadius.circular(16) : BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isOwner ? const Color(0xFF3B82F6) : const Color(0xFFDC143C),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isOwner ? 20 : 16,
            vertical: isOwner ? 16 : 12,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
