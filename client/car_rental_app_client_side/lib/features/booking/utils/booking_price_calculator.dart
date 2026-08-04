import '../models/booking_flow_state.dart';

class BookingPriceCalculator {
  BookingPriceCalculator._();

  static double calculateBaseRentalCharge(BookingFlowState state) {
    if (state.vehicle == null) return 0.0;
    return state.vehicle!.pricePerDay * state.rentalDurationDays;
  }

  static double calculateDriverFee(BookingFlowState state) {
    if (state.rentalType == RentalType.selfDrive || state.driver == null) return 0.0;
    return state.driver!.pricePerDay * state.rentalDurationDays;
  }

  static double calculateInsurance(BookingFlowState state) {
    // Separate out insurance from general addons for summary transparency
    final hasInsurance = state.selectedServices.any((s) => s.id == 'srv_insurance');
    if (!hasInsurance) return 0.0;
    
    final insurance = state.selectedServices.firstWhere((s) => s.id == 'srv_insurance');
    return insurance.isReoccurring 
        ? insurance.price * state.rentalDurationDays 
        : insurance.price;
  }

  static double calculateAdditionalServices(BookingFlowState state) {
    double total = 0.0;
    for (final service in state.selectedServices) {
      if (service.id == 'srv_insurance') continue; // Handled separately
      if (service.isReoccurring) {
        total += service.price * state.rentalDurationDays;
      } else {
        total += service.price;
      }
    }
    return total;
  }

  static double calculateSubtotal(BookingFlowState state) {
    return calculateBaseRentalCharge(state) +
        calculateDriverFee(state) +
        calculateInsurance(state) +
        calculateAdditionalServices(state);
  }

  static double calculateDiscount(BookingFlowState state) {
    if (state.coupon == null) return 0.0;
    final subtotal = calculateBaseRentalCharge(state); // Coupon typically applies to vehicle subtotal
    
    if (state.coupon!.percentage > 0) {
      return subtotal * (state.coupon!.percentage / 100.0);
    }
    return state.coupon!.discountAmount;
  }

  static double calculateTax(BookingFlowState state) {
    final subtotal = calculateSubtotal(state);
    final discount = calculateDiscount(state);
    final taxable = subtotal - discount;
    if (taxable <= 0) return 0.0;
    return taxable * 0.18; // 18% tax rate
  }

  static double calculateSecurityDeposit(BookingFlowState state) {
    if (state.vehicle == null) return 0.0;
    return 150.0; // Standard refundable card security deposit
  }

  static double calculateGrandTotal(BookingFlowState state) {
    final subtotal = calculateSubtotal(state);
    final discount = calculateDiscount(state);
    final tax = calculateTax(state);
    final deposit = calculateSecurityDeposit(state);
    return (subtotal - discount) + tax + deposit;
  }
}
