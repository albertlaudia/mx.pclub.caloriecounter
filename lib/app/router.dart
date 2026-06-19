import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/food_item.dart';
import '../features/barcode/barcode_screen.dart';
import '../features/camera/camera_screen.dart';
import '../features/home/home_screen.dart';
import '../features/manual/portion_screen.dart';
import '../features/manual/search_screen.dart';
import '../features/review/review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final scale = Tween<double>(begin: 0.96, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: '/camera',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CameraScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final scale = Tween<double>(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (context, state) {
        final imagePath = state.extra as String;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ReviewScreen(imagePath: imagePath),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: '/manual/search',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FoodSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final scale = Tween<double>(begin: 0.96, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: '/manual/portion',
      pageBuilder: (context, state) {
        final item = state.extra as FoodItem;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PortionEditorScreen(item: item),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: '/barcode',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BarcodeScannerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
  ],
);
