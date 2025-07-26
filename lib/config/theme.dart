import 'package:flutter/material.dart';

class AppTheme {
  // Color constants - Updated to orange color scheme
  static const Color primaryColor = Color(0xFFFF7F24); // Vibrant orange
  static const Color accentColor = Color(0xFFFFA76A); // Light orange accent
  static const Color darkAccentColor =
      Color(0xFFE65C00); // Darker orange accent
  static const Color backgroundColor = Color(0xFFFFFAF5); // Warm off-white
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF333340); // Dark grey for text
  static const Color textSecondaryColor =
      Color(0xFF686877); // Medium grey for secondary text

  // Single theme - no light/dark mode
  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      tertiary: darkAccentColor,
      background: backgroundColor,
      surface: cardColor,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimaryColor),
      titleMedium: TextStyle(fontFamily: 'Poppins', color: textPrimaryColor),
      titleSmall: TextStyle(fontFamily: 'Poppins', color: textPrimaryColor),
      bodyLarge: TextStyle(fontFamily: 'Poppins', color: textPrimaryColor),
      bodyMedium: TextStyle(fontFamily: 'Poppins', color: textSecondaryColor),
      bodySmall: TextStyle(fontFamily: 'Poppins', color: textSecondaryColor),
      labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: textPrimaryColor),
      labelMedium: TextStyle(fontFamily: 'Poppins', color: textPrimaryColor),
      labelSmall: TextStyle(fontFamily: 'Poppins', color: textSecondaryColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle:
          const TextStyle(fontFamily: 'Poppins', color: textSecondaryColor),
      hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  // Simple gradient for accents
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Basic subtle background gradient
  static LinearGradient backgroundGradient = const LinearGradient(
    colors: [backgroundColor, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glassmorphism effect - fixed to not require context
  static BoxDecoration glassEffect({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.grey[100]!,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
