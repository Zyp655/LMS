import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_spacing.dart';

abstract class AppDecorations {
 
  static BoxDecoration get darkCard => BoxDecoration(
    gradient: AppColors.darkCardGradient,
    borderRadius: AppSpacing.borderRadiusLg,
    boxShadow: [darkShadow],
  );

  static BoxDecoration get lightCard => BoxDecoration(
    color: AppColors.lightSurface,
    borderRadius: AppSpacing.borderRadiusLg,
    boxShadow: [lightShadow],
  );

  static BoxDecoration get primaryCard => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppSpacing.borderRadiusLg,
    boxShadow: [primaryShadow],
  );

  static BoxDecoration iconContainer({Color? color, double opacity = 0.2}) =>
      BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: opacity),
        borderRadius: AppSpacing.borderRadiusMd,
      );

  static BoxDecoration circleIconContainer({
    Color? color,
    double opacity = 0.15,
  }) => BoxDecoration(
    color: (color ?? AppColors.primary).withValues(alpha: opacity),
    shape: BoxShape.circle,
  );



  static BoxDecoration statusBadge(Color color) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(10));

  static BoxDecoration get publishedBadge => statusBadge(AppColors.success);
  static BoxDecoration get draftBadge => statusBadge(AppColors.warning);

 

  static InputDecoration darkInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: TextStyle(color: Colors.grey[400]),
    hintStyle: TextStyle(color: Colors.grey[600]),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.darkSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
  );

  

  static BoxShadow get darkShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static BoxShadow get lightShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static BoxShadow get primaryShadow => BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.3),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );


  static const ShapeBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  );

 

  static ShapeBorder get dialogShape =>
      RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg);
  static Widget dragHandle({Color? color}) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: color ?? Colors.grey[700],
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
