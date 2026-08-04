enum BookingStep {
  vehicle,
  pickup,
  driver,
  extras,
  summary,
  payment,
  success,
}

extension BookingStepExtension on BookingStep {
  int get index => BookingStep.values.indexOf(this);

  String get label {
    switch (this) {
      case BookingStep.vehicle:
        return 'Vehicle Details';
      case BookingStep.pickup:
        return 'Date & Location';
      case BookingStep.driver:
        return 'Driver Selection';
      case BookingStep.extras:
        return 'Add-ons';
      case BookingStep.summary:
        return 'Summary';
      case BookingStep.payment:
        return 'Payment';
      case BookingStep.success:
        return 'Success';
    }
  }

  // Helper to get step numbers for progress UI (e.g. "Step 1 of 6")
  int get stepNumber => index + 1;
}
