import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:car_rental_app_client_side/core/notifications/notification_service.dart';
import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';
import 'package:car_rental_app_client_side/features/home/presentation/screens/home_screen.dart';

import 'package:car_rental_app_client_side/core/network/network_status.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core Firebase App synchronously before rendering UI
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Initialization notice: $e');
  }

  runApp(const MyApp());

  // Initialize FCM Notification Service & Auth in background after initial frame
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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      builder: (context, child) => NetworkStatusBanner(
        child: child ?? const SizedBox(),
      ),
      home: const HomeScreen(),
    );
  }
}

