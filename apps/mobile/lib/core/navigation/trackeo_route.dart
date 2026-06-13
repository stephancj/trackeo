import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Transition premium : slide vers le haut + fade (iOS-style épuré).
/// Usage : Navigator.push(context, TrackeoRoute(builder: (_) => MyPage()));
class TrackeoRoute<T> extends PageRouteBuilder<T> {
  TrackeoRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0.0, 0.035),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppMotion.quint,
            ));

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            );

            // Secondary: très légère sortie vers la droite de la page courante
            final exit = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.04, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeIn,
            ));

            return SlideTransition(
              position: exit,
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              ),
            );
          },
        );
}
