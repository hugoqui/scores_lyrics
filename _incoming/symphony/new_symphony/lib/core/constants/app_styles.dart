import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';

class AppStyles {
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: AppDimensions.fontSizeExtraLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppDimensions.fontSizeLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppDimensions.fontSizeSmall,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 10.0, // Smaller than AppDimensions.fontSizeSmall
    color: AppColors.textSecondary,
  );

  // Button styles
  static const TextStyle buttonText = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // AppBar title style
  static const TextStyle appBarTitle = TextStyle(
    fontSize: AppDimensions.fontSizeLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}
