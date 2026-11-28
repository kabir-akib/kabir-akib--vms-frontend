import 'package:flutter/material.dart';

/// Central design tokens and color palette reflecting Stark Group's
/// premium automotive fleet management visual style.
///
/// Palette specification:
/// - Main Background: #202B35 (Graphite)
/// - Card & Panel Background: #2C3945 (Steel Gray)
/// - Primary Action: #286B91 (Automotive Blue)
/// - Success & Active: #27845F (Emerald Green)
/// - Secondary Accent: #7056A5 (Muted Purple)
/// - Error & Expired: #D65D68 (Soft Red)
/// - Maintenance & Warning: #D5A34D (Warm Amber)
/// - Primary Text: #F1F4F7
/// - Secondary Text: #C1CCD5
/// - Borders & Dividers: #465563
class AppColors {
  // Brand & Action Colors
  static const Color primaryAction = Color(0xFF286B91); // Automotive Blue
  static const Color primaryActionHover = Color(0xFF3381AD); // Lighter blue for hover
  static const Color primary = primaryAction; // Primary brand color
  static const Color secondaryAccent = Color(0xFF7056A5); // Muted Purple
  static const Color secondary = secondaryAccent;

  // Background and surface colors (Graphite & Steel Gray)
  static const Color background = Color(0xFF202B35); // Main Background: Graphite
  static const Color surface = Color(0xFF2C3945); // Card and Panel: Steel Gray
  static const Color surfaceVariant = Color(0xFF25313D); // Slightly darker panel / header
  static const Color surfaceHighlight = Color(0xFF354452); // Subtle hover / highlight fill
  static const Color border = Color(0xFF465563); // Borders and Dividers
  static const Color borderStrong = Color(0xFF5A6C7D); // Stronger borders for active inputs
  static const Color divider = Color(0xFF465563);

  // Backward-compatibility alias for previous starkOrange references -> primaryAction
  static const Color starkOrange = primaryAction;
  static const Color starkOrangeHover = primaryActionHover;
  static const Color starkOrangeSoft = Color(0x28286B91);

  // Typography colors
  static const Color textPrimary = Color(0xFFF1F4F7); // Primary Text
  static const Color textSecondary = Color(0xFFC1CCD5); // Secondary Text
  static const Color textMuted = Color(0xFF8E9EA9); // Muted / hint text
  static const Color textOnDark = Color(0xFFF1F4F7);
  static const Color textOnAction = Colors.white;

  // Operational Status colors
  static const Color statusActiveText = Color(0xFF27845F); // Emerald Green
  static const Color statusActiveBg = Color(0x2227845F); // Emerald Green 14% tint
  static const Color statusActiveDot = Color(0xFF27845F);

  static const Color statusMaintenanceText = Color(0xFFD5A34D); // Warm Amber
  static const Color statusMaintenanceBg = Color(0x24D5A34D); // Warm Amber 14% tint
  static const Color statusMaintenanceDot = Color(0xFFD5A34D);

  static const Color statusInactiveText = Color(0xFFC1CCD5); // Secondary Slate
  static const Color statusInactiveBg = Color(0x20C1CCD5); // Subtle tint
  static const Color statusInactiveDot = Color(0xFF8E9EA9);

  // Alert and destructive colors
  static const Color error = Color(0xFFD65D68); // Soft Red
  static const Color errorBg = Color(0x22D65D68); // Soft Red 14% tint
  static const Color warning = Color(0xFFD5A34D); // Warm Amber
}
