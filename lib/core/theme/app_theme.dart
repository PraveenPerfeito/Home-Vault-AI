import 'package:flutter/material.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/core/theme/app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      secondary: isDark ? AppColors.secondaryLight : AppColors.secondary,
      error: AppColors.error,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    final textColor = isDark ? Colors.white : AppColors.grey800;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: _textTheme(textColor),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: textColor,
        titleTextStyle:
            AppTextStyles.headlineLarge.copyWith(color: textColor),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.transparent : AppColors.grey200,
          ),
        ),
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? AppColors.primaryLight : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(
            color: isDark ? AppColors.grey600 : AppColors.grey200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor:
            isDark ? AppColors.primaryLight : AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.grey800 : AppColors.grey200,
        thickness: 1,
      ),
    );
  }

  static TextTheme _textTheme(Color color) => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: color),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: color),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: color),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: color),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: color),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: color),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: color),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: color),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: color),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: color),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: color),
      );
}
