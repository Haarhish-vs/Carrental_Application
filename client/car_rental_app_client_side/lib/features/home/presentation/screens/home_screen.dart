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
    return vehicles.map(CarModel.fromJson).toList();
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

  Future<void> _pickDate({required bool isPickup}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
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
          });
        },

        onTripsTap: () {
          setState(() {
            _navIndex = 1;
          });
        },

        onSupportTap: () {
          setState(() {
            _navIndex = 2;
          });
        },

        onHostTap: _goHost,
      ),
    );
  }
}