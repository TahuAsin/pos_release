import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors (from ALFlow POS logo)
  static const Color primary = Color(0xFF1B3A8A);        // Navy Blue
  static const Color primaryLight = Color(0xFF2850B8);   // Lighter Navy
  static const Color primaryDark = Color(0xFF0F2060);    // Darker Navy

  static const Color secondary = Color(0xFF00C9A7);      // Emerald Teal
  static const Color secondaryLight = Color(0xFF33D4B8); // Lighter Teal
  static const Color secondaryDark = Color(0xFF00A080);  // Darker Teal

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Dark theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Stock status
  static const Color stockLow = Color(0xFFEF4444);
  static const Color stockMedium = Color(0xFFF59E0B);
  static const Color stockGood = Color(0xFF10B981);

  // Transparent
  static const Color transparent = Colors.transparent;
  static const Color primaryWithOpacity10 = Color(0x1A1B3A8A);
  static const Color secondaryWithOpacity10 = Color(0x1A00C9A7);
}
