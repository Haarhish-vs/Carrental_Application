import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/indian_currency_formatter.dart';
import '../../models/customer_car_model.dart';
import '../../models/customer_dummy_data.dart';

/// Professional Customer Rental Marketplace Experience.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<String> _favoriteCarIds = {};

  @override
  Widget build(BuildContext context) {
    final filteredCars = CustomerDummyData.cars.where((car) {
      final matchesCategory = _selectedCategory == 'All' || car.category == _selectedCategory;
      final matchesSearch = car.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DriveEase',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.ink),
                ),
                Text(
                  'Bengaluru, KA · Tap to change',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/owner'),
              icon: const Icon(Icons.dashboard_rounded, size: 16),
              label: const Text('Owner Portal', style: TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(60, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth > 1100
                  ? 4
                  : maxWidth > 800
                      ? 3
                      : maxWidth > 550
                          ? 2
                          : 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HERO BANNER & SEARCH
                  _buildHeroBanner(context),
                  const SizedBox(height: 24),

                  // 2. CATEGORY SELECTOR CHIPS
                  const Text(
                    'Explore Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),
                  const SizedBox(height: 24),

                  // 3. FEATURED CAR FLEET GRID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Fleet (${filteredCars.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                      if (filteredCars.isNotEmpty)
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredCars.isEmpty)
                    _buildEmptyState()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 330,
                      ),
                      itemCount: filteredCars.length,
                      itemBuilder: (context, index) {
                        final car = filteredCars[index];
                        final isFav = _favoriteCarIds.contains(car.id);
                        return _CarCard(
                          car: car,
                          isFavorite: isFav,
                          onFavoriteToggle: () {
                            setState(() {
                              if (isFav) {
                                _favoriteCarIds.remove(car.id);
                              } else {
                                _favoriteCarIds.add(car.id);
                              }
                            });
                          },
                          onBookTap: () => _showBookingModal(context, car),
                        );
                      },
                    ),
                  const SizedBox(height: 32),

                  // 4. PROMO OFFER BANNER
                  _buildPromoBanner(),
                  const SizedBox(height: 32),

                  // 5. POPULAR DESTINATIONS
                  const Text(
                    'Popular Roadtrip Destinations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  _buildDestinationsList(),
                  const SizedBox(height: 32),

                  // 6. WHY CHOOSE US
                  const Text(
                    'Why Rent With Us',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  _buildWhyUsGrid(maxWidth),
                  const SizedBox(height: 32),

                  // 7. HOW IT WORKS
                  const Text(
                    'How It Works',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  _buildHowItWorksRow(maxWidth),
                  const SizedBox(height: 32),

                  // 8. FAQS
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  _buildFaqsSection(),
                  const SizedBox(height: 40),

                  // FOOTER
                  Center(
                    child: Text(
                      '© 2026 DriveEase Car Rental Platform · All prices in Indian Rupees (₹)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1E293B), Color(0xff3663F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚡ Self-Drive Cars in India',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Drive Your Dream Car Today',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Sanitized vehicles with zero security deposit and free doorstep delivery.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Search Input Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by car model, brand, or city...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CustomerDummyData.categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat['name']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat['name']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_car_sharp, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No cars match your search filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Try clearing your search query or selecting a different category.', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              _selectedCategory = 'All';
              _searchQuery = '';
            }),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Offer: Flat 20% OFF',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff78350F)),
                ),
                SizedBox(height: 2),
                Text(
                  'Use code DRIVE20 on your first booking above ₹3,000.',
                  style: TextStyle(fontSize: 12, color: Color(0xff92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: CustomerDummyData.destinations.length,
        itemBuilder: (context, index) {
          final dest = CustomerDummyData.destinations[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dest['city']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(dest['tag']!, style: const TextStyle(fontSize: 11.5, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(dest['trips']!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhyUsGrid(double maxWidth) {
    final isMobile = maxWidth < 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        mainAxisExtent: 90,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: CustomerDummyData.whyUs.length,
      itemBuilder: (context, index) {
        final item = CustomerDummyData.whyUs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryContainer,
                child: Icon(Icons.check_rounded, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(item['desc']!, style: const TextStyle(fontSize: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHowItWorksRow(double maxWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final items = CustomerDummyData.howItWorks.map((step) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['step']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const SizedBox(height: 6),
                Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(step['desc']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          );
        }).toList();

        if (isSmall) {
          return Column(
            children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList(),
          );
        }

        return Row(
          children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w))).toList(),
        );
      },
    );
  }

  Widget _buildFaqsSection() {
    return Column(
      children: CustomerDummyData.faqs.map((faq) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: ExpansionTile(
            title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.ink)),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
            children: [
              Text(faq['a']!, style: const TextStyle(fontSize: 12.5, color: Color(0xB3000000))),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showBookingModal(BuildContext context, CustomerCarModel car) {
    const days = 3;
    final totalBase = car.pricePerDay * days;
    const insuranceFee = 499.0;
    final gst = totalBase * 0.18;
    final grandTotal = totalBase + insuranceFee + gst;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(car.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Text('${car.brand} · ${car.category} · ${car.location}', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
              const Divider(height: 24),
              const Text('Rental Price Summary (3 Days)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              _buildPriceRow('Base Rental (${IndianCurrencyFormatter.format(car.pricePerDay)} × 3 days)', IndianCurrencyFormatter.format(totalBase)),
              _buildPriceRow('Comprehensive Insurance', IndianCurrencyFormatter.format(insuranceFee)),
              _buildPriceRow('GST (18%)', IndianCurrencyFormatter.format(gst)),
              const Divider(height: 20),
              _buildPriceRow('Total Amount', IndianCurrencyFormatter.format(grandTotal), isBold: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking request for ${car.name} submitted successfully!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  child: Text('Confirm Booking · ${IndianCurrencyFormatter.format(grandTotal)}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: isBold ? AppTheme.primary : AppTheme.ink)),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBookTap,
  });

  final CustomerCarModel car;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge + Favorite
          Stack(
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.directions_car_filled_rounded, size: 54, color: AppTheme.primary),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : Colors.black45,
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                ),
              ),
              if (car.isFeatured)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Featured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        car.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xffFBBF24)),
                        const SizedBox(width: 2),
                        Text('${car.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${car.transmission} · ${car.fuelType} · ${car.seats} Seats',
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          IndianCurrencyFormatter.format(car.pricePerDay),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
                        ),
                        const Text('/day', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onBookTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Book Now', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
