class UserProfileModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String profileImageUrl;
  final bool isDlVerified;
  final double trustScore;
  final double rating;
  final int reviewsCount;

  // Account types
  final bool isRenter;
  final int bookedCarsCount;
  final bool isOwner;
  final int listedCarsCount;

  // Activity stats
  final int totalBookings;
  final int activeBookings;
  final int completedTrips;
  final int carsListed;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email = '',
    this.profileImageUrl = '',
    this.isDlVerified = false,
    this.trustScore = 100.0,
    this.rating = 4.8,
    this.reviewsCount = 0,
    this.isRenter = true,
    this.bookedCarsCount = 0,
    this.isOwner = false,
    this.listedCarsCount = 0,
    this.totalBookings = 0,
    this.activeBookings = 0,
    this.completedTrips = 0,
    this.carsListed = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final accountType = json['accountType'] as Map<String, dynamic>? ?? {};
    final activity = json['activity'] as Map<String, dynamic>? ?? {};

    final trust = double.tryParse(json['trustScore']?.toString() ?? json['trust_score']?.toString() ?? '') ?? 100.0;
    final rate = double.tryParse(json['rating']?.toString() ?? '') ?? (trust > 0 ? trust / 20.0 : 4.8);

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? 'User',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString() ?? json['profile_image_url']?.toString() ?? '',
      isDlVerified: (json['isDlVerified'] == true || json['is_dl_verified'] == true),
      trustScore: trust,
      rating: rate,
      reviewsCount: int.tryParse(json['reviewsCount']?.toString() ?? json['reviews_count']?.toString() ?? '') ?? 0,
      isRenter: (accountType['isRenter'] == true || accountType['is_renter'] == true || true),
      bookedCarsCount: int.tryParse(accountType['bookedCarsCount']?.toString() ?? accountType['booked_cars_count']?.toString() ?? '') ??
          (int.tryParse(activity['totalBookings']?.toString() ?? '') ?? 0),
      isOwner: (accountType['isOwner'] == true || accountType['is_owner'] == true),
      listedCarsCount: int.tryParse(accountType['listedCarsCount']?.toString() ?? accountType['listed_cars_count']?.toString() ?? '') ??
          (int.tryParse(activity['carsListed']?.toString() ?? '') ?? 0),
      totalBookings: int.tryParse(activity['totalBookings']?.toString() ?? activity['total_bookings']?.toString() ?? '') ?? 0,
      activeBookings: int.tryParse(activity['activeBookings']?.toString() ?? activity['active_bookings']?.toString() ?? '') ?? 0,
      completedTrips: int.tryParse(activity['completedTrips']?.toString() ?? activity['completed_trips']?.toString() ?? '') ?? 0,
      carsListed: int.tryParse(activity['carsListed']?.toString() ?? activity['cars_listed']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isDlVerified': isDlVerified,
      'trustScore': trustScore,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'accountType': {
        'isRenter': isRenter,
        'bookedCarsCount': bookedCarsCount,
        'isOwner': isOwner,
        'listedCarsCount': listedCarsCount,
      },
      'activity': {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'completedTrips': completedTrips,
        'carsListed': carsListed,
      },
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
    bool? isDlVerified,
    double? trustScore,
    double? rating,
    int? reviewsCount,
    bool? isRenter,
    int? bookedCarsCount,
    bool? isOwner,
    int? listedCarsCount,
    int? totalBookings,
    int? activeBookings,
    int? completedTrips,
    int? carsListed,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isDlVerified: isDlVerified ?? this.isDlVerified,
      trustScore: trustScore ?? this.trustScore,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isRenter: isRenter ?? this.isRenter,
      bookedCarsCount: bookedCarsCount ?? this.bookedCarsCount,
      isOwner: isOwner ?? this.isOwner,
      listedCarsCount: listedCarsCount ?? this.listedCarsCount,
      totalBookings: totalBookings ?? this.totalBookings,
      activeBookings: activeBookings ?? this.activeBookings,
      completedTrips: completedTrips ?? this.completedTrips,
      carsListed: carsListed ?? this.carsListed,
    );
  }
}
