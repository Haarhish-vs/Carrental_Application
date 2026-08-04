# Booking Module Flow Documentation

This document describes the user flow through the Car Rental Booking Module.

## Flow Sequence

```
[Vehicle Details Screen]
          │
          ▼ (Book Now)
[Booking Screen (Step 1: Specs & Step 2: Pickup/Return Dates)]
          │
          ▼ (Continue)
[Rental Mode Check]
   ├─── With Driver  ───► [Driver Selection Screen (Step 3)]
   │                               │
   │                               ▼
   └─── Self Drive ───────────────► [Additional Services (Step 4)]
                                           │
                                           ▼
                                 [Booking Summary (Step 5)]
                                           │
                                           ▼ (Apply Coupon)
                                 [Payment Selection (Step 6)]
                                           │
                                           ▼ (Confirm Reservation)
                                 [Booking Success (Step 7)]
                                           │
                                           ▼ (Track Details)
                                 [Booking Details Screen (Step 8)]
```

## Step Descriptions

1. **Step 1: Vehicle Details**: View specifications (Automatic/Manual, Seats, Fuel type) and rental pricing metrics.
2. **Step 2: Pickup & Return Settings**: Choose locations, dates, and times. Choose rental style (Self Drive vs. Driver).
3. **Step 3: Driver Selection**: Browse verified driver profiles with ratings, experience, languages, and pricing.
4. **Step 4: Optional Add-ons**: Add insurance, extra drivers, child seats, GPS, and Wi-Fi hotspot options.
5. **Step 5: Checkout Summary**: Review detailed price breakdown (driver fees, services, deposit, tax adjustments).
6. **Step 6: Coupon Sheet**: Apply discount codes.
7. **Step 7: Payment Options UI**: Choose payment method.
8. **Step 8: Success State**: View lottie animation and invoice download buttons.
9. **Step 9: Real-time Timeline**: View active rental status (Confirmed, Active, Completed, Cancelled).
