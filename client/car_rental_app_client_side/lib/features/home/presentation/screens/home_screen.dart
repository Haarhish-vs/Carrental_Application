import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../../owner/presentation/screens/rent_car/car_spefication.dart';
import '../../../location/data/models/location_model.dart';
import '../../../location/presentation/location_flow.dart';
import 'package:car_rental_app_client_side/features/search/data/models/search_parameters.dart';
import 'package:car_rental_app_client_side/features/search/presentation/screens/search_cars_screen.dart';
import '../widgets/custom_home_app_bar.dart';
import '../widgets/hero_search_card.dart';
import '../widgets/recommended_cars.dart';
import '../widgets/become_host_banner.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/home_drawer.dart';
import 'car_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'my_cars_screen.dart';
import 'all_recommended_cars_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CarApiService _carApiService = CarApiService();

  int _navIndex = 0;

  late Future<List<CarModel>> _vehiclesFuture;

  String? _userName;
  String? _userLocation;
  String? _profileImageUrl;

  // Search form state
  LocationModel? _selectedLocationModel;
  String? _pickupLocation;
  String? _pickupDate;
  String? _pickupTime;
  String? _returnDate;
  String? _returnTime;

  DateTime? _selectedPickupDate;
  TimeOfDay? _selectedPickupTime;
  DateTime? _selectedReturnDate;
  TimeOfDay? _selectedReturnTime;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    _vehiclesFuture = _fetchVehicles();
  }

  @override
  void dispose() {
    AuthService.authStateNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {
        _loadUserInfo();
      });
    }
  }

  void _loadUserInfo() {
    if (AuthService.isAuthenticated && AuthService.currentUser != null) {
      final user = AuthService.currentUser!;
      final fullName = user['full_name']?.toString() ?? user['fullName']?.toString();
      final phone = user['phone_number']?.toString() ?? user['phoneNumber']?.toString();
      _profileImageUrl = user['profile_image_url']?.toString() ?? user['profileImageUrl']?.toString();

      if (fullName != null && fullName.trim().isNotEmpty) {
        _userName = fullName.trim();
      } else if (phone != null && phone.trim().isNotEmpty) {
        _userName = phone.trim();
      } else {
        _userName = 'User';
      }
    } else {
      _userName = null;
      _profileImageUrl = null;
    }
  }

  /// Fetches vehicles from the database via backend API
  Future<List<CarModel>> _fetchVehicles({
    String? city,
    String? startDate,
    String? endDate,
  }) async {
    // Default to a 1-year window if no dates are provided to exclude any car with an active/future booking
    final now = DateTime.now();
    final defaultStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nextYear = now.add(const Duration(days: 365));
    final defaultEnd = '${nextYear.year}-${nextYear.month.toString().padLeft(2, '0')}-${nextYear.day.toString().padLeft(2, '0')}';

    final queryStart = startDate ?? defaultStart;
    final queryEnd = endDate ?? defaultEnd;

    debugPrint('🔍 [HomeScreen] Querying vehicles -> city: "${city ?? 'ALL'}", startDate: "$queryStart", endDate: "$queryEnd"');
    final vehicles = await _carApiService.getVehicles(
      city: city,
      startDate: queryStart,
      endDate: queryEnd,
    );
    final mapped = vehicles.map(CarModel.fromJson).toList();
    final available = mapped.where((car) => car.isAvailable).toList();
    debugPrint('🚗 [HomeScreen] Available vehicles loaded: ${available.length}');
    
    // Sort by ratings (highest first)
    try {
      final ratings = await Future.wait(
        available.map((car) => _carApiService.getAverageRating(car.id))
      );
      
      final paired = List.generate(
        available.length, 
        (i) => MapEntry(available[i], ratings[i] ?? 0.0)
      );
      
      paired.sort((a, b) => b.value.compareTo(a.value));
      return paired.map((e) => e.key).toList();
    } catch (e) {
      debugPrint('⚠️ Error sorting by rating: $e');
      return available;
    }
  }

  void _handleSearch() {
    if (_pickupLocation == null ||
        _pickupDate == null ||
        _pickupTime == null ||
        _returnDate == null ||
        _returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all search details'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final location = _selectedLocationModel ??
        LocationModel(
          placeId: '',
          name: _pickupLocation!,
          address: _pickupLocation!,
          latitude: 0.0,
          longitude: 0.0,
          city: _pickupLocation!,
          state: '',
          country: '',
        );

    final params = SearchParameters(
      location: location,
      pickupDate: _pickupDate!,
      pickupTime: _pickupTime!,
      returnDate: _returnDate!,
      returnTime: _returnTime!,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchCarsScreen(initialParams: params),
      ),
    );
  }

  void _openCarDetail(CarModel car) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarDetailScreen(
          car: car,
          initialPickupDate: _selectedPickupDate,
          initialReturnDate: _selectedReturnDate,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _vehiclesFuture = _fetchVehicles();
      });
    }
  }

  Future<bool> _ensureAuthenticated({
    required String title,
    required String message,
  }) async {
    if (AuthService.isAuthenticated) return true;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1E5AA8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E5AA8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log In / Register'),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) return false;

    final authSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    return authSuccess == true;
  }

  Future<void> _goHost() async {
    final authenticated = await _ensureAuthenticated(
      title: 'Host Your Car',
      message: 'Please log in or register to list your vehicle.',
    );

    if (authenticated && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CarSpecificationScreen(),
        ),
      );
      if (mounted) {
        setState(() {
          _vehiclesFuture = _fetchVehicles();
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      debugPrint('🚪 [HomeScreen] User confirmed logout. Clearing session...');
      await AuthService.logout();
      if (!mounted) return;

      setState(() {
        _navIndex = 0;
        _loadUserInfo();
        _vehiclesFuture = _fetchVehicles();
      });

      debugPrint('📱 [HomeScreen] Navigating to Login screen...');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(initialMode: AuthMode.login),
        ),
      );
    }
  }

  Future<void> _openProfileScreen() async {
    if (!AuthService.isAuthenticated) {
      final loggedIn = await _ensureAuthenticated(
        title: 'User Profile',
        message: 'Please log in or register to view your profile.',
      );
      if (!loggedIn || !mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    if (mounted) {
      setState(() {
        _loadUserInfo();
        _vehiclesFuture = _fetchVehicles();
      });
    }
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1:
        return MyBookingsScreen(
          onExplorePressed: () {
            setState(() {
              _navIndex = 0;
              _vehiclesFuture = _fetchVehicles();
            });
          },
        );
      case 2:
        return MyCarsScreen(
          onListCarPressed: () async {
            await _goHost();
          },
        );
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomHomeAppBar(
            userName: _userName,
            location: _userLocation,
            profileImageUrl: _profileImageUrl,
            onMenuTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            onFavoriteTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorites coming soon')),
              );
            },
            onProfileTap: _openProfileScreen,
          ),
          const SizedBox(height: 10),
          HeroSearchCard(
            pickupLocation: _pickupLocation,
            pickupDate: _pickupDate,
            pickupTime: _pickupTime,
            returnDate: _returnDate,
            returnTime: _returnTime,
            onPickupLocationTap: () async {
              final selectedLocation = await LocationFlow.start(context);
              if (selectedLocation != null && mounted) {
                setState(() {
                  _selectedLocationModel = selectedLocation;
                  _pickupLocation = selectedLocation.name;
                });
              }
            },
            onPickupDateTap: () => _pickDate(isPickup: true),
            onPickupTimeTap: () => _pickTime(isPickup: true),
            onReturnDateTap: () => _pickDate(isPickup: false),
            onReturnTimeTap: () => _pickTime(isPickup: false),
            onSearch: _handleSearch,
          ),
          const SizedBox(height: 22),
          FutureBuilder<List<CarModel>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 14),
                          Text('Finding available cars...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'Unable to load vehicles',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString().replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _vehiclesFuture = _fetchVehicles();
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final cars = snapshot.data ?? [];
              if (cars.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_outlined, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No cars available at the moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check back soon as hosts list new cars regularly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RecommendedCars(
                cars: cars,
                onCarTap: _openCarDetail,
                onBookNow: (car) async {
                  if (AuthService.isAuthenticated &&
                      AuthService.currentUser != null &&
                      AuthService.currentUser!['id'] == car.ownerId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You cannot book your own vehicle'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  _openCarDetail(car);
                },
                onSeeAllTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllRecommendedCarsScreen(
                        cars: cars,
                        initialPickupDate: _selectedPickupDate,
                        initialReturnDate: _selectedReturnDate,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 26),
          BecomeHostBanner(onHostTap: _goHost),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final initialDate = isPickup
        ? (_selectedPickupDate ?? now)
        : (_selectedReturnDate ?? (_selectedPickupDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1))));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    setState(() {
      if (isPickup) {
        _selectedPickupDate = picked;
        _pickupDate = formatted;
        if (_selectedReturnDate != null && _selectedReturnDate!.isBefore(picked)) {
          final nextDay = picked.add(const Duration(days: 1));
          _selectedReturnDate = nextDay;
          _returnDate =
              '${nextDay.day.toString().padLeft(2, '0')}/'
              '${nextDay.month.toString().padLeft(2, '0')}/${nextDay.year}';
        }
      } else {
        _selectedReturnDate = picked;
        _returnDate = formatted;
      }
    });
  }

  Future<void> _pickTime({required bool isPickup}) async {
    final initialTime = isPickup
        ? (_selectedPickupTime ?? const TimeOfDay(hour: 10, minute: 0))
        : (_selectedReturnTime ?? const TimeOfDay(hour: 18, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null || !mounted) return;

    final formatted = picked.format(context);

    setState(() {
      if (isPickup) {
        _selectedPickupTime = picked;
        _pickupTime = formatted;
      } else {
        _selectedReturnTime = picked;
        _returnTime = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: HomeDrawer(
        userName: _userName,
        userLocation: _userLocation,
        onProfileTap: () {
          Navigator.pop(context);
          _openProfileScreen();
        },
        onTripsTap: () {
          Navigator.pop(context);
          setState(() {
            _navIndex = 1;
          });
        },
        onFavoritesTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorites coming soon')),
          );
        },
        onSupportTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support coming soon')),
          );
        },
        onHostTap: () async {
          Navigator.pop(context);
          await _goHost();
        },
        onSettingsTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings coming soon')),
          );
        },
        onHelpTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help & FAQs coming soon')),
          );
        },
        onPrivacyTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Privacy Policy coming soon')),
          );
        },
        onLogoutTap: () {
          Navigator.pop(context);
          _handleLogout();
        },
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _navIndex,
        onHomeTap: () {
          setState(() {
            _navIndex = 0;
            _vehiclesFuture = _fetchVehicles();
          });
        },
        onBookingsTap: () {
          setState(() {
            _navIndex = 1;
          });
        },
        onMyCarTap: () {
          setState(() {
            _navIndex = 2;
          });
        },
        onHostTap: _goHost,
      ),
    );
  }
}
