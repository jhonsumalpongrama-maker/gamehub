import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color cyan = Color(0xFF00FBFF);
  static const Color pink = Color(0xFFFF006E);
  static const Color green = Color(0xFF39FF14);
  static const Color amber = Color(0xFFFFB800);
  static const Color purple = Color(0xFFBC13FE);
  static const Color glassBase = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const Color checkRed = Color(0xFFFF4D4D);
  static const Color moveHint = Color(0xFF39FF14);

  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalSilver = Color(0xFFA9A9A9);
  static const Color medalBronze = Color(0xFFCD7F32);
}

class AppTextStyles {
  static TextStyle get title => GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 8.0,
  );

  static TextStyle get subtitle => GoogleFonts.rajdhani(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white24,
    letterSpacing: 2,
  );

  static TextStyle neonTitle(Color color) => GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: color,
    letterSpacing: 4,
    shadows: [Shadow(color: color, blurRadius: 10)],
  );

  static TextStyle get cardTitle => GoogleFonts.rajdhani(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static TextStyle get label => GoogleFonts.rajdhani(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static TextStyle get score => GoogleFonts.orbitron(
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static TextStyle get body => GoogleFonts.rajdhani(
    fontSize: 12,
    color: Colors.white54,
  );
}