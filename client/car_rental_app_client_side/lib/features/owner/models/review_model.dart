class ReviewModel {
  const ReviewModel({
    required this.customerName,
    required this.carName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String customerName;
  final String carName;
  final double rating;
  final String comment;
  final DateTime date;
}
