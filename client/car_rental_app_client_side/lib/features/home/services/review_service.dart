import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReviewModel {
  final String id;
  final String carId;
  final String userName;
  final double rating;
  final String feedback;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.carId,
    required this.userName,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'carId': carId,
        'userName': userName,
        'rating': rating,
        'feedback': feedback,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        carId: json['carId'] as String,
        userName: json['userName'] as String,
        rating: (json['rating'] as num).toDouble(),
        feedback: json['feedback'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ReviewService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static String _getKey(String carId) => 'reviews_$carId';

  static Future<List<ReviewModel>> getReviews(String carId) async {
    try {
      final String? data = await _storage.read(key: _getKey(carId));
      if (data == null || data.isEmpty) {
        return [
          ReviewModel(
            id: 'default_review_1',
            carId: carId,
            userName: 'Raja',
            rating: 4.5,
            feedback: 'Great car! The owner was very cooperative and the car was clean and smooth.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          )
        ];
      }

      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addReview(ReviewModel review) async {
    final List<ReviewModel> reviews = await getReviews(review.carId);
    reviews.add(review);
    
    final String data = jsonEncode(reviews.map((e) => e.toJson()).toList());
    await _storage.write(key: _getKey(review.carId), value: data);
  }

  static Future<double?> getAverageRating(String carId) async {
    final reviews = await getReviews(carId);
    if (reviews.isEmpty) return null; // Returns null if no reviews yet
    
    double total = 0;
    for (var r in reviews) {
      total += r.rating;
    }
    return total / reviews.length;
  }
}
