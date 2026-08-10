import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';

class CarLoadingSkeleton extends StatefulWidget {
  const CarLoadingSkeleton({super.key});

  @override
  State<CarLoadingSkeleton> createState() => _CarLoadingSkeletonState();
}

class _CarLoadingSkeletonState extends State<CarLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(alpha: _animation.value),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200.withValues(alpha: _animation.value),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(alpha: _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 80,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(alpha: _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(alpha: _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 100,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(alpha: _animation.value),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              width: 110,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(alpha: _animation.value),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
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
    );
  }
}
