import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  // Uses en_IN locale for proper Indian numbering format (e.g. ₹3,926.00)
  return NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  ).format(amount);
}
