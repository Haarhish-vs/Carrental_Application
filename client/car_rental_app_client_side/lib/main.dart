import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/notifications/notification_service.dart';
import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';
import 'package:car_rental_app_client_side/features/home/presentation/screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Run App immediately so Flutter engine renders first frame without freezing splash screen
  runApp(const MyApp());

  // Initialize Firebase, NotificationService & AuthService asynchronously after first frame
  _initServices();
}

Future<void> _initServices() async {
  try {
    await NotificationService.instance.initialize(navKey: navigatorKey);
  } catch (e) {
    debugPrint('[FCM ERROR] Non-fatal initialization error: $e');
  }

  try {
    await AuthService.tryAutoLogin();
  } catch (e) {
    debugPrint('[Auth ERROR] Auto-login error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Car Rental Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF103B66),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
