// This stub file is used when neither web nor mobile libraries are available.
Future<String> openRazorpayCheckout({
  required String keyId,
  required double amountInRupees,
  required String name,
  required String description,
}) {
  throw UnsupportedError('Razorpay is not supported on this platform');
}
