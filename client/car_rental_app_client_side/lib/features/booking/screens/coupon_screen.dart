import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/coupon_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/coupon_card.dart';

class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _showSuccessAnimation = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCoupon(String code) async {
    if (code.trim().isEmpty) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final success = await ref.read(bookingFlowProvider.notifier).applyCoupon(code.trim());
    if (success) {
      setState(() {
        _showSuccessAnimation = true;
      });
      // Show success animation for 1s, then go back
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final couponsAsync = ref.watch(couponsListProvider);

    return AppScaffold(
      title: "Apply Coupon",
      showProgress: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter Promo Code", style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
            const Gap(AppSpacing.xs),
            Text(
              "Type or select an active coupon code to redeem discount savings.",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500),
            ),
            const Gap(AppSpacing.lg),

            // Coupon Textfield Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "E.g. DRIVE20",
                      errorText: flowState.errorMessage,
                      prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.slate400),
                      fillColor: Colors.white,
                    ),
                    onChanged: (_) {
                      // Clear errors while typing
                      if (flowState.errorMessage != null) {
                        ref.read(bookingFlowProvider.notifier).applyCoupon(""); // reset error
                      }
                    },
                    onSubmitted: (val) => _submitCoupon(val),
                  ),
                ),
                const Gap(AppSpacing.md),
                ElevatedButton(
                  onPressed: flowState.isLoading
                      ? null
                      : () => _submitCoupon(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(90, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: flowState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Apply",
                          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
            
            // Success State Badge
            if (_showSuccessAnimation) ...[
              const Gap(AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.accent),
                    Gap(8),
                    Text(
                      "Promo Applied! Saving you money...",
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Gap(AppSpacing.xl),
            const Divider(),
            const Gap(AppSpacing.md),
            
            Text(
              "Available Special Deals",
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(AppSpacing.md),

            // Available coupon list view
            couponsAsync.when(
              data: (coupons) {
                if (coupons.isEmpty) {
                  return Text("No active coupons found.", style: AppTextStyles.bodyMedium);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    final isApplied = flowState.coupon?.code == coupon.code;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CouponCard(
                        coupon: coupon,
                        isApplied: isApplied,
                        onTap: () {
                          if (isApplied) {
                            ref.read(bookingFlowProvider.notifier).removeCoupon();
                            _codeController.clear();
                          } else {
                            _codeController.text = coupon.code;
                            _submitCoupon(coupon.code);
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text("Error loading deals: $err", style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
