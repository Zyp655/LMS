import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF0D9488);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color accent = Color(0xFF4ADE80);

  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111B2E);
  static const Color darkSurfaceVariant = Color(0xFF172338);
  static const Color darkCard = Color(0xFF152033);
  static const Color darkBorder = Color(0xFF1E3048);
  static const Color darkDivider = Color(0xFF162740);

  static const Color lightBackground = Color(0xFFF0FDFA);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF0FDFA);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFCCFBF1);
  static const Color lightDivider = Color(0xFFE2E8F0);

  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFF8899AA);
  static const Color textDisabledDark = Color(0xFF506070);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  static const Color success = Color(0xFF4ADE80);
  static const Color successLight = Color(0xFFBBF7D0);
  static const Color successDark = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFDE68A);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFECACA);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFBFDBFE);
  static const Color infoDark = Color(0xFF2563EB);

  static const List<Color> chartColors = [
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
    Color(0xFFEF4444),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF111B2E), Color(0xFF172338)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B1120), Color(0xFF0D3B3B), Color(0xFF0B1120)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color divider(BuildContext context) =>
      isDark(context) ? darkDivider : lightDivider;
}
