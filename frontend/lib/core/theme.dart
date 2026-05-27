import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const colorPrimary     = Color(0xFF2563EB);  // Cobalt blue
  static const colorPrimaryDark = Color(0xFF1D4ED8);
  static const colorPrimaryLight= Color(0xFFEFF6FF);  // Blue tint bg
  static const colorBg          = Color(0xFFF8FAFC);  // Near-white
  static const colorSurface     = Color(0xFFFFFFFF);
  static const colorTextPrimary = Color(0xFF0F172A);  // Deep slate
  static const colorTextMuted   = Color(0xFF64748B);
  static const colorSuccess     = Color(0xFF10B981);  // Emerald
  static const colorSuccessLight= Color(0xFFECFDF5);
  static const colorError       = Color(0xFFEF4444);  // Red
  static const colorErrorLight  = Color(0xFFFEF2F2);
  static const colorWarning     = Color(0xFFF59E0B);  // Amber
  static const colorWarningLight= Color(0xFFFFFBEB);
  static const colorBorder      = Color(0xFFE2E8F0);
  static const colorDivider     = Color(0xFFF1F5F9);

  /// Format price from cents to rupee string  e.g. 8000 → "₹80"
  static String formatPrice(int cents) {
    final rupees = cents / 100;
    if (rupees == rupees.truncate()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Format price compact  e.g. 8000 → "₹80/session"
  static String formatPriceWithSuffix(int cents) {
    return '${formatPrice(cents)}/session';
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrimary,
        surface: colorSurface,
      ),
      scaffoldBackgroundColor: colorBg,
      cardTheme: CardThemeData(
        color: colorSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: colorBorder, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: colorSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorTextPrimary),
        titleTextStyle: TextStyle(
          color: colorTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: colorPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: colorPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: colorTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: colorTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: colorTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: colorTextPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: colorTextMuted,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: colorTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
