import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Exact Cyberpunk Colors from original app
  static const Color cyberBg = Color(0xFF06080F);
  static const Color cyberBgSecondary = Color(0xFF0A0E1A);
  static const Color cyberBgTertiary = Color(0xFF0F1629);

  static const Color neonCyan = Color(0xFF00D4FF);
  static const Color neonCyanVariant = Color(0xFF00A8CC);
  static const Color neonPurple = Color(0xFF7C3AED);
  static const Color neonPurpleVariant = Color(0xFF6D28D9);

  static const Color cardBorder = Color(0xFF1E293B);
  static const Color lightText = Color(0xFFF1F5F9);
  static const Color slateText = Color(0xFF94A3B8);
  static const Color dimText = Color(0xFF64748B);

  static const Color greenSuccess = Color(0xFF22C55E);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color redDanger = Color(0xFFEF4444);
  static const Color pinkVariant = Color(0xFFEC4899);

  // Aliases for compatibility
  static const Color primary = neonCyan;
  static const Color accent = neonPurple;
  static const Color danger = redDanger;
  static const Color warning = orangeWarning;
  static const Color success = greenSuccess;
  static const Color darkBg = cyberBg;
  static const Color darkSurface = cyberBgSecondary;
  static const Color darkText = lightText;
  static const Color darkTextMuted = slateText;

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: cyberBg,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonPurple,
      surface: cyberBgSecondary,
      error: redDanger,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: lightText,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: lightText,
      displayColor: lightText,
    ),
    cardTheme: CardThemeData(
      color: cyberBgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: cyberBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cyberBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: lightText, fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: neonCyan),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: cyberBgSecondary,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cyberBgTertiary,
      labelStyle: const TextStyle(color: slateText, fontSize: 13),
      hintStyle: const TextStyle(color: dimText, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: neonCyan, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    dividerColor: cardBorder,
    dividerTheme: const DividerThemeData(color: cardBorder, thickness: 1),
  );

  static ThemeData lightTheme = darkTheme; // Default to the Cyberpunk Dark theme as primary
}
