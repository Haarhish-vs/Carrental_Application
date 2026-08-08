import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/location_model.dart';
import '../../repositories/driver_repository.dart';

class LocationSearchSheet extends StatefulWidget {
  final String title;

  const LocationSearchSheet({super.key, required this.title});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final List<LocationModel> _allLocations = LocationModel.mockLocations;
  List<LocationModel> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();
  LocationModel? _tempSelectedLocation;

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
          .where(
            (loc) =>
                loc.name.toLowerCase().contains(query) ||
                loc.address.toLowerCase().contains(query),
          )
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
      height: MediaQuery.of(context).size.height * 0.8,
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
                Text(
                  _tempSelectedLocation != null
                      ? "Confirm Selection"
                      : widget.title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tempSelectedLocation != null
                  ? _buildConfirmationView()
                  : _buildSearchView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Column(
      key: const ValueKey("SearchView"),
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter airport, city or hub name...",
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.slate500,
              ),
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
                      const Icon(
                        Icons.location_off_outlined,
                        size: 48,
                        color: AppColors.slate300,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        "No locations found",
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: _filteredLocations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.slate100, height: 1),
                  itemBuilder: (context, index) {
                    final loc = _filteredLocations[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.blueSurface,
                        radius: 18,
                        child: Icon(
                          Icons.pin_drop_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ),
                      title: Text(
                        loc.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      subtitle: Text(
                        loc.address,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _tempSelectedLocation = loc;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView() {
    final selected = _tempSelectedLocation!;
    final nearby = _allLocations.where((l) => l.id != selected.id).toList();

    return SingleChildScrollView(
      key: const ValueKey("ConfirmationView"),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blueSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBlue),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.accent,
                  size: 28,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        selected.address,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          // Nearby Pickup Points Title
          Text(
            "Nearby Pickup Points",
            style: AppTextStyles.subtitle2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.slate700,
            ),
          ),
          const Gap(AppSpacing.xs),

          ...nearby.map((hub) {
            final distance = MockDriverRepository.calculateDistance(
              selected.latitude,
              selected.longitude,
              hub.latitude,
              hub.longitude,
            );
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.slate50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.slate200),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.pin_drop_outlined,
                  color: AppColors.slate500,
                  size: 18,
                ),
                title: Text(
                  hub.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                trailing: Text(
                  "${distance.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _tempSelectedLocation = hub;
                  });
                },
              ),
            );
          }),

          const Gap(AppSpacing.xl),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedLocation = null;
                    });
                  },
                  child: const Text("Back to Search"),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Confirm Location"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
