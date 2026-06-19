import 'package:go_router/go_router.dart';
import '../core/animation/app_motion.dart';
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
      pageBuilder: (context, state) => AppMotion.sharedAxisPage(
        const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/camera',
      pageBuilder: (context, state) => AppMotion.sharedAxisPage(
        const CameraScreen(),
      ),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (context, state) {
        final imagePath = state.extra as String;
        return AppMotion.sharedAxisPage(
          ReviewScreen(imagePath: imagePath),
        );
      },
    ),
    GoRoute(
      path: '/manual/search',
      pageBuilder: (context, state) => AppMotion.sharedAxisPage(
        const FoodSearchScreen(),
      ),
    ),
    GoRoute(
      path: '/manual/portion',
      pageBuilder: (context, state) {
        final item = state.extra as FoodItem;
        return AppMotion.sharedAxisPage(
          PortionEditorScreen(item: item),
        );
      },
    ),
    GoRoute(
      path: '/barcode',
      pageBuilder: (context, state) => AppMotion.sharedAxisPage(
        const BarcodeScannerScreen(),
      ),
    ),
  ],
);