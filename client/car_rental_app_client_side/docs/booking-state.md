# Booking State Architecture

We utilize a single, unified `BookingFlowState` class backed by a Riverpod `NotifierProvider` (`bookingFlowProvider`) to handle state changes throughout the modular booking flow.

## State Fields

- **vehicle**: Currently selected Vehicle details.
- **pickupLocation**: Pickup address/terminal.
- **returnLocation**: Return address/terminal.
- **pickupDateTime**: Combined Date and Time for vehicle release.
- **returnDateTime**: Combined Date and Time for vehicle return.
- **rentalType**: RentalType enum (`selfDrive` or `withDriver`).
- **driver**: Selected Driver details (nullable).
- **selectedServices**: List of chosen Additional Services.
- **coupon**: Applied promo code details (nullable).
- **paymentMethod**: Chosen payment channel (nullable).
- **currentStep**: Active step index represented by the `BookingStep` enum.
- **status**: Booking status (e.g. pending, success).

## Flow Diagram

```
User Input ──► Provider Notifier ──► State Mutation ──► Price Calculator ──► UI Re-render
```

## Calculations

To separate concerns, the `BookingPriceCalculator` utility evaluates:
- Base Rental Charge = Days * Vehicle Price
- Driver Charge = Days * Driver Price (if `withDriver` selected)
- Services Charge = Sum(Addons flat) + Sum(Addons daily * Days)
- Subtotal = Base + Driver + Services
- Discount = Coupon percentage/flat reduction
- Tax = (Subtotal - Discount) * TaxRate (e.g. 18%)
- Deposit = Refundable security deposit
- Grand Total = Subtotal - Discount + Tax + Deposit
