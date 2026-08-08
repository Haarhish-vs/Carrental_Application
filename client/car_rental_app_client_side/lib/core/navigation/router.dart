import 'package:go_router/go_router.dart';
import '../../features/booking/navigation/booking_routes.dart';
import '../constants/app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter get router {
    return GoRouter(
      initialLocation: AppRoutes.booking,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(path: '/', redirect: (_, __) => AppRoutes.booking),
        ...BookingRoutes.routes,
      ],
    );
  }
}
