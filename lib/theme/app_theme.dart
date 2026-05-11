import 'package:flutter/material.dart';

class AppTheme {
  // Unified Theme - Owner Dashboard Inspired
  static const Color primaryColor = Color(0xFFDC143C); // Wine color
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light background
  static const Color surfaceColor = Color(0xFFFFFFFF); // White surfaces
  static const Color surfaceVariantColor = Color(0xFFF8FAFC); // Light variant
  static const Color successColor = Color(0xFF10B981); // Green for success

  // Owner-specific colors
  static const Color accentColor = Color(0xFF3B82F6); // Blue accent
  static const Color textPrimary = Color(0xFF374151); // Dark gray text
  static const Color textSecondary = Color(0xFF64748B); // Muted text
  static const Color textMuted = Color(0xFF94A3B8); // Light text
  static const Color borderColor = Color(0xFFE2E8F0); // Light borders
  static const Color shadowColor = Color(0xFFE5E7EB); // Light shadows

  static const Color onBackgroundColor = Color(
    0xFF374151,
  ); // Dark text on light
  static const Color onSurfaceColor = Color(
    0xFF374151,
  ); // Dark text on surfaces
  static const Color onPrimaryColor = Colors.white; // White text on wine
  static const Color onAccentColor = Colors.white; // White text on blue

  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Backward compatibility properties
  static const Color onBackgroundMuted = textSecondary;
  static const Color onBackgroundSubtle = textMuted;
  static const Color onBackgroundFaint = textMuted;
  static const Color outlineColor = borderColor;
  static const Color onBackgroundColor12 = textMuted;

  static final ThemeData themeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      secondary: successColor,
      onSecondary: onPrimaryColor,
      error: errorColor,
      onError: onPrimaryColor,
      background: backgroundColor,
      onBackground: onBackgroundColor,
    ),
    useMaterial3: true,

    // Enhanced AppBar with owner styling
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      elevation: 4,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: onPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: onPrimaryColor, size: 24),
    ),

    // Enhanced ElevatedButton with owner styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Enhanced Input Decoration with owner styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIconColor: accentColor,
      suffixIconColor: textSecondary,
    ),

    // Enhanced Dialog with owner styling
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: textSecondary, fontSize: 16),
    ),

    // Enhanced Card with owner styling
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),

    // Enhanced Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
