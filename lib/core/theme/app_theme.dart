import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryWithOpacity10,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryWithOpacity10,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildTextTheme(AppColors.textPrimaryLight),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      cardTheme: _buildCardTheme(AppColors.surfaceLight),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(false),
      bottomNavigationBarTheme: _buildBottomNavTheme(false),
      navigationBarTheme: _buildNavigationBarTheme(false),
      chipTheme: _buildChipTheme(false),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: _buildSnackBarTheme(false),
      dialogTheme: _buildDialogTheme(false),
      floatingActionButtonTheme: _buildFabTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.secondary,
        onPrimary: AppColors.backgroundDark,
        primaryContainer: const Color(0xFF1A3A5C),
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF1B3A8A).withValues(alpha: 0.3),
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),
      appBarTheme: _buildAppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
      ),
      cardTheme: _buildCardTheme(AppColors.cardDark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(true),
      bottomNavigationBarTheme: _buildBottomNavTheme(true),
      navigationBarTheme: _buildNavigationBarTheme(true),
      chipTheme: _buildChipTheme(true),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: _buildSnackBarTheme(true),
      dialogTheme: _buildDialogTheme(true),
      floatingActionButtonTheme: _buildFabTheme(),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 40, fontWeight: FontWeight.w700, color: textColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700, color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500, color: textColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500, color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400, color: textColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: textColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400, color: textColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600, color: textColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10, fontWeight: FontWeight.w600, color: textColor,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color surfaceColor) {
    return CardThemeData(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(0),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: labelColor,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: labelColor.withValues(alpha: 0.6),
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(bool isDark) {
    return NavigationBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      indicatorColor: AppColors.primaryWithOpacity10,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return IconThemeData(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          size: 24,
        );
      }),
    );
  }

  static ChipThemeData _buildChipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
      selectedColor: AppColors.primaryWithOpacity10,
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(bool isDark) {
    return SnackBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.textPrimaryLight,
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    );
  }

  static DialogThemeData _buildDialogTheme(bool isDark) {
    return DialogThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
