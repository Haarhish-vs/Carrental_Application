import 'package:equatable/equatable.dart';
import 'vehicle_model.dart';
import 'driver_model.dart';
import 'service_model.dart';
import 'coupon_model.dart';
import 'booking_step.dart';
import 'location_model.dart';

enum RentalType { selfDrive, withDriver }

enum PaymentMethod { upi, creditCard, debitCard, wallet, netBanking }

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.netBanking:
        return 'Net Banking';
    }
  }
}

class BookingFlowState extends Equatable {
  final Vehicle? vehicle;
  final LocationModel? pickupLocation;
  final LocationModel? returnLocation;
  final DateTime? pickupDateTime;
  final DateTime? returnDateTime;
  final RentalType rentalType;
  final Driver? driver;
  final List<Service> selectedServices;
  final Coupon? coupon;
  final PaymentMethod? paymentMethod;
  final BookingStep currentStep;

  // Checkout & Status Details
  final String? bookingId;
  final bool isLoading;
  final String? errorMessage;

  const BookingFlowState({
    this.vehicle,
    this.pickupLocation,
    this.returnLocation,
    this.pickupDateTime,
    this.returnDateTime,
    this.rentalType = RentalType.selfDrive,
    this.driver,
    this.selectedServices = const [],
    this.coupon,
    this.paymentMethod,
    this.currentStep = BookingStep.vehicle,
    this.bookingId,
    this.isLoading = false,
    this.errorMessage,
  });

  BookingFlowState copyWith({
    Vehicle? Function()? vehicle,
    LocationModel? Function()? pickupLocation,
    LocationModel? Function()? returnLocation,
    DateTime? Function()? pickupDateTime,
    DateTime? Function()? returnDateTime,
    RentalType? rentalType,
    Driver? Function()? driver,
    List<Service>? selectedServices,
    Coupon? Function()? coupon,
    PaymentMethod? Function()? paymentMethod,
    BookingStep? currentStep,
    String? Function()? bookingId,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return BookingFlowState(
      vehicle: vehicle != null ? vehicle() : this.vehicle,
      pickupLocation: pickupLocation != null
          ? pickupLocation()
          : this.pickupLocation,
      returnLocation: returnLocation != null
          ? returnLocation()
          : this.returnLocation,
      pickupDateTime: pickupDateTime != null
          ? pickupDateTime()
          : this.pickupDateTime,
      returnDateTime: returnDateTime != null
          ? returnDateTime()
          : this.returnDateTime,
      rentalType: rentalType ?? this.rentalType,
      driver: driver != null ? driver() : this.driver,
      selectedServices: selectedServices ?? this.selectedServices,
      coupon: coupon != null ? coupon() : this.coupon,
      paymentMethod: paymentMethod != null
          ? paymentMethod()
          : this.paymentMethod,
      currentStep: currentStep ?? this.currentStep,
      bookingId: bookingId != null ? bookingId() : this.bookingId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  // Calculate rental duration in days (minimum 1 day)
  int get rentalDurationDays {
    if (pickupDateTime == null || returnDateTime == null) return 1;
    final difference = returnDateTime!.difference(pickupDateTime!);
    if (difference.isNegative) return 1;
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    // Round up if extra hours exist (e.g. 1 day 2 hours counts as 2 days)
    return hours > 0 ? days + 1 : (days == 0 ? 1 : days);
  }

  @override
  List<Object?> get props => [
    vehicle,
    pickupLocation,
    returnLocation,
    pickupDateTime,
    returnDateTime,
    rentalType,
    driver,
    selectedServices,
    coupon,
    paymentMethod,
    currentStep,
    bookingId,
    isLoading,
    errorMessage,
  ];
}
