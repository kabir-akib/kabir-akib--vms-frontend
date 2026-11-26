import 'package:flutter/material.dart';

/// Screen size helper for responsive desktop-first layout decisions.
class Responsive {
  static const double mobileMaxWidth = 650;
  static const double tabletMaxWidth = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMaxWidth;
}

/// A responsive widget builder that renders appropriate widgets based on screen width.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.tabletMaxWidth) {
          return desktop;
        } else if (constraints.maxWidth >= Responsive.mobileMaxWidth) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

