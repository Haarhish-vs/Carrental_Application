import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future<String> openRazorpayCheckout({
  required String keyId,
  required double amountInRupees,
  required String name,
  required String description,
}) {
  final completer = Completer<String>();
  final razorpay = Razorpay();

  final amountInPaise = (amountInRupees * 100).round();

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    completer.complete(response.paymentId ?? 'success_no_id');
    razorpay.clear();
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    completer.completeError(Exception(response.message ?? 'Payment failed'));
    razorpay.clear();
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
    completer.completeError(Exception('External wallet selected: ${response.walletName}'));
    razorpay.clear();
  });

  final options = {
    'key': keyId,
    'amount': amountInPaise,
    'name': name,
    'description': description,
    'currency': 'INR',
  };

  try {
    razorpay.open(options);
  } catch (e) {
    completer.completeError(Exception('Could not launch Razorpay: $e'));
    razorpay.clear();
  }

  return completer.future;
}
