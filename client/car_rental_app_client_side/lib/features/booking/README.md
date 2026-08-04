# Feature: Booking Module

This folder contains the frontend module for car booking, driver assignment, optional accessories, coupons, checkout calculation, and status tracking.

## Architecture

This feature follows **Clean Feature-First Architecture**:

```
lib/features/booking/
├── models/         # Immutable models (Vehicle, Driver, Service, Coupon, BookingFlowState)
├── services/       # Mock services fetching local JSON assets through ApiClient
├── repositories/   # Repositories coordinating mock endpoints for easy swapping
├── providers/      # Riverpod providers managing flow selections and validations
├── navigation/     # GoRouter paths, sub-routes, and state Route Guards
├── utils/          # Calculation helper modules (BookingPriceCalculator)
├── screens/        # Premium step checkout screens
└── widgets/        # Component widgets (cards, bottom sheets, timelines, buttons)
```

## State Flow

All data is stored inside a single `BookingFlowState` handled by `BookingFlowNotifier`.
State recalculates details dynamically via `BookingPriceCalculator` upon any mutation.

## Navigation and Route Guards

- `/booking`: Starting view (Vehicle and pick-up details)
- `/booking/driver-selection`: Available only when "With Driver" is active.
- `/booking/services`: Optional addons page.
- `/booking/summary`: Detailed calculations.
- `/booking/coupon`: Coupon application page.
- `/booking/payment`: Payment method selector.
- `/booking/success`: Receipt confirmation (Lottie animation).
- `/booking/details`: Post-booking active trip timeline.

**Route Guards**: Ensure that users cannot access `/booking/summary` or `/booking/success` unless dates, vehicles, and location properties have been set.
