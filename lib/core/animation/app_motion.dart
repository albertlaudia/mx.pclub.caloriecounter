import 'package:flutter/material.dart';

/// Motion design tokens — keep all animation timings in one place.
///
/// Curve palette is intentionally narrow: 3 curves for 95% of use cases.
/// Reach for `springed` (the spring) when something should feel physical.
class AppMotion {
  AppMotion._();

  // ── Durations ────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration hero = Duration(milliseconds: 800);

  // ── Curves ───────────────────────────────────────────────────
  /// Quick start, gentle landing — for elements entering the screen.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Quick start, gentle end — for elements leaving.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Bouncy overshoot — for playful confirmations (log success, snap).
  static const Curve playful = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Linear with slight ease — for progress and counters.
  static const Curve standard = Curves.easeInOutCubic;

  // ── Page transitions ─────────────────────────────────────────
  static PageRouteBuilder<T> fadeThroughPage<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final fade = CurvedAnimation(parent: anim, curve: emphasized);
        final scale = Tween<double>(begin: 0.96, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: emphasized));
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static PageRouteBuilder<T> sharedAxisPage<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: slow,
      reverseTransitionDuration: fast,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: emphasized),
        );
        final fade = CurvedAnimation(parent: anim, curve: emphasizedDecelerate);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  // ── Reusable transitions ─────────────────────────────────────
  static Widget fadeSlideIn(
    Widget child, {
    Duration delay = Duration.zero,
    Duration duration = normal,
    Offset offset = const Offset(0, 12),
    Curve curve = emphasized,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, c) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset * (1 - value),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

/// Standard hero tag names — keep these consistent for shared transitions.
class HeroTags {
  HeroTags._();
  static const cameraButton = 'camera-button';
  static const mealPhoto = 'meal-photo';
  static const calorieRing = 'calorie-ring';
}