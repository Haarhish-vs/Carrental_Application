import 'package:flutter/material.dart';

import '../presentation/widgets/common/owner_colors.dart';
import '../presentation/widgets/common/owner_stat_card.dart';
import 'car_model.dart';
import 'owner_booking.dart';
import 'owner_notification.dart';
import 'review_model.dart';
import 'top_customer.dart';

/// Single source of truth for ALL static/dummy data used across the
/// Owner Dashboard sections. Frontend-only — replace this class with
/// Riverpod/repository-backed providers later; no widget code will
/// need to change since it all reads these same shapes.
abstract final class OwnerDummyData {
  static const ownerName = 'Alex Morgan';
  static const businessName = 'DriveEase Rentals';
  static const unreadNotifications = 4;

  // ---------------------------------------------------------------------
  // SECTION 1 — QUICK STATISTICS
  // ---------------------------------------------------------------------
  static const quickStats = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Total Earnings',
      value: '₹1,28,450',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
      trendPercent: 12.4,
      trend: OwnerTrend.up,
      trendLabel: 'vs last month',
    ),
    OwnerStatItem(
      title: 'Current Month Earnings',
      value: '₹4,280',
      icon: Icons.calendar_month_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
      trendPercent: 8.1,
      trend: OwnerTrend.up,
      trendLabel: 'vs last month',
    ),
    OwnerStatItem(
      title: 'Total Cars Listed',
      value: '32',
      icon: Icons.directions_car_filled_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
      trendPercent: 3.2,
      trend: OwnerTrend.up,
      trendLabel: 'new this month',
    ),
    OwnerStatItem(
      title: 'Available Cars',
      value: '19',
      icon: Icons.check_circle_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
      trend: OwnerTrend.flat,
      trendLabel: 'ready to rent',
    ),
    OwnerStatItem(
      title: 'Cars Currently Rented',
      value: '11',
      icon: Icons.vpn_key_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
      trend: OwnerTrend.flat,
      trendLabel: 'on the road',
    ),
    OwnerStatItem(
      title: 'Total Rentals',
      value: '1,248',
      icon: Icons.inventory_2_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
      trendPercent: 5.6,
      trend: OwnerTrend.up,
      trendLabel: 'all time',
    ),
    OwnerStatItem(
      title: 'Overall Rating',
      value: '4.8',
      icon: Icons.star_rounded,
      iconColor: OwnerColors.star,
      iconBg: Color(0xffFFF7E0),
      trendPercent: 0.2,
      trend: OwnerTrend.up,
      trendLabel: 'this quarter',
    ),
    OwnerStatItem(
      title: 'Customers Served',
      value: '864',
      icon: Icons.people_alt_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
      trendPercent: 6.9,
      trend: OwnerTrend.up,
      trendLabel: 'vs last month',
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 2 — BOOKING ANALYTICS
  // ---------------------------------------------------------------------
  static const bookingAnalytics = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Total Booking Requests',
      value: '186',
      icon: Icons.inbox_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Accepted',
      value: '152',
      icon: Icons.done_all_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Rejected',
      value: '14',
      icon: Icons.cancel_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Completed',
      value: '128',
      icon: Icons.outlined_flag_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Cancelled',
      value: '9',
      icon: Icons.block_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Ongoing',
      value: '11',
      icon: Icons.autorenew_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
    OwnerStatItem(
      title: 'Upcoming',
      value: '17',
      icon: Icons.upcoming_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Pending',
      value: '6',
      icon: Icons.hourglass_top_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 3 — EARNINGS ANALYTICS
  // ---------------------------------------------------------------------
  static const earningsAnalytics = <OwnerStatItem>[
    OwnerStatItem(
      title: "Today's Earnings",
      value: '₹845',
      icon: Icons.wb_sunny_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'This Week',
      value: '₹5,490',
      icon: Icons.date_range_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'This Month',
      value: '₹4,280',
      icon: Icons.calendar_month_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'This Year',
      value: '₹98,620',
      icon: Icons.calendar_today_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Lifetime Earnings',
      value: '₹1,28,450',
      icon: Icons.trending_up_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Average Earnings',
      value: '₹624',
      icon: Icons.receipt_long_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Highest Month',
      value: 'October',
      icon: Icons.arrow_circle_up_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Lowest Month',
      value: 'February',
      icon: Icons.arrow_circle_down_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
  ];

  /// 12 months of dummy monthly revenue (in hundreds ₹) for the line chart.
  static const monthlyRevenue = <double>[62, 48, 70, 75, 82, 91, 88, 95, 102, 118, 97, 105];
  static const monthLabels = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // ---------------------------------------------------------------------
  // SECTION 4 — CAR ANALYTICS
  // ---------------------------------------------------------------------
  static const carAnalytics = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Total Cars',
      value: '32',
      icon: Icons.directions_car_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Available Cars',
      value: '19',
      icon: Icons.check_circle_outline_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Active Cars',
      value: '11',
      icon: Icons.bolt_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Inactive Cars',
      value: '2',
      icon: Icons.do_not_disturb_on_rounded,
      iconColor: OwnerColors.textTertiary,
      iconBg: OwnerColors.surfaceMuted,
    ),
    OwnerStatItem(
      title: 'Under Maintenance',
      value: '3',
      icon: Icons.build_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
    OwnerStatItem(
      title: 'Most Rented Car',
      value: 'Tesla Model 3',
      icon: Icons.emoji_events_rounded,
      iconColor: OwnerColors.star,
      iconBg: Color(0xffFFF7E0),
    ),
    OwnerStatItem(
      title: 'Least Rented Car',
      value: 'Ford Focus',
      icon: Icons.trending_down_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Average Utilization',
      value: '68%',
      icon: Icons.speed_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Kilometers Driven',
      value: '4,52,120 km',
      icon: Icons.alt_route_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
  ];

  static const topCars = <CarModel>[
    CarModel(
      name: 'Tesla Model 3',
      plateNumber: 'KA 05 AB 1234',
      status: CarStatus.rented,
      totalRentals: 96,
      utilization: 0.88,
      rating: 4.9,
      kilometersDriven: 24500,
    ),
    CarModel(
      name: 'BMW X5',
      plateNumber: 'KA 05 CD 5678',
      status: CarStatus.available,
      totalRentals: 84,
      utilization: 0.79,
      rating: 4.8,
      kilometersDriven: 31200,
    ),
    CarModel(
      name: 'Toyota Camry',
      plateNumber: 'KA 05 EF 9012',
      status: CarStatus.available,
      totalRentals: 71,
      utilization: 0.72,
      rating: 4.7,
      kilometersDriven: 18900,
    ),
    CarModel(
      name: 'Honda Civic',
      plateNumber: 'KA 05 GH 3456',
      status: CarStatus.maintenance,
      totalRentals: 63,
      utilization: 0.61,
      rating: 4.5,
      kilometersDriven: 27600,
    ),
    CarModel(
      name: 'Jeep Wrangler',
      plateNumber: 'KA 05 IJ 7890',
      status: CarStatus.rented,
      totalRentals: 58,
      utilization: 0.55,
      rating: 4.9,
      kilometersDriven: 15400,
    ),
    CarModel(
      name: 'Ford Focus',
      plateNumber: 'KA 05 KL 2468',
      status: CarStatus.inactive,
      totalRentals: 21,
      utilization: 0.31,
      rating: 4.2,
      kilometersDriven: 9800,
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 5 — CUSTOMER ANALYTICS
  // ---------------------------------------------------------------------
  static const customerAnalytics = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Total Customers',
      value: '864',
      icon: Icons.people_alt_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Repeat Customers',
      value: '312',
      icon: Icons.repeat_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'New Customers',
      value: '58',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Average Rating',
      value: '4.8',
      icon: Icons.star_rounded,
      iconColor: OwnerColors.star,
      iconBg: Color(0xffFFF7E0),
    ),
    OwnerStatItem(
      title: 'Total Reviews',
      value: '742',
      icon: Icons.reviews_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Most Frequent Customer',
      value: 'Jordan Lee',
      icon: Icons.workspace_premium_rounded,
      iconColor: OwnerColors.star,
      iconBg: Color(0xffFFF7E0),
    ),
  ];

  static const topCustomers = <TopCustomer>[
    TopCustomer(name: 'Jordan Lee', totalBookings: 14, isRepeat: true, totalSpent: 6840),
    TopCustomer(name: 'Mia Rodriguez', totalBookings: 9, isRepeat: true, totalSpent: 4120),
    TopCustomer(name: 'Sam Carter', totalBookings: 2, isRepeat: false, totalSpent: 720),
  ];

  // ---------------------------------------------------------------------
  // SECTION 6 — BOOKING PERFORMANCE (reuses the existing OwnerBooking model)
  // ---------------------------------------------------------------------
  static const bookingPerformance = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Total Bookings',
      value: '186',
      icon: Icons.assignment_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Pending',
      value: '6',
      icon: Icons.hourglass_top_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
    OwnerStatItem(
      title: 'Approved',
      value: '152',
      icon: Icons.done_all_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Active',
      value: '11',
      icon: Icons.vpn_key_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Completed',
      value: '128',
      icon: Icons.outlined_flag_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Cancelled',
      value: '9',
      icon: Icons.block_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Avg. Rental Duration',
      value: '3.4 days',
      icon: Icons.access_time_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Booking Success Rate',
      value: '81.7%',
      icon: Icons.track_changes_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Cancellation Rate',
      value: '4.8%',
      icon: Icons.trending_down_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
  ];

  static final recentBookings = <OwnerBooking>[
    OwnerBooking(
      id: '#BK-2041',
      guestName: 'Jordan Lee',
      vehicleName: 'Tesla Model 3',
      startDate: DateTime(2026, 8, 12),
      endDate: DateTime(2026, 8, 15),
      total: 267,
    ),
    OwnerBooking(
      id: '#BK-2040',
      guestName: 'Mia Rodriguez',
      vehicleName: 'BMW X5',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 13),
      total: 360,
    ),
    OwnerBooking(
      id: '#BK-2039',
      guestName: 'Sam Carter',
      vehicleName: 'Toyota Camry',
      startDate: DateTime(2026, 8, 2),
      endDate: DateTime(2026, 8, 4),
      total: 210,
    ),
    OwnerBooking(
      id: '#BK-2038',
      guestName: 'Priya Nair',
      vehicleName: 'Jeep Wrangler',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 3),
      total: 298,
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 7 — FINANCIAL ANALYTICS
  // ---------------------------------------------------------------------
  static const financialAnalytics = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Revenue',
      value: '₹1,28,450',
      icon: Icons.account_balance_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Commission',
      value: '₹19,268',
      icon: Icons.percent_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
    OwnerStatItem(
      title: 'Net Income',
      value: '₹1,09,182',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Pending Payments',
      value: '₹2,430',
      icon: Icons.schedule_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
    OwnerStatItem(
      title: 'Received Payments',
      value: '₹1,26,020',
      icon: Icons.verified_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Refund Amount',
      value: '₹845',
      icon: Icons.undo_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Taxes',
      value: '₹6,422',
      icon: Icons.receipt_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
  ];

  /// Revenue distribution slices for the pie chart (label, value %).
  static const revenueDistribution = <MapEntry<String, double>>[
    MapEntry('Owner Net Income', 85),
    MapEntry('Platform Commission', 15),
  ];

  // ---------------------------------------------------------------------
  // SECTION 8 — RATINGS & REVIEWS
  // ---------------------------------------------------------------------
  static const overallRating = 4.8;
  static const totalReviewCount = 742;
  static const ratingBreakdown = <int, double>{5: 0.72, 4: 0.18, 3: 0.06, 2: 0.03, 1: 0.01};

  static final recentReviews = <ReviewModel>[
    ReviewModel(
      customerName: 'Jordan Lee',
      carName: 'Tesla Model 3',
      rating: 5,
      comment: 'Smooth booking process and the car was spotless. Will rent again!',
      date: DateTime(2026, 8, 2),
    ),
    ReviewModel(
      customerName: 'Mia Rodriguez',
      carName: 'BMW X5',
      rating: 4.5,
      comment: 'Great vehicle for a family trip, minor delay at pickup.',
      date: DateTime(2026, 7, 29),
    ),
    ReviewModel(
      customerName: 'Sam Carter',
      carName: 'Toyota Camry',
      rating: 4,
      comment: 'Comfortable ride, good mileage. Support team was responsive.',
      date: DateTime(2026, 7, 25),
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 9 — PERFORMANCE METRICS
  // ---------------------------------------------------------------------
  static const performanceMetrics = <OwnerStatItem>[
    OwnerStatItem(
      title: 'Occupancy Rate',
      value: '68%',
      icon: Icons.speed_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Booking Success Rate',
      value: '81.7%',
      icon: Icons.track_changes_rounded,
      iconColor: OwnerColors.success,
      iconBg: OwnerColors.successBg,
    ),
    OwnerStatItem(
      title: 'Cancellation Rate',
      value: '4.8%',
      icon: Icons.trending_down_rounded,
      iconColor: OwnerColors.danger,
      iconBg: OwnerColors.dangerBg,
    ),
    OwnerStatItem(
      title: 'Avg. Daily Earnings',
      value: '₹469',
      icon: Icons.wb_sunny_rounded,
      iconColor: OwnerColors.info,
      iconBg: OwnerColors.infoBg,
    ),
    OwnerStatItem(
      title: 'Avg. Monthly Earnings',
      value: '₹10,704',
      icon: Icons.calendar_month_rounded,
      iconColor: OwnerColors.primary,
      iconBg: OwnerColors.primaryLight,
    ),
    OwnerStatItem(
      title: 'Avg. Rental Price',
      value: '₹1,850/day',
      icon: Icons.sell_rounded,
      iconColor: OwnerColors.warning,
      iconBg: OwnerColors.warningBg,
    ),
  ];

  // ---------------------------------------------------------------------
  // SECTION 10 — NOTIFICATIONS
  // ---------------------------------------------------------------------
  static const notifications = <OwnerNotification>[
    OwnerNotification(
      type: OwnerNotificationType.bookingRequest,
      title: 'New Booking Request',
      subtitle: 'Mia Rodriguez requested BMW X5',
      timeAgo: '5 min ago',
      unread: true,
    ),
    OwnerNotification(
      type: OwnerNotificationType.paymentReceived,
      title: 'Payment Received',
      subtitle: '₹2,670 received for booking #BK-2041',
      timeAgo: '1 hr ago',
      unread: true,
    ),
    OwnerNotification(
      type: OwnerNotificationType.rentalEnding,
      title: 'Rental Ending Soon',
      subtitle: 'Tesla Model 3 rental ends in 3 hours',
      timeAgo: '2 hrs ago',
      unread: true,
    ),
    OwnerNotification(
      type: OwnerNotificationType.maintenance,
      title: 'Maintenance Reminder',
      subtitle: 'Honda Civic is due for service this week',
      timeAgo: '1 day ago',
      unread: true,
    ),
    OwnerNotification(
      type: OwnerNotificationType.lowRating,
      title: 'Low Rating Alert',
      subtitle: 'Ford Focus received a 2★ review',
      timeAgo: '2 days ago',
    ),
  ];
}
