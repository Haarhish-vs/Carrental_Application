import 'package:flutter/material.dart';

import 'widgets/booking_performance_section.dart';
import 'widgets/car_analytics_section.dart';
import 'widgets/common/owner_spacing.dart';
import 'widgets/customer_analytics_section.dart';
import 'widgets/earnings_analytics_section.dart';
import 'widgets/financial_analytics_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/owner_top_bar.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/ratings_reviews_section.dart';
import 'widgets/simple_stat_sections.dart';
import 'widgets/welcome_card.dart';

/// Dashboard landing screen for car owners — full width, no artificial right margin capping.
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OwnerTopBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: OwnerSpacing.lg, vertical: OwnerSpacing.lg),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeCard(),
              SizedBox(height: OwnerSpacing.xl),

              QuickStatsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              BookingAnalyticsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              EarningsAnalyticsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              CarAnalyticsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              CustomerAnalyticsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              BookingPerformanceSection(),
              SizedBox(height: OwnerSpacing.xxl),

              FinancialAnalyticsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              RatingsReviewsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              PerformanceMetricsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              NotificationsSection(),
              SizedBox(height: OwnerSpacing.xxl),

              QuickActionsSection(),
              SizedBox(height: OwnerSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
