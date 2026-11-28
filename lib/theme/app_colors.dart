import 'package:flutter/material.dart';

/// Central design tokens and color palette reflecting Stark Group's
/// Professional Automotive + Hybrid Layered visual style.
///
/// Palette specification:
/// - Deep Navy (#172633) for sidebar and dark surfaces.
/// - Steel Blue (#243746) for secondary panels / header accents.
/// - Automotive Teal (#168C91) for primary actions and highlights.
/// - Emerald (#39A879) for successful and active states.
/// - Warm Amber (#E2A84A) for warnings and maintenance.
/// - Soft Red (#E56B70) for errors and expired states.
/// - Off White (#F3F6F8) for the main content background.
class AppColors {
  // Brand & Action Colors
  static const Color primaryAction = Color(0xFF168C91); // Automotive Teal
  static const Color primaryActionHover = Color(0xFF1E9FA5); // Slightly brighter teal
  static const Color primaryActionDark = Color(0xFF116F73);
  static const Color primary = primaryAction;

  // Dark Surfacing & Panels (Sidebar, dark containers)
  static const Color deepNavy = Color(0xFF172633); // Sidebar & primary dark container
  static const Color steelBlue = Color(0xFF243746); // Secondary dark panels / cards
  static const Color darkBorder = Color(0xFF2E4557);

  // Light Workspace & Hybrid Layered Surfacing
  static const Color background = Color(0xFFF3F6F8); // Off White main content workspace
  static const Color surface = Colors.white; // Pure white elevated card surfaces
  static const Color surfaceVariant = Color(0xFFEBF0F4); // Crisp light slate container fill
  static const Color surfaceHighlight = Color(0xFFF0F5F8); // Very light hover surface
  static const Color border = Color(0xFFD6DFE6); // Light divider & card border
  static const Color borderStrong = Color(0xFFB5C3CF); // Input & active borders
  static const Color divider = Color(0xFFE2E9EF);

  // Typography - High contrast readability for both light workspace and dark sidebar
  static const Color textPrimary = Color(0xFF111E29); // Dark slate for light workspace
  static const Color textSecondary = Color(0xFF566A7A); // Cool slate body text
  static const Color textMuted = Color(0xFF8699A8); // Hint text
  static const Color textLight = Color(0xFFF1F5F8); // For deep navy / dark panels
  static const Color textLightSecondary = Color(0xFFA5B7C6); // Muted for dark panels

  // Operational Status colors
  static const Color statusActiveText = Color(0xFF39A879); // Emerald Green
  static const Color statusActiveBg = Color(0x1F39A879); // Emerald 12% tint
  static const Color statusActiveDot = Color(0xFF39A879);

  static const Color statusMaintenanceText = Color(0xFFE2A84A); // Warm Amber
  static const Color statusMaintenanceBg = Color(0x22E2A84A); // Amber 13% tint
  static const Color statusMaintenanceDot = Color(0xFFE2A84A);

  static const Color statusInactiveText = Color(0xFF728493); // Muted slate
  static const Color statusInactiveBg = Color(0x1F728493);
  static const Color statusInactiveDot = Color(0xFF90A1AF);

  // Alert & Destructive
  static const Color error = Color(0xFFE56B70); // Soft Red
  static const Color errorBg = Color(0x20E56B70); // Soft Red tint
  static const Color warning = Color(0xFFE2A84A); // Warm Amber

  // Backward compatibility alias
  static const Color starkOrange = primaryAction;
  static const Color starkOrangeHover = primaryActionHover;
  static const Color starkOrangeSoft = Color(0x1A168C91);
}
