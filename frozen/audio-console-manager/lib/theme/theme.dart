import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.primary,
        background: AppColors.background,
        onPrimary: AppColors.accent,
        onSecondary: AppColors.accent,
        onSurface: AppColors.accent,
        onBackground: AppColors.accent,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.accent),
        bodyMedium: TextStyle(color: AppColors.accent),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.accent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.secondary,
        inactiveTrackColor: AppColors.primary.withOpacity(0.5),
        thumbColor: AppColors.secondary,
        overlayColor: AppColors.secondary.withAlpha(51),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
        trackShape: const RectangularSliderTrackShape(),
        valueIndicatorColor: AppColors.secondary,
        valueIndicatorTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        disabledActiveTrackColor: Colors.grey,
        disabledInactiveTrackColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.primary, // Texto oscuro sobre fondo amarillo
          backgroundColor: AppColors.secondary, // Fondo amarillo
          shadowColor: Colors.black.withOpacity(0.5),
          elevation: 4,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
