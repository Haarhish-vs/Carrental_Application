import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/dummy_data.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _navIndex = 0;

  String? _userName;
  String? _userLocation;
  String? _pickupLocation;
  String? _pickupDate;
  String? _pickupTime;
  String? _returnDate;
  String? _returnTime;

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  Future<void> _pickDate({required bool isPickup}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked == null) return;

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

    if (picked == null) return;

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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trips coming soon'),
            ),
          );
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
                categories: DummyData.categories,
                onCategoryTap: (category) {},
              ),

              const SizedBox(height: 22),

              OfferCarousel(
                offers: DummyData.offers,
                onOfferTap: (offer) {},
              ),

              const SizedBox(height: 22),

              RecommendedCars(
                cars: DummyData.recommendedCars,
                onCarTap: (car) {},
                onBookNow: (car) {},
              ),

              const SizedBox(height: 26),

              WhyChooseUsSection(
                items: DummyData.whyChooseUs,
              ),

              const SizedBox(height: 26),

              const HowItWorksSection(),

              const SizedBox(height: 26),

              BecomeHostBanner(
                onHostTap: () {},
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
<<<<<<< Updated upstream
        onHomeTap: () => setState(() => _navIndex = 0),
        onTripsTap: () => setState(() => _navIndex = 1),
        onSupportTap: () => setState(() => _navIndex = 2),
        onHostTap: () => setState(() => _navIndex = 3),
=======

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
>>>>>>> Stashed changes
      ),
    );
  }
}