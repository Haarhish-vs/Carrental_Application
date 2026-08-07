import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../../models/category_model.dart';
import '../../models/offer_model.dart';
import '../../models/feature_item_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../../owner/presentation/screens/rent_car/car_spefication.dart';
import '../widgets/custom_home_app_bar.dart';
import '../widgets/hero_search_card.dart';
import '../widgets/category_list.dart';
import '../widgets/offer_carousel.dart';
import '../widgets/recommended_cars.dart';
import '../widgets/why_choose_us_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/become_host_banner.dart';
import '../widgets/stats_section.dart';
import '../widgets/home_footer.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/home_drawer.dart';
import 'car_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'my_cars_screen.dart';

const List<CategoryModel> _homeCategories = [
  CategoryModel(id: '1', label: 'Daily Rental', icon: Icons.calendar_today_outlined),
  CategoryModel(id: '2', label: 'Weekly Rental', icon: Icons.date_range_outlined),
  CategoryModel(id: '3', label: 'SUV', icon: Icons.directions_car_filled_outlined),
  CategoryModel(id: '4', label: 'Luxury', icon: Icons.diamond_outlined),
  CategoryModel(id: '5', label: 'Electric', icon: Icons.electric_bolt_outlined),
  CategoryModel(id: '6', label: 'Automatic', icon: Icons.settings_outlined),
];

const List<OfferModel> _homeOffers = [
  OfferModel(
    id: '1',
    title: 'Weekend Offer',
    subtitle: 'Get 20% off on weekend bookings',
    imageUrl: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800',
  ),
  OfferModel(
    id: '2',
    title: 'Festival Offer',
    subtitle: 'Flat ₹500 cashback this festive season',
    imageUrl: 'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=800',
  ),
  OfferModel(
    id: '3',
    title: 'Refer & Earn',
    subtitle: 'Invite friends, earn ₹250 per referral',
    imageUrl: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800',
  ),
  OfferModel(
    id: '4',
    title: 'Host Your Car',
    subtitle: 'Turn your idle car into income',
    imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800',
  ),
];

const List<FeatureItemModel> _whyChooseUsItems = [
  FeatureItemModel(id: '1', icon: Icons.verified_outlined, title: 'Verified Cars'),
  FeatureItemModel(id: '2', icon: Icons.badge_outlined, title: 'Verified Owners'),
  FeatureItemModel(id: '3', icon: Icons.car_repair_outlined, title: 'Roadside Assistance'),
  FeatureItemModel(id: '4', icon: Icons.lock_outline, title: 'Secure Payments'),
  FeatureItemModel(id: '5', icon: Icons.flash_on_outlined, title: 'Instant Booking'),
  FeatureItemModel(id: '6', icon: Icons.headset_mic_outlined, title: '24×7 Support'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CarApiService _carApiService = CarApiService();

  int _navIndex = 0;

  late final Future<List<CarModel>> _vehiclesFuture;
  Future<List<Map<String, dynamic>>>? _myBookingsFuture;
  Future<List<Map<String, dynamic>>>? _myCarsFuture;

  String? _userName;
  String? _userLocation;
  String? _pickupLocation;
  String? _pickupDate;
  String? _pickupTime;
  String? _returnDate;
  String? _returnTime;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _fetchHomeVehicles();
  }

  Future<List<CarModel>> _fetchHomeVehicles() async {
    final vehicles = await _carApiService.getVehicles();
    return vehicles
        .map(CarModel.fromJson)
        .where((car) => car.isAvailable)
        .toList();
  }

  Future<void> _goHost() async {
    if (AuthService.isAuthenticated) {
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CarSpecificationScreen(),
        ),
      );
      return;
    }

    final authSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );

    if (authSuccess == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CarSpecificationScreen(),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMyBookings() async {
    return _carApiService.getMyBookings();
  }

  Future<List<Map<String, dynamic>>> _fetchMyCars() async {
    return _carApiService.getMyListings();
  }

  Widget _buildAuthPrompt(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final authSuccess = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );

              if (authSuccess == true && mounted) {
                setState(() {
                  _myBookingsFuture = _fetchMyBookings();
                  _myCarsFuture = _fetchMyCars();
                });
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Login to view'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    if (!AuthService.isAuthenticated) {
      return _buildAuthPrompt(
        'My Bookings',
        'Log in to see the cars you have booked and track booking status.',
      );
    }

    _myBookingsFuture ??= _fetchMyBookings();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _myBookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load bookings: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Text('No bookings yet. Book a car to see it listed here.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final vehicle = booking['vehicle'] as Map<String, dynamic>?;
            final vehicleName = vehicle != null
                ? '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'.trim()
                : 'Booked Vehicle';
            final startDate = booking['start_date'] ?? '';
            final endDate = booking['end_date'] ?? '';
            final status = booking['status'] ?? 'pending';
            final totalPrice = booking['total_price'] ?? 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicleName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Dates: $startDate → $endDate', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Status: ${status.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Total Paid: ₹$totalPrice', style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyCarTab() {
    if (!AuthService.isAuthenticated) {
      return _buildAuthPrompt(
        'My Cars',
        'Log in to see the cars you have listed for rent.',
      );
    }

    _myCarsFuture ??= _fetchMyCars();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _myCarsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load your cars: ${snapshot.error}'),
          );
        }

        final cars = snapshot.data ?? [];
        if (cars.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Text('No cars listed yet. Use the Host tab to list a vehicle.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: cars.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final car = cars[index];
            final name = '${car['brand'] ?? ''} ${car['model'] ?? ''}'.trim();
            final city = car['city'] ?? 'Unknown city';
            final price = car['price_per_day'] ?? car['dailyPrice'] ?? 0;
            final isAvailable = car['is_available'] == true;
            final status = car['status'] ?? 'unknown';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : 'My Car', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('City: $city', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Price/day: ₹$price', style: const TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Status: ${status.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(isAvailable ? 'Available for booking' : 'Currently unavailable', style: TextStyle(color: isAvailable ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1:
        return _buildMyBookingsTab();
      case 2:
        return _buildMyCarTab();
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

            onPickupLocationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location selection will be connected soon.',
                  ),
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
                    content: Text(
                      'Please fill all search details',
                    ),
                  ),
                );
                return;
              }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile coming soon'),
      ),
    );
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
      const SnackBar(
        content: Text('Favorites coming soon'),
      ),
    );
  },

  onSupportTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support coming soon'),
      ),
    );
  },

  onHostTap: () async {
    Navigator.pop(context);
    await _goHost();
  },

  onSettingsTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings coming soon'),
      ),
    );
  },

  onHelpTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & FAQs coming soon'),
      ),
    );
  },

  onPrivacyTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy coming soon'),
      ),
    );
  },

  onLogoutTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logout coming soon'),
      ),
    );
  },
),

      body: SafeArea(
        child: _navIndex == 1
            ? MyBookingsScreen(
                onExplorePressed: () {
                  setState(() {
                    _navIndex = 0;
                    _vehiclesFuture = _fetchHomeVehicles();
                  });
                },
              )
            : _navIndex == 2
                ? MyCarsScreen(
                    onListCarPressed: () async {
                      await _goHost();
                      // after returning from host flow, refresh
                      setState(() {
                        _vehiclesFuture = _fetchHomeVehicles();
                      });
                    },
                  )
                : SingleChildScrollView(
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

                      onPickupLocationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Location selection will be connected soon.',
                            ),
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
                          onCarTap: (car) async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CarDetailScreen(car: car),
                              ),
                            );
                            if (mounted) {
                              setState(() {
                                _vehiclesFuture = _fetchHomeVehicles();
                              });
                            }
                          },
                          onBookNow: (car) async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CarDetailScreen(car: car),
                              ),
                            );
                            if (mounted) {
                              setState(() {
                                _vehiclesFuture = _fetchHomeVehicles();
                              });
                            }
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