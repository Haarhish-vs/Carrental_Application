import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isReoccurring; // true = per day, false = flat fee

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isReoccurring,
  });

  Service copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isReoccurring,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isReoccurring: isReoccurring ?? this.isReoccurring,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      isReoccurring: json['isReoccurring'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'isReoccurring': isReoccurring,
    };
  }

  @override
  List<Object?> get props => [id, name, description, price, isReoccurring];
}
