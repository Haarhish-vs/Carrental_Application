import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/customer/presentation/screens/home_screen.dart';
import '../../features/owner/presentation/screens/owner_dashboard_screen.dart';

/// Central route configuration. Feature routes can be added here when their
/// screens are implemented.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    // Owner Dashboard is only reachable after Owner Login in the full
    // product; login/auth isn't implemented yet, so we open directly
    // on it here.
    initialLocation: '/owner',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(title: 'Flutter Demo Home Page'),
      ),
      GoRoute(
        path: '/owner',
        name: 'owner-dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const OwnerDashboardScreen(),
      ),
    ],
  );
}
