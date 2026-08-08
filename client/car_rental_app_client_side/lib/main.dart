import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';
import 'package:car_rental_app_client_side/features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate stored JWT & auto-login user before initial frame
  await AuthService.tryAutoLogin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
