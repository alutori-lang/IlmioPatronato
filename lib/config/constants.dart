import 'package:flutter/material.dart';

class AppColors {
  // Primary blues
  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D2D5E);
  static const primaryLight = Color(0xFF42A5F5);
  static const headerStart = Color(0xFF0A1628);
  static const headerMid = Color(0xFF0D2D5E);
  static const headerEnd = Color(0xFF143D7A);

  // Service card icon backgrounds
  static const serviceBlueLight = Color(0xFFE3F2FD);
  static const serviceBlueMed = Color(0xFFBBDEFB);
  static const serviceGreenLight = Color(0xFFE8F5E9);
  static const serviceGreenMed = Color(0xFFC8E6C9);
  static const serviceOrangeLight = Color(0xFFFFF3E0);
  static const serviceOrangeMed = Color(0xFFFFE0B2);
  static const servicePurpleLight = Color(0xFFF3E5F5);
  static const servicePurpleMed = Color(0xFFE1BEE7);

  // Service icon colors
  static const iconBlue = Color(0xFF1565C0);
  static const iconGreen = Color(0xFF2E7D32);
  static const iconOrange = Color(0xFFE65100);
  static const iconPurple = Color(0xFF6A1B9A);

  // Accents
  static const badge = Color(0xFF4CAF50);
  static const notification = Color(0xFFFF4444);

  // Backgrounds
  static const background = Color(0xFFEEF2F7);
  static const cardBg = Colors.white;
  static const bannerOverlayStart = Color(0xDD0D45A1);
  static const bannerOverlayEnd = Color(0x991976D2);

  // Text
  static const textDark = Color(0xFF1A1A2E);
  static const textMedium = Color(0xFF666666);
  static const textLight = Color(0xFF999999);
  static const textSubtitle = Color(0xFF7BAED4);
  static const bannerText = Color(0xFFBBDEFB);

  // Nav
  static const navInactive = Color(0xFFBBBBBB);

  // Header gradient
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerStart, headerMid, headerEnd],
  );

  // Button gradient
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
  );
}
