import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class LocationSearchSheet extends StatefulWidget {
  final String title;

  const LocationSearchSheet({
    super.key,
    required this.title,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final List<String> _allLocations = [
    "Los Angeles International Airport (LAX) - Terminal 1",
    "San Francisco International Airport (SFO) - Rental Car Center",
    "Downtown Rental Hub - 450 Broadway Ave, LA",
    "Beverly Hills Pick-up Point - Wilshire Blvd",
    "Santa Monica Beach Station - Ocean Ave",
    "Hollywood Walk of Fame Service Center",
    "Union Station Depot - Transit Plaza, LA",
    "Pasadena Collection Center - Colorado Blvd",
  ];

  List<String> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLocations = _allLocations;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = _allLocations
          .where((loc) => loc.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const Gap(AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(AppSpacing.md),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.slate700),
                ),
              ],
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Enter airport, city or station name...",
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // List View
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_outlined, size: 48, color: AppColors.slate300),
                        const Gap(AppSpacing.sm),
                        Text("No locations found", style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate400)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _filteredLocations.length,
                    separatorBuilder: (context, index) => Divider(color: AppColors.slate100, height: 1),
                    itemBuilder: (context, index) {
                      final loc = _filteredLocations[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.slate100,
                          radius: 18,
                          child: Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.primary),
                        ),
                        title: Text(
                          loc,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, loc);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
