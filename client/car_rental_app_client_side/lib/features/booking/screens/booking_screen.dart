import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../../models/booking_flow_state.dart';
import '../../models/vehicle_model.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _returnController = TextEditingController();

  // Mock static vehicles for presentation
  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: "veh_tesla",
      name: "Tesla Model S Plaid",
      imageUrl: AppImages.mockCarTesla,
      pricePerDay: 149.0,
      specifications: ["Electric", "1020 HP", "5 Seats", "Auto"],
      rating: 4.95,
    ),
    const Vehicle(
      id: "veh_audi",
      name: "Audi R8 Spyder",
      imageUrl: AppImages.mockCarAudi,
      pricePerDay: 199.0,
      specifications: ["Petrol", "562 HP", "2 Seats", "Auto"],
      rating: 4.88,
    ),
    const Vehicle(
      id: "veh_porsche",
      name: "Porsche 911 Carrera",
      imageUrl: AppImages.mockCarPorsche,
      pricePerDay: 179.0,
      specifications: ["Petrol", "379 HP", "4 Seats", "PDK"],
      rating: 4.92,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default initial selections on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = ref.read(bookingFlowProvider);
      if (flow.vehicle == null) {
        ref.read(bookingFlowProvider.notifier).setVehicle(_vehicles[0]);
      }
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.vehicle);
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);

    return AppScaffold(
      title: "Confirm Your Reservation",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vehicle Specifications", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Complete details in Checkpoint 3.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            
            // Standard action button
            ElevatedButton(
              onPressed: () {
                // Progress to Step 2
                ref.read(bookingFlowProvider.notifier).nextStep();
                context.push(AppRoutes.additionalServices);
              },
              child: const Text("Go to Additional Services"),
            ),
          ],
        ),
      ),
    );
  }
}
