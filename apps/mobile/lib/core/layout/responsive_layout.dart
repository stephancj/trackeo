import 'package:flutter/material.dart';

/// Points de rupture (breakpoints) pour le responsive design.
class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

/// Helper widget pour construire des layouts responsives.
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
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop;
        } else if (constraints.maxWidth >= Breakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Extension sur BuildContext pour vérifier la taille de l'écran.
extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < Breakpoints.tablet;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= Breakpoints.tablet &&
      MediaQuery.of(this).size.width < Breakpoints.desktop;
  bool get isDesktop => MediaQuery.of(this).size.width >= Breakpoints.desktop;
}
