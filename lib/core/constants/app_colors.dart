import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Energy Accents
  static const Color primary = Color(0xFF0052CC); // Deep Royal Blue
  static const Color primaryDark = Color(0xFF073B8C);
  static const Color primaryLight = Color(0xFF2684FF);
  
  // Energetic Accent / Fire & Speed (CTAs, Offers, Urgency)
  static const Color accentFlame = Color(0xFFFF5630); // Fire Coral / Orange
  static const Color accentFlameLight = Color(0xFFFF7A00);
  static const Color accentFlameDark = Color(0xFFDE350B);
  
  // Clean Cyan / Gas Aura
  static const Color gasCyan = Color(0xFF00C7E6);
  static const Color gasCyanLight = Color(0xFFE6FCFF);

  // Status & Feedback
  static const Color success = Color(0xFF36B37E);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5630);
  static const Color info = Color(0xFF0065FF);

  // Surfaces & Backgrounds - Light
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F4F9);
  static const Color border = Color(0xFFE2E8F0);

  // Surfaces & Backgrounds - Dark
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF1C2541);
  static const Color darkSurfaceVariant = Color(0xFF253258);
  static const Color darkBorder = Color(0xFF2F3E68);

  // Neutral Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0052CC), Color(0xFF2684FF)],
  );

  static const LinearGradient flameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A00), Color(0xFFFF5630)],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1736), Color(0xFF040A1A)],
  );
}
