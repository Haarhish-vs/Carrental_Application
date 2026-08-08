import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/location_model.dart';
import '../providers/location_provider.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/current_location_card.dart';
import '../widgets/recent_locations_list.dart';
import '../widgets/popular_locations_list.dart';
import '../widgets/location_tile.dart';
import 'current_location_screen.dart';
import 'map_location_screen.dart';

/// No longer creates its own provider — LocationFlow.start() creates it
/// once for the whole flow and hands it down via ChangeNotifierProvider.value.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocationProvider>();
      provider.loadRecentLocations();
      provider.loadPopularLocations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectLocation(LocationModel location) {
    context.read<LocationProvider>().saveRecentLocation(location);
    Navigator.pop(context, location);
  }

  Future<void> _handleCurrentLocationTap() async {
    final provider = context.read<LocationProvider>();
    final result = await Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LocationProvider>.value(
          value: provider,
          child: const CurrentLocationScreen(),
        ),
      ),
    );
    if (result != null && mounted) {
      _selectLocation(result);
    }
  }

  Future<void> _handleChooseOnMapTap() async {
    final provider = context.read<LocationProvider>();
    final picked = await Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LocationProvider>.value(
          value: provider,
          child: const MapLocationScreen(),
        ),
      ),
    );
    if (picked != null && mounted) {
      _selectLocation(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<LocationProvider>(
          builder: (context, provider, _) {
            final isSearching = _searchController.text.trim().isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: LocationSearchBar(
                    controller: _searchController,
                    isLoading: provider.searchStatus == LocationLoadStatus.loading,
                    onChanged: (value) {
                      setState(() {});
                      provider.searchLocations(value);
                    },
                    onClear: () {
                      _searchController.clear();
                      provider.clearSearch();
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: isSearching ? _buildSearchResults(provider) : _buildDefaultContent(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(LocationProvider provider) {
    if (provider.searchStatus == LocationLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (provider.searchStatus == LocationLoadStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.searchError ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text('No locations found',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final location = provider.searchResults[index];
        return LocationTile(location: location, onTap: () => _selectLocation(location));
      },
    );
  }

  Widget _buildDefaultContent(LocationProvider provider) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        CurrentLocationCard(onTap: _handleCurrentLocationTap),
        const SizedBox(height: 20),
        if (provider.recentStatus == LocationLoadStatus.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          RecentLocationsList(locations: provider.recentLocations, onLocationTap: _selectLocation),
        const SizedBox(height: 20),
        if (provider.popularStatus == LocationLoadStatus.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          PopularLocationsList(locations: provider.popularLocations, onLocationTap: _selectLocation),
        const SizedBox(height: 20),
        InkWell(
          onTap: _handleChooseOnMapTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Can't find your location?",
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text('Drop a pin on the map to select location',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}