import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.white,
      background: AppColors.backgroundLight,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onError: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      titleTextStyle: AppStyles.appBarTitle,
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    textTheme: const TextTheme(
      headlineLarge: AppStyles.headlineLarge,
      headlineMedium: AppStyles.headlineMedium,
      headlineSmall: AppStyles.headlineSmall,
      bodyLarge: AppStyles.bodyLarge,
      bodyMedium: AppStyles.bodyMedium,
      bodySmall: AppStyles.bodySmall,
      labelLarge: AppStyles.buttonText, // For buttons
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: AppStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    // Add more theme properties as needed
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.accentDark,
      surface: AppColors.darkGrey,
      background: AppColors.backgroundDark,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textLight,
      onBackground: AppColors.textLight,
      onError: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.white,
      titleTextStyle: AppStyles.appBarTitle, // Can be a dark specific style
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    textTheme: TextTheme(
      headlineLarge: AppStyles.headlineLarge.copyWith(color: AppColors.textLight), // Using dark specific style
      headlineMedium: AppStyles.headlineMedium.copyWith(color: AppColors.textLight),
      headlineSmall: AppStyles.headlineSmall.copyWith(color: AppColors.textLight),
      bodyLarge: AppStyles.bodyLarge.copyWith(color: AppColors.textLight),
      bodyMedium: AppStyles.bodyMedium.copyWith(color: AppColors.textLight),
      bodySmall: AppStyles.bodySmall.copyWith(color: AppColors.textLight),
      labelLarge: AppStyles.buttonText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        textStyle: AppStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    // Add more dark theme properties as needed
  );
}
