import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/car_model.dart';
import 'reserve_screen.dart';

class CarDetailScreen extends StatefulWidget {
  const CarDetailScreen({super.key, required this.car});

  final CarModel car;

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isLiked = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSpecCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.car.images.isNotEmpty 
        ? widget.car.images 
        : (widget.car.imageUrl.isNotEmpty ? [widget.car.imageUrl] : []);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Carousel & Back/Share overlays
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFEAF2FF),
                                child: const Icon(Icons.directions_car, size: 70, color: AppColors.primary),
                              ),
                            );
                          },
                        ),
                      ),

                      // Heart & Share Icon buttons on Top Right
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 16,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              radius: 20,
                              child: IconButton(
                                icon: Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.grey.shade700,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isLiked = !_isLiked;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              radius: 20,
                              child: IconButton(
                                icon: Icon(Icons.share_outlined, color: Colors.grey.shade700, size: 18),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Back Button on Top Left
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      // 360 View overlay badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.threed_rotation_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                "360 View",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Carousel Dot Indicators
                      if (images.length > 1)
                        Positioned(
                          bottom: 18,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 12 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _currentImageIndex == index
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.8),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // 2. Info Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.car.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),

                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              widget.car.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              ' - 120 reviews',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Host Info Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hosted by Michael',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Owner',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Specifications grid
                        const Text(
                          'Specifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            _buildSpecCard(Icons.local_gas_station_outlined, 'Fuel Type', widget.car.fuelType),
                            _buildSpecCard(Icons.settings_outlined, 'Transmission', widget.car.transmission),
                            _buildSpecCard(Icons.airline_seat_recline_normal_outlined, 'Seats', '${widget.car.seats} Seats'),
                            _buildSpecCard(Icons.ac_unit_outlined, 'AC', 'Climate Control'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSpecCard(Icons.map_outlined, 'Navigation', 'Built-in GPS'),
                        const SizedBox(height: 24),

                        // Included in your booking
                        const Text(
                          'Included in your booking',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 14, color: AppColors.success),
                            ),
                            const SizedBox(width: 12),
                            const Text('Unlimited KM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 14, color: AppColors.success),
                            ),
                            const SizedBox(width: 12),
                            const Text('24/7 Roadside Assistance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Sticky bar (TOTAL PRICE & Reserve button)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${widget.car.pricePerDay.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              ' / day',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // Auth guard: must be logged in to reserve
                          if (!AuthService.isAuthenticated) {
                            final loggedIn = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(initialMode: AuthMode.login),
                              ),
                            );
                            if (loggedIn != true || !context.mounted) return;
                          }

                          if (AuthService.isAuthenticated &&
                              AuthService.currentUser != null &&
                              AuthService.currentUser!['id'] == widget.car.ownerId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You cannot book your own vehicle'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReserveScreen(car: widget.car),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Reserve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
