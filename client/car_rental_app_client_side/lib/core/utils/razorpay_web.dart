// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Opens the Razorpay payment gateway using the web checkout.js SDK.
/// Returns the razorpay_payment_id on success, throws on failure/cancel.
Future<String> openRazorpayCheckout({
  required String keyId,
  required double amountInRupees,
  required String name,
  required String description,
}) {
  // Razorpay expects amount in **paise** (1 INR = 100 paise)
  final amountInPaise = (amountInRupees * 100).round();

  final completer = _Completer<String>();

  // JS callback for success
  final onSuccess = js.allowInterop((String paymentId) {
    completer.complete(paymentId);
  });

  // JS callback for failure / cancel
  final onFailure = js.allowInterop((String reason) {
    completer.completeError(Exception(reason));
  });

  js.context.callMethod('openRazorpay', [
    keyId,
    amountInPaise,
    'INR',
    name,
    description,
    onSuccess,
    onFailure,
  ]);

  return completer.future;
}

// Simple Completer wrapper
class _Completer<T> {
  _Completer();

  final _callbacks = <Function>[];
  final _errorCallbacks = <Function>[];
  T? _value;
  Object? _error;
  bool _done = false;
  bool _isError = false;

  void complete(T value) {
    _value = value;
    _done = true;
    for (final cb in _callbacks) {
      cb(value);
    }
  }

  void completeError(Object error) {
    _error = error;
    _isError = true;
    _done = true;
    for (final cb in _errorCallbacks) {
      cb(error);
    }
  }

  Future<T> get future {
    if (_done && !_isError) return Future.value(_value as T);
    if (_done && _isError) return Future.error(_error!);
    return _makeFuture();
  }

  Future<T> _makeFuture() {
    return Future<T>(() async {
      while (!_done) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_isError) throw _error!;
      return _value as T;
    });
  }
}
