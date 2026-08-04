import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_routes.dart';
import '../models/booking_step.dart';
import '../providers/booking_provider.dart';
import '../models/booking_flow_state.dart';

// Screens imports (to be implemented next)
import '../screens/booking_screen.dart';
import '../screens/driver_selection_screen.dart';
import '../screens/additional_services_screen.dart';
import '../screens/booking_summary_screen.dart';
import '../screens/coupon_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/booking_success_screen.dart';
import '../screens/booking_details_screen.dart';

class BookingRoutes {
  BookingRoutes._();

  static List<RouteBase> get routes {
    return [
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverSelection,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          // Route Guard: Vehicle must be selected and withDriver active
          if (flowState.vehicle == null) {
            return AppRoutes.booking;
          }
          if (flowState.rentalType == RentalType.selfDrive) {
            return AppRoutes.additionalServices;
          }
          return null; // Allow navigation
        },
        builder: (context, state) => const DriverSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.additionalServices,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          // Route Guard: Vehicle must be selected
          if (flowState.vehicle == null) {
            return AppRoutes.booking;
          }
          return null;
        },
        builder: (context, state) => const AdditionalServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingSummary,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          // Route Guard: Vehicle and pickup details must be set
          if (flowState.vehicle == null || flowState.pickupDateTime == null) {
            return AppRoutes.booking;
          }
          return null;
        },
        builder: (context, state) => const BookingSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupon,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          if (flowState.vehicle == null) {
            return AppRoutes.booking;
          }
          return null;
        },
        builder: (context, state) => const CouponScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          if (flowState.vehicle == null || flowState.pickupDateTime == null) {
            return AppRoutes.booking;
          }
          return null;
        },
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context, listen: false);
          final flowState = container.read(bookingFlowProvider);

          // Route Guard: Must have a submitted booking transaction
          if (flowState.bookingId == null) {
            return AppRoutes.booking;
          }
          return null;
        },
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        // Allow optional path parameter for specific booking ID query
        path: '${AppRoutes.bookingDetails}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookingDetailsScreen(bookingId: id);
        },
      ),
    ];
  }
}
