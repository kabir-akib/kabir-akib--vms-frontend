import 'package:flutter/material.dart';

/// Central design tokens and color palette reflecting Stark Group's
/// heavy-logistics and industrial visual style.
class AppColors {
  // Stark Group corporate brand colors
  static const Color primary = Color(0xFF0F172A); // Stark Dark Slate / Charcoal
  static const Color primaryLight = Color(0xFF1E293B); // Medium Charcoal
  static const Color starkOrange = Color(0xFFEA580C); // Stark Signature Vermilion / Orange
  static const Color starkOrangeHover = Color(0xFFC2410C); // Deeper Orange on hover
  static const Color starkOrangeSoft = Color(0xFFFFF7ED); // Soft Orange tint for badges/accents
  static const Color secondary = Color(0xFF334155); // Corporate Slate

  // Neutral background and surface colors
  static const Color background = Color(0xFFF8FAFC); // Clean slate background
  static const Color surface = Colors.white; // Pure white cards & dialogs
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light slate fill
  static const Color border = Color(0xFFE2E8F0); // Subtle divider / card border
  static const Color borderStrong = Color(0xFFCBD5E1); // Input field border

  // Typography colors
  static const Color textPrimary = Color(0xFF0F172A); // High contrast dark
  static const Color textSecondary = Color(0xFF475569); // Slate body text
  static const Color textMuted = Color(0xFF94A3B8); // Subtitle / hint text
  static const Color textOnDark = Colors.white;

  // Operational Status colors
  static const Color statusActiveText = Color(0xFF15803D); // Green 700
  static const Color statusActiveBg = Color(0xFFDCFCE7); // Green 100
  static const Color statusActiveDot = Color(0xFF22C55E); // Green 500

  static const Color statusMaintenanceText = Color(0xFFB45309); // Amber 700
  static const Color statusMaintenanceBg = Color(0xFFFEF3C7); // Amber 100
  static const Color statusMaintenanceDot = Color(0xFFF59E0B); // Amber 500

  static const Color statusInactiveText = Color(0xFF475569); // Slate 600
  static const Color statusInactiveBg = Color(0xFFF1F5F9); // Slate 100
  static const Color statusInactiveDot = Color(0xFF94A3B8); // Slate 400

  // Alert and destructive colors
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xFFFEE2E2); // Red 100
}
