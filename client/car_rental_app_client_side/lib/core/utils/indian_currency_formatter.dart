import 'package:flutter/foundation.dart';

/// Utility class for formatting currency values using Indian Numbering Conventions.
/// Examples:
/// - 999 -> ₹999
/// - 1500 -> ₹1,500
/// - 25000 -> ₹25,000
/// - 125000 -> ₹1,25,000
/// - 1250000 -> ₹12,50,000
@immutable
abstract final class IndianCurrencyFormatter {
  /// Formats a numeric value into an Indian Rupee string representation.
  static String format(
    num amount, {
    bool symbol = true,
    int decimalDigits = 0,
    bool compact = false,
  }) {
    final prefix = symbol ? '₹' : '';

    if (compact) {
      if (amount >= 10000000) {
        final cr = amount / 10000000;
        return '$prefix${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 1)} Cr';
      } else if (amount >= 100000) {
        final lakh = amount / 100000;
        return '$prefix${lakh.toStringAsFixed(lakh.truncateToDouble() == lakh ? 0 : 1)} Lakh';
      } else if (amount >= 1000) {
        final k = amount / 1000;
        return '$prefix${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
      }
    }

    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(decimalDigits).split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 && decimalDigits > 0 ? '.${parts[1]}' : '';

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      var remaining = integerPart.substring(0, integerPart.length - 3);
      final List<String> chunks = [];
      while (remaining.length > 2) {
        chunks.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      if (remaining.isNotEmpty) {
        chunks.insert(0, remaining);
      }
      integerPart = '${chunks.join(',')},$lastThree';
    }

    final sign = isNegative ? '-' : '';
    return '$sign$prefix$integerPart$decimalPart';
  }

  /// Replaces US Dollar ($) symbols and formats numbers found within arbitrary strings.
  static String convertString(String input) {
    if (!input.contains('\$')) return input;
    final regex = RegExp(r'\$([0-9,]+(?:\.[0-9]+)?)');
    return input.replaceAllMapped(regex, (match) {
      final valStr = match.group(1)?.replaceAll(',', '') ?? '0';
      final val = num.tryParse(valStr) ?? 0;
      return format(val);
    });
  }
}
