import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../../owner/presentation/screens/rent_car/car_spefication.dart';
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
  String? _pickupLocation;
  String? _pickupDate;
  String? _pickupTime;
  String? _returnDate;
  String? _returnTime;
  loc.LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    _vehiclesFuture = _fetchHomeVehicles();
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

  Future<List<CarModel>> _fetchHomeVehicles() async {
    final vehicles = await _carApiService.getVehicles();
    final mapped = vehicles.map(CarModel.fromJson).toList();
    return mapped.where((car) => car.isAvailable).toList();
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
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
            style: AppColors.primaryButtonStyle(verticalPadding: 12, borderRadius: 12),
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
          _vehiclesFuture = _fetchHomeVehicles();
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
        title: const Text('Log Out', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: AppColors.dangerButtonStyle(),
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
        _vehiclesFuture = _fetchHomeVehicles();
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
    final name = user['full_name']?.toString() ?? user['fullName']?.toString() ?? 'User';
    final phone = user['phone_number']?.toString() ?? user['phoneNumber']?.toString() ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone.isNotEmpty) ...[
              const Text('Phone Number', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
            ],
            const Text('Account Status: Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
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
            style: AppColors.dangerButtonStyle(),
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
              _vehiclesFuture = _fetchHomeVehicles();
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
            onPickupLocationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location selection will be connected soon.'),
                ),
              );
            },
            onPickupDateTap: () => _pickDate(isPickup: true),
            onPickupTimeTap: () => _pickTime(isPickup: true),
            onReturnDateTap: () => _pickDate(isPickup: false),
            onReturnTimeTap: () => _pickTime(isPickup: false),
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
            },
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
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Recommended Cars',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 12),
                      Text('Unable to load vehicles. Please try again later.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              final cars = snapshot.data ?? [];
              if (cars.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Recommended Cars',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 12),
                      Text('No cars available at the moment.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return RecommendedCars(
                cars: cars,
                onCarTap: (car) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CarDetailScreen(car: car),
                    ),
                  );
                },
                onBookNow: (car) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CarDetailScreen(car: car),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 26),
          BecomeHostBanner(
            onHostTap: _goHost,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    setState(() {
      if (isPickup) {
        _pickupDate = formatted;
      } else {
        _returnDate = formatted;
      }
    });
  }

  Future<void> _pickTime({required bool isPickup}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null || !mounted) return;

    final formatted = picked.format(context);

    setState(() {
      if (isPickup) {
        _pickupTime = formatted;
      } else {
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                    const SnackBar(
                      content: Text('Favorites coming soon'),
                    ),
                  );
                },

                onProfileTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile coming soon'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              HeroSearchCard(
                pickupLocation: _pickupLocation,
                pickupDate: _pickupDate,
                pickupTime: _pickupTime,
                returnDate: _returnDate,
                returnTime: _returnTime,

                
onPickupLocationTap: () async {
  final selected = await LocationFlow.start(context);
  if (selected != null) {
    setState(() {
      _selectedLocation = selected;
      _pickupLocation = selected.name;
    });
  }
},
                onPickupDateTap: () => _pickDate(isPickup: true),
                onPickupTimeTap: () => _pickTime(isPickup: true),
                onReturnDateTap: () => _pickDate(isPickup: false),
                onReturnTimeTap: () => _pickTime(isPickup: false),

                onSearch: () {
                  if (_pickupLocation == null ||
                      _pickupDate == null ||
                      _pickupTime == null ||
                      _returnDate == null ||
                      _returnTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill all search details',
                        ),
                      ),
                    );
                    return;
                  }

                  // TODO:
                  // Navigate to Search Results Screen
                },
              ),

              const SizedBox(height: 22),

              CategoryList(
                categories: _homeCategories,
                onCategoryTap: (category) {},
              ),

              const SizedBox(height: 22),

              OfferCarousel(
                offers: _homeOffers,
                onOfferTap: (offer) {},
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
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Recommended Cars',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 12),
                          Text('Unable to load vehicles. Please try again later.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  final cars = snapshot.data ?? [];
                  if (cars.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Recommended Cars',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 12),
                          Text('No cars available at the moment.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return RecommendedCars(
                    cars: cars,
                    onCarTap: (car) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CarDetailScreen(car: car),
                        ),
                      );
                    },
                    onBookNow: (car) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CarDetailScreen(car: car),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 26),

              WhyChooseUsSection(
                items: _whyChooseUsItems,
              ),

              const SizedBox(height: 26),

              const HowItWorksSection(),

              const SizedBox(height: 26),

              BecomeHostBanner(
                onHostTap: _goHost,
              ),

              const SizedBox(height: 26),

              const StatsSection(),

              const SizedBox(height: 30),

              HomeFooter(
                onAboutTap: () {},
                onPrivacyPolicyTap: () {},
                onTermsTap: () {},
                onFaqsTap: () {},
                onContactUsTap: () {},
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _navIndex,
        onHomeTap: () {
          setState(() {
            _navIndex = 0;
            _vehiclesFuture = _fetchHomeVehicles();
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