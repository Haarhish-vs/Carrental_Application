import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/feature_item_model.dart';

/// Dummy data source. Replace individual lists with API responses
/// once teammates' backend endpoints are ready — no widget changes needed.
class DummyData {
  DummyData._();

  static const List<CategoryModel> categories = [
    CategoryModel(id: '1', label: 'Daily Rental', icon: Icons.calendar_today_outlined),
    CategoryModel(id: '2', label: 'Weekly Rental', icon: Icons.date_range_outlined),
    CategoryModel(id: '3', label: 'SUV', icon: Icons.directions_car_filled_outlined),
    CategoryModel(id: '4', label: 'Luxury', icon: Icons.diamond_outlined),
    CategoryModel(id: '5', label: 'Electric', icon: Icons.electric_bolt_outlined),
    CategoryModel(id: '6', label: 'Automatic', icon: Icons.settings_outlined),
  ];

  static const List<OfferModel> offers = [
    OfferModel(
      id: '1',
      title: 'Weekend Offer',
      subtitle: 'Get 20% off on weekend bookings',
      imageUrl: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800',
    ),
    OfferModel(
      id: '2',
      title: 'Festival Offer',
      subtitle: 'Flat ₹500 cashback this festive season',
      imageUrl: 'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=800',
    ),
    OfferModel(
      id: '3',
      title: 'Refer & Earn',
      subtitle: 'Invite friends, earn ₹250 per referral',
      imageUrl: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800',
    ),
    OfferModel(
      id: '4',
      title: 'Host Your Car',
      subtitle: 'Turn your idle car into income',
      imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800',
    ),
  ];

  static const List<CarModel> recommendedCars = [
    CarModel(
      id: '1',
      name: 'Hyundai Creta',
      imageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=800',
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      rating: 4.8,
      pricePerDay: 2499,
    ),
    CarModel(
      id: '2',
      name: 'Tesla Model 3',
      imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800',
      transmission: 'Automatic',
      fuelType: 'Electric',
      seats: 5,
      rating: 4.9,
      pricePerDay: 5999,
    ),
    CarModel(
      id: '3',
      name: 'Mahindra Thar',
      imageUrl: 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=800',
      transmission: 'Manual',
      fuelType: 'Diesel',
      seats: 4,
      rating: 4.6,
      pricePerDay: 3299,
    ),
  ];

  static const List<CarModel> popularCars = [
    CarModel(
      id: '4',
      name: 'Maruti Swift',
      imageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
      transmission: 'Manual',
      fuelType: 'Petrol',
      seats: 5,
      rating: 4.5,
      pricePerDay: 1499,
    ),
    CarModel(
      id: '5',
      name: 'BMW 3 Series',
      imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800',
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      rating: 4.9,
      pricePerDay: 7999,
    ),
    CarModel(
      id: '6',
      name: 'Toyota Innova',
      imageUrl: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
      transmission: 'Automatic',
      fuelType: 'Diesel',
      seats: 7,
      rating: 4.7,
      pricePerDay: 3599,
    ),
    CarModel(
      id: '7',
      name: 'Kia Seltos',
      imageUrl: 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=800',
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      rating: 4.6,
      pricePerDay: 2799,
    ),
  ];

  /// "Why Choose Us" horizontal cards.
  static const List<FeatureItemModel> whyChooseUs = [
    FeatureItemModel(id: '1', icon: Icons.verified_outlined, title: 'Verified Cars'),
    FeatureItemModel(id: '2', icon: Icons.badge_outlined, title: 'Verified Owners'),
    FeatureItemModel(id: '3', icon: Icons.car_repair_outlined, title: 'Roadside Assistance'),
    FeatureItemModel(id: '4', icon: Icons.lock_outline, title: 'Secure Payments'),
    FeatureItemModel(id: '5', icon: Icons.flash_on_outlined, title: 'Instant Booking'),
    FeatureItemModel(id: '6', icon: Icons.headset_mic_outlined, title: '24×7 Support'),
  ];

  /// "Why Our Platform" benefit cards.
  static const List<FeatureItemModel> whyChoosePlatform = [
    FeatureItemModel(
      id: '1',
      icon: Icons.currency_rupee_outlined,
      title: 'Affordable Rentals',
      subtitle: 'Best prices, no hidden charges',
    ),
    FeatureItemModel(
      id: '2',
      icon: Icons.groups_outlined,
      title: 'Trusted Community',
      subtitle: 'Thousands of verified users',
    ),
    FeatureItemModel(
      id: '3',
      icon: Icons.directions_car_outlined,
      title: 'Wide Vehicle Collection',
      subtitle: 'From hatchbacks to luxury cars',
    ),
    FeatureItemModel(
      id: '4',
      icon: Icons.touch_app_outlined,
      title: 'Easy Booking',
      subtitle: 'Book a car in under 2 minutes',
    ),
    FeatureItemModel(
      id: '5',
      icon: Icons.receipt_long_outlined,
      title: 'Transparent Pricing',
      subtitle: 'What you see is what you pay',
    ),
    FeatureItemModel(
      id: '6',
      icon: Icons.support_agent_outlined,
      title: 'Quick Support',
      subtitle: 'We respond within minutes',
    ),
  ];
}