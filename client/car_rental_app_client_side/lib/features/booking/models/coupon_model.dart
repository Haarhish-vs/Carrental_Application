import 'package:equatable/equatable.dart';

class Coupon extends Equatable {
  final String code;
  final double discountAmount;
  final double percentage; // 0-100 (e.g. 20%)
  final double minBookingValue;
  final String description;

  const Coupon({
    required this.code,
    required this.discountAmount,
    required this.percentage,
    required this.minBookingValue,
    required this.description,
  });

  Coupon copyWith({
    String? code,
    double? discountAmount,
    double? percentage,
    double? minBookingValue,
    String? description,
  }) {
    return Coupon(
      code: code ?? this.code,
      discountAmount: discountAmount ?? this.discountAmount,
      percentage: percentage ?? this.percentage,
      minBookingValue: minBookingValue ?? this.minBookingValue,
      description: description ?? this.description,
    );
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] as String,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      minBookingValue: (json['minBookingValue'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'percentage': percentage,
      'minBookingValue': minBookingValue,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [code, discountAmount, percentage, minBookingValue, description];
}
