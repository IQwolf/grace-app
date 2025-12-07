import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EduPulseColors {
  static const primary = Color(0xFF58BBB1);
  static const primaryDark = Color(0xFF1C3F59);
  static const background = Color(0xFFFFF9F0);
  static const surface = Color(0xFFFFFFFF);
  static const textMain = Color(0xFF0F1B22);
  static const divider = Color(0xFFE6ECEC);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const shadow = Color(0x1A000000);
}

class FontSizes {
  static const double displayLarge = 32.0;
  static const double displayMedium = 28.0;
  static const double displaySmall = 24.0;
  static const double headlineLarge = 22.0;
  static const double headlineMedium = 20.0;
  static const double headlineSmall = 18.0;
  static const double titleLarge = 18.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: EduPulseColors.primary,
    onPrimary: Colors.white,
    primaryContainer: EduPulseColors.primary.withValues(alpha: 0.1),
    onPrimaryContainer: EduPulseColors.primaryDark,
    secondary: EduPulseColors.primaryDark,
    onSecondary: Colors.white,
    error: EduPulseColors.error,
    onError: EduPulseColors.onError,
    surface: EduPulseColors.surface,
    onSurface: EduPulseColors.textMain,
    shadow: EduPulseColors.shadow,
  ),
  scaffoldBackgroundColor: EduPulseColors.background,
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: EduPulseColors.textMain,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: GoogleFonts.tajawal(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.tajawal(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.bold,
      color: EduPulseColors.textMain,
    ),
    displayMedium: GoogleFonts.tajawal(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    displaySmall: GoogleFonts.tajawal(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    headlineLarge: GoogleFonts.tajawal(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    headlineMedium: GoogleFonts.tajawal(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    headlineSmall: GoogleFonts.tajawal(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    titleLarge: GoogleFonts.tajawal(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
      color: EduPulseColors.textMain,
    ),
    titleMedium: GoogleFonts.tajawal(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: EduPulseColors.textMain,
    ),
    titleSmall: GoogleFonts.tajawal(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: EduPulseColors.textMain,
    ),
    labelLarge: GoogleFonts.tajawal(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: EduPulseColors.textMain,
    ),
    labelMedium: GoogleFonts.tajawal(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: EduPulseColors.textMain,
    ),
    labelSmall: GoogleFonts.tajawal(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: EduPulseColors.textMain,
    ),
    bodyLarge: GoogleFonts.tajawal(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: EduPulseColors.textMain,
    ),
    bodyMedium: GoogleFonts.tajawal(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: EduPulseColors.textMain,
    ),
    bodySmall: GoogleFonts.tajawal(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: EduPulseColors.textMain,
    ),
  ),
  cardTheme: CardThemeData(
    color: EduPulseColors.surface,
    elevation: 2,
    shadowColor: EduPulseColors.shadow,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: EduPulseColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: EduPulseColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: EduPulseColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: EduPulseColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: EduPulseColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: EduPulseColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    hintStyle: GoogleFonts.tajawal(
      color: EduPulseColors.textMain.withValues(alpha: 0.6),
      fontSize: 16,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: EduPulseColors.surface,
    selectedItemColor: EduPulseColors.primary,
    unselectedItemColor: EduPulseColors.textMain.withValues(alpha: 0.6),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.normal),
  ),
);

ThemeData get darkTheme => lightTheme;