import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.darkOlive,
        onPrimary: AppColors.cream,
        secondary: AppColors.warmGolden,
        onSecondary: AppColors.deepCharcoal,
        error: Color(0xFFB00020),
        onError: AppColors.cream,
        surface: AppColors.creamSurface,
        onSurface: AppColors.deepCharcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.deepCharcoal),
        titleTextStyle: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkOlive,
          foregroundColor: AppColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkOlive,
          side: const BorderSide(color: AppColors.darkOlive, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamSurface,
        hintStyle: const TextStyle(color: AppColors.mutedCharcoal, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.deepCharcoal, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderCharcoal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderCharcoal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkOlive, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.deepCharcoal,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
