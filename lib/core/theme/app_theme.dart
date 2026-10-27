import 'package:flutter/material.dart';

abstract final class AppColors {
  static const green = Color(0xFF155F4C);
  static const ink = Color(0xFF19382F);
  static const muted = Color(0xFF62736A);
  static const surface = Colors.white;
  static const background = Color(0xFFF6F8F4);
  static const soft = Color(0xFFE6EFE7);
  static const accent = Color(0xFFDCEBB0);
  static const red = Color(0xFFA53535);
  static const line = Color(0xFFE0E7DF);
}

abstract final class AppTheme {
  static const title = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 26,
    height: 1.3,
    letterSpacing: -.6,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const heading = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 15,
    height: 1.4,
    color: AppColors.ink,
  );
  static const label = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const caption = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 12,
    height: 1.4,
    color: AppColors.muted,
  );
  static const amount = TextStyle(
    fontFamily: 'Noto Sans',
    fontSize: 36,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Noto Sans',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    textTheme: const TextTheme(
      headlineMedium: title,
      titleLarge: heading,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: label,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 3,
      hintStyle: caption.copyWith(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: label,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: AppColors.line,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.green,
    ),
  );
}
