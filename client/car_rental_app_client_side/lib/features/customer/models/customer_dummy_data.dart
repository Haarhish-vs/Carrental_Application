import 'customer_car_model.dart';

abstract final class CustomerDummyData {
  static const categories = <Map<String, String>>[
    {'name': 'All', 'icon': 'directions_car'},
    {'name': 'SUV', 'icon': 'directions_car_filled'},
    {'name': 'Sedan', 'icon': 'minor_crash'},
    {'name': 'Electric', 'icon': 'electric_car'},
    {'name': 'Luxury', 'icon': 'workspace_premium'},
    {'name': 'Convertible', 'icon': 'style'},
  ];

  static const cars = <CustomerCarModel>[
    CustomerCarModel(
      id: 'c1',
      name: 'Mahindra Thar 4x4',
      brand: 'Mahindra',
      category: 'SUV',
      imageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf',
      pricePerDay: 3500,
      rating: 4.9,
      reviewCount: 142,
      transmission: 'Automatic',
      fuelType: 'Diesel',
      seats: 4,
      location: 'Bengaluru, KA',
      isFeatured: true,
      isPopular: true,
    ),
    CustomerCarModel(
      id: 'c2',
      name: 'Tata Nexon EV Max',
      brand: 'Tata',
      category: 'Electric',
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935',
      pricePerDay: 2800,
      rating: 4.8,
      reviewCount: 98,
      transmission: 'Automatic',
      fuelType: 'Electric',
      seats: 5,
      location: 'Mumbai, MH',
      isFeatured: true,
      isElectric: true,
    ),
    CustomerCarModel(
      id: 'c3',
      name: 'BMW 3 Series Gran Limousine',
      brand: 'BMW',
      category: 'Luxury',
      imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e',
      pricePerDay: 9500,
      rating: 4.95,
      reviewCount: 64,
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      location: 'Delhi NCR',
      isFeatured: true,
      isLuxury: true,
    ),
    CustomerCarModel(
      id: 'c4',
      name: 'Hyundai Creta SX(O)',
      brand: 'Hyundai',
      category: 'SUV',
      imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
      pricePerDay: 2400,
      rating: 4.7,
      reviewCount: 210,
      transmission: 'Manual',
      fuelType: 'Petrol',
      seats: 5,
      location: 'Hyderabad, TS',
      isPopular: true,
    ),
    CustomerCarModel(
      id: 'c5',
      name: 'Mercedes-Benz C-Class',
      brand: 'Mercedes',
      category: 'Luxury',
      imageUrl: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738',
      pricePerDay: 12500,
      rating: 4.98,
      reviewCount: 52,
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      location: 'Bengaluru, KA',
      isLuxury: true,
    ),
    CustomerCarModel(
      id: 'c6',
      name: 'Honda City ZX',
      brand: 'Honda',
      category: 'Sedan',
      imageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2',
      pricePerDay: 2100,
      rating: 4.6,
      reviewCount: 185,
      transmission: 'Automatic',
      fuelType: 'Petrol',
      seats: 5,
      location: 'Pune, MH',
    ),
  ];

  static const destinations = <Map<String, String>>[
    {'city': 'Bengaluru', 'tag': 'Garden City', 'trips': '1,240+ rentals'},
    {'city': 'Goa', 'tag': 'Beach & Drive', 'trips': '2,890+ rentals'},
    {'city': 'Mumbai', 'tag': 'Coastal Express', 'trips': '1,850+ rentals'},
    {'city': 'Delhi NCR', 'tag': 'Heritage & Highways', 'trips': '2,100+ rentals'},
  ];

  static const whyUs = <Map<String, String>>[
    {'title': 'Zero Security Deposit', 'desc': 'Rent seamlessly with verified digital KYC and transparent pricing.'},
    {'title': 'Free Doorstep Delivery', 'desc': 'Get your clean, disinfected car delivered straight to your home or airport.'},
    {'title': '24x7 Roadside Assistance', 'desc': 'Drive worry-free with instant pan-India emergency breakdown support.'},
    {'title': 'Unlimited Kilometers', 'desc': 'Explore without limits. Enjoy zero per-km charges on selected fleets.'},
  ];

  static const howItWorks = <Map<String, String>>[
    {'step': '01', 'title': 'Search & Select', 'desc': 'Pick your preferred car model, dates, and pickup city.'},
    {'step': '02', 'title': 'Verify & Pay', 'desc': 'Upload driving license & complete secure instant payment.'},
    {'step': '03', 'title': 'Drive Away', 'desc': 'Collect the key at doorstep or pickup hub & enjoy the journey.'},
  ];

  static const faqs = <Map<String, String>>[
    {'q': 'What documents are required to rent a car?', 'a': 'You need a valid Indian Driving License (DL) and an Aadhaar/Passport for KYC verification.'},
    {'q': 'Is fuel included in the rental price?', 'a': 'Cars are provided with a minimum fuel level. You return the car with the same fuel level.'},
    {'q': 'What is the speed limit policy?', 'a': 'All vehicles adhere to government speed limits (typically 120 km/h on expressways).'},
  ];
}
