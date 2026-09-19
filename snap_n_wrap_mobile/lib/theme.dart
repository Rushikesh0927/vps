import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PremiumTheme {
  // Core Colors
  static const Color bgPrimary = Colors.black;
  static const Color bgSecondary = Color(0xFF1D1D1F); // Apple Dark Gray
  static const Color textPrimary = Color(0xFFF5F5F7); // Off-white
  static const Color textSecondary = Color(0xFFA1A1A6); // Apple Light Gray
  
  // Accents (Coral Red for Snap-N-Wrap)
  static const Color accentCoral = Color(0xFFFF5A5F);
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color accentBlue = Color(0xFF0A84FF); // Classic Apple Blue

  // Glassmorphism constants
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accentCoral,
      colorScheme: const ColorScheme.dark(
        primary: accentCoral,
        secondary: accentOrange,
        surface: bgSecondary,
        background: bgPrimary,
      ),
      fontFamily: '.SF Pro Display', // Will use system font on iOS/Mac
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textPrimary),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 17, color: textPrimary, letterSpacing: -0.2), // Apple standard 17pt
        bodyMedium: TextStyle(fontSize: 15, color: textSecondary, letterSpacing: -0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCoral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(980), // Apple pill shape
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
