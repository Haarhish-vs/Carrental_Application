import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/owner/data/services/car_api_service.dart';
import 'features/owner/presentation/screens/rent_car/car_spefication.dart';

void main() {
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarApiService _apiService = CarApiService();
  late Future<List<Map<String, dynamic>>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }

  void _refreshVehicles() {
    setState(() {
      _vehiclesFuture = _apiService.getVehicles();
    });
  }

  Future<void> _ensureAuthenticated(
    BuildContext context,
    VoidCallback onAuthenticated,
  ) async {
    if (AuthService.isAuthenticated) {
      onAuthenticated();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF1E5AA8),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Authentication Required'),
            ],
          ),
          content: const Text(
            'Please register or log in to continue.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Login / Register'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      final authSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

      if (authSuccess == true && mounted) {
        setState(() {}); // Refresh UI state after login
        onAuthenticated();
      }
    }
  }

  void _logout() {
    AuthService.logout();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rent-A-Car Fleet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshVehicles,
            tooltip: 'Refresh Listings',
          ),
          if (AuthService.isAuthenticated)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'logout') _logout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    AuthService.currentUser?['full_name'] ??
                        AuthService.currentUser?['phone_number'] ??
                        'Authenticated User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  backgroundColor: Color(0xFF1E5AA8),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () async {
                final authSuccess = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                if (authSuccess == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rent Out Your Car Banner Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 32,
                        color: Color(0xFF1E5AA8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earn by Renting Your Car',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF103B66),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'List your vehicle in 4 simple steps.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF57718A),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        _ensureAuthenticated(context, () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CarSpecificationScreen(),
                            ),
                          );
                          _refreshVehicles();
                        });
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Rent Out'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Vehicles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF103B66),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: _refreshVehicles,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final vehicles = snapshot.data ?? [];
                if (vehicles.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.car_rental_outlined,
                            size: 48,
                            color: Color(0xFF8EA6BE),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No active vehicle listings yet.',
                            style: TextStyle(
                              color: Color(0xFF103B66),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'List a vehicle using the "Rent Out" button above.',
                            style: TextStyle(
                              color: Color(0xFF57718A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final car = vehicles[index];
                    final images = (car['images'] as List<dynamic>?) ?? [];
                    final imageUrl = images.isNotEmpty ? images.first.toString() : '';
                    final brand = car['brand'] ?? 'Vehicle';
                    final model = car['model'] ?? '';
                    final price = car['price_per_day'] ?? car['dailyPrice'] ?? 0;
                    final seats = car['seats'] ?? car['seatingCapacity'] ?? 5;
                    final transmission = car['transmission'] ?? 'Automatic';
                    final city = car['city'] ?? 'Default City';

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFEAF2FF),
                                      child: const Icon(
                                        Icons.directions_car_rounded,
                                        size: 48,
                                        color: Color(0xFF1E5AA8),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFEAF2FF),
                                    child: const Icon(
                                      Icons.directions_car_rounded,
                                      size: 48,
                                      color: Color(0xFF1E5AA8),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$brand $model',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF103B66),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '₹$price / day',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: const Color(0xFF1E5AA8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_seat_outlined,
                                      size: 16,
                                      color: Color(0xFF57718A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$seats Seats',
                                      style: const TextStyle(
                                        color: Color(0xFF57718A),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.settings_outlined,
                                      size: 16,
                                      color: Color(0xFF57718A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$transmission',
                                      style: const TextStyle(
                                        color: Color(0xFF57718A),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Color(0xFF57718A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$city',
                                      style: const TextStyle(
                                        color: Color(0xFF57718A),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () {
                                    _ensureAuthenticated(context, () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Booking request initiated for $brand $model!'),
                                        ),
                                      );
                                    });
                                  },
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Book Now'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
