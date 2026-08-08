import 'dart:async';
import 'dart:js_interop';

@JS('openRazorpay')
external void _openRazorpay(
  JSString keyId,
  JSNumber amountInPaise,
  JSString currency,
  JSString name,
  JSString description,
  JSFunction onSuccess,
  JSFunction onFailure,
);

/// Opens the Razorpay payment gateway using the web checkout.js SDK.
/// Returns the razorpay_payment_id on success, throws on failure/cancel.
Future<String> openRazorpayCheckout({
  required String keyId,
  required double amountInRupees,
  required String name,
  required String description,
}) {
  final amountInPaise = (amountInRupees * 100).round();
  final completer = Completer<String>();

  final onSuccess = ((JSString paymentId) {
    completer.complete(paymentId.toDart);
  }).toJS;

  final onFailure = ((JSString reason) {
    completer.completeError(Exception(reason.toDart));
  }).toJS;

  try {
    _openRazorpay(
      keyId.toJS,
      amountInPaise.toJS,
      'INR'.toJS,
      name.toJS,
      description.toJS,
      onSuccess,
      onFailure,
    );
  } catch (e) {
    completer.completeError(e);
  }

  return completer.future;
}
