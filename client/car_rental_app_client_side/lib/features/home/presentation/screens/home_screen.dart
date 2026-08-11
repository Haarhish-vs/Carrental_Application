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
<<<<<<< Updated upstream
  LocationModel? _selectedLocationModel;
=======

  // Search form state
  LocationModel? _selectedLocation;
>>>>>>> Stashed changes
  String? _pickupLocation;
  String? _pickupDate;
  String? _pickupTime;
  String? _returnDate;
  String? _returnTime;

  DateTime? _selectedPickupDate;
  TimeOfDay? _selectedPickupTime;
  DateTime? _selectedReturnDate;
  TimeOfDay? _selectedReturnTime;

  // Active search state
  bool _isSearchActive = false;
  String? _activeSearchCity;

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
      final fullName =
          user['full_name']?.toString() ?? user['fullName']?.toString();
      final phone =
          user['phone_number']?.toString() ?? user['phoneNumber']?.toString();

      if (fullName != null && fullName.trim().isNotEmpty) {
        _userName = fullName.trim();
      } else if (phone != null && phone.trim().isNotEmpty) {
        _userName = phone.trim();
      } else {
        _userName = 'User';
      }
    } else {
      _userName = null;
    }
  }

  /// Fetches vehicles from the database via backend API with optional search parameters.
  Future<List<CarModel>> _fetchVehicles({
    String? city,
    String? startDate,
    String? endDate,
  }) async {
    debugPrint('🔍 [HomeScreen] Querying vehicles -> city: "${city ?? 'ALL'}", startDate: "$startDate", endDate: "$endDate"');
    final vehicles = await _carApiService.getVehicles(
      city: city,
      startDate: startDate,
      endDate: endDate,
    );
    final mapped = vehicles.map(CarModel.fromJson).toList();
    final available = mapped.where((car) => car.isAvailable).toList();
    debugPrint('🚗 [HomeScreen] Available vehicles loaded: ${available.length}');
    return available;
  }

  void _handleSearch() {
    if (_pickupLocation == null || _pickupLocation!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final pickupMidnight = DateTime(_selectedPickupDate!.year, _selectedPickupDate!.month, _selectedPickupDate!.day);
    final returnMidnight = DateTime(_selectedReturnDate!.year, _selectedReturnDate!.month, _selectedReturnDate!.day);

    if (pickupMidnight.isBefore(todayMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup date cannot be in the past'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (returnMidnight.isBefore(pickupMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return date must be on or after pickup date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final startDateStr = '${pickupMidnight.year}-${pickupMidnight.month.toString().padLeft(2, '0')}-${pickupMidnight.day.toString().padLeft(2, '0')}';
    final endDateStr = '${returnMidnight.year}-${returnMidnight.month.toString().padLeft(2, '0')}-${returnMidnight.day.toString().padLeft(2, '0')}';

    final cityQuery = (_selectedLocation != null && _selectedLocation!.city.isNotEmpty)
        ? _selectedLocation!.city
        : _pickupLocation!.split(',').first.trim();

    debugPrint('🚀 [HomeScreen.onSearch] Triggering Search: city="$cityQuery", range=[$startDateStr to $endDateStr]');

    setState(() {
      _isSearchActive = true;
      _activeSearchCity = cityQuery;
      _vehiclesFuture = _fetchVehicles(
        city: cityQuery,
        startDate: startDateStr,
        endDate: endDateStr,
      );
    });
  }

  void _clearSearch() {
    debugPrint('🔄 [HomeScreen] Resetting search filters');
    setState(() {
      _isSearchActive = false;
      _activeSearchCity = null;
      _pickupLocation = null;
      _pickupDate = null;
      _pickupTime = null;
      _returnDate = null;
      _returnTime = null;
      _selectedPickupDate = null;
      _selectedReturnDate = null;
      _selectedPickupTime = null;
      _selectedReturnTime = null;
      _selectedLocation = null;
      _vehiclesFuture = _fetchVehicles();
    });
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

    // Refresh vehicle list so booked cars update
    if (mounted) {
      setState(() {
        if (_isSearchActive && _selectedPickupDate != null && _selectedReturnDate != null) {
          final startStr = '${_selectedPickupDate!.year}-${_selectedPickupDate!.month.toString().padLeft(2, '0')}-${_selectedPickupDate!.day.toString().padLeft(2, '0')}';
          final endStr = '${_selectedReturnDate!.year}-${_selectedReturnDate!.month.toString().padLeft(2, '0')}-${_selectedReturnDate!.day.toString().padLeft(2, '0')}';
          _vehiclesFuture = _fetchVehicles(
            city: _activeSearchCity,
            startDate: startStr,
            endDate: endStr,
          );
        } else {
          _vehiclesFuture = _fetchVehicles();
        }
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
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF1E5AA8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log In / Register'),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) return false;

    final authSuccess = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));

    return authSuccess == true;
  }

  Future<void> _goHost() async {
    final authenticated = await _ensureAuthenticated(
      title: 'Host Your Car',
      message: 'Please log in or register to list your vehicle.',
    );

    if (authenticated && mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CarSpecificationScreen()));
      if (mounted) {
        setState(() {
          _vehiclesFuture = _fetchVehicles();
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        _clearSearch();
      });

      debugPrint('📱 [HomeScreen] Navigating to Login screen...');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(initialMode: AuthMode.login),
        ),
      );
    }
  }

  void _showProfileModal() {
    if (!AuthService.isAuthenticated) {
      _ensureAuthenticated(
        title: 'User Profile',
        message: 'Please log in or register to view your profile.',
      );
      return;
    }

    final user = AuthService.currentUser ?? {};
    final name =
        user['full_name']?.toString() ?? user['fullName']?.toString() ?? 'User';
    final phone =
        user['phone_number']?.toString() ??
        user['phoneNumber']?.toString() ??
        '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.person, color: Color(0xFF1E5AA8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone.isNotEmpty) ...[
              const Text(
                'Phone Number',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Account Status: Active',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _handleLogout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
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
            onMenuTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            onFavoriteTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorites coming soon')),
              );
            },
            onProfileTap: _showProfileModal,
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
<<<<<<< Updated upstream
                  _selectedLocationModel = selectedLocation;
=======
                  _selectedLocation = selectedLocation;
>>>>>>> Stashed changes
                  _pickupLocation = selectedLocation.name;
                });
              }
            },
            onPickupDateTap: () => _pickDate(isPickup: true),
            onPickupTimeTap: () => _pickTime(isPickup: true),
            onReturnDateTap: () => _pickDate(isPickup: false),
            onReturnTimeTap: () => _pickTime(isPickup: false),
<<<<<<< Updated upstream
            onSearch: () {
              if (_pickupLocation == null ||
                  _pickupDate == null ||
                  _pickupTime == null ||
                  _returnDate == null ||
                  _returnTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all search details'),
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
            },
=======
            onSearch: _handleSearch,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Recommended Cars',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Unable to load vehicles. Please try again later.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
=======
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
>>>>>>> Stashed changes
                  ),
                );
              }

              final cars = snapshot.data ?? [];
              if (cars.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
<<<<<<< Updated upstream
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Recommended Cars',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No cars available at the moment.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
=======
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
                        Text(
                          _isSearchActive ? 'No cars available for selected criteria' : 'No cars available at the moment',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSearchActive
                              ? 'Try choosing different dates, another pickup location, or reset filters to browse all cars.'
                              : 'Check back soon as hosts list new cars regularly.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                        if (_isSearchActive) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Show All Cars'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
>>>>>>> Stashed changes
                  ),
                );
              }

              final title = _isSearchActive
                  ? 'Available Cars (${cars.length})'
                  : 'Recommended Cars';

              final trailing = _isSearchActive
                  ? TextButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close, size: 14, color: AppColors.primary),
                      label: const Text(
                        'Clear filter',
                        style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  : null;

              return RecommendedCars(
                cars: cars,
                title: title,
                trailing: trailing,
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
        // If return date is before new pickup date, auto-bump return date to next day
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
          _showProfileModal();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Support coming soon')));
        },
        onHostTap: () async {
          Navigator.pop(context);
          await _goHost();
        },
        onSettingsTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
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
