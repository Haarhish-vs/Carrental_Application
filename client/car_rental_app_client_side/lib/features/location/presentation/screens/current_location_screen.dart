import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/location_model.dart';
import '../providers/location_provider.dart';
import 'location_confirmation_screen.dart';

/// Screen 2/3A from the design: detects the device's current location,
/// then shows a confirm card ("Use This Location" / "Choose Another
/// Location"), or a dedicated full-screen state for permission/service
/// errors — never a snackbar/dialog for these two cases.
class CurrentLocationScreen extends StatefulWidget {
  const CurrentLocationScreen({super.key});

  @override
  State<CurrentLocationScreen> createState() => _CurrentLocationScreenState();
}

class _CurrentLocationScreenState extends State<CurrentLocationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detect());
  }

  Future<void> _detect() => context.read<LocationProvider>().requestCurrentLocation();

  Future<void> _handleUseThisLocation(LocationModel location) async {
    final provider = context.read<LocationProvider>();
    final confirmed = await Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LocationProvider>.value(
          value: provider,
          child: LocationConfirmationScreen(location: location),
        ),
      ),
    );
    if (confirmed != null && mounted) {
      Navigator.pop(context, confirmed);
    }
  }

  void _handleChooseAnother() {
    context.read<LocationProvider>().clearCurrentLocation();
    Navigator.pop(context);
  }

  Future<void> _handleGrantPermission() => _detect();

  Future<void> _handleOpenAppSettings() async {
    if (kIsWeb) {
      await _detect();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _handleOpenLocationSettings() async {
    if (kIsWeb) {
      await _detect();
    } else {
      await Geolocator.openLocationSettings();
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
        title: const Text('Current Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<LocationProvider>(
          builder: (context, provider, _) {
            if (provider.currentLocationStatus == LocationLoadStatus.loading ||
                provider.currentLocationStatus == LocationLoadStatus.idle) {
              return const _DetectingView();
            }

            if (provider.currentLocationStatus == LocationLoadStatus.error) {
              switch (provider.currentLocationErrorType) {
                case CurrentLocationErrorType.serviceDisabled:
                  return _ServicesDisabledView(onOpenSettings: _handleOpenLocationSettings);
                case CurrentLocationErrorType.permissionDenied:
                  return _PermissionRequiredView(onGrant: _handleGrantPermission);
                case CurrentLocationErrorType.permissionDeniedForever:
                  return _PermissionRequiredView(
                    onGrant: _handleOpenAppSettings,
                    buttonLabel: 'Open Settings',
                  );
                case CurrentLocationErrorType.reverseGeocodeFailed:
                case CurrentLocationErrorType.unknown:
                case CurrentLocationErrorType.none:
                  return _GenericErrorView(
                    message: provider.currentLocationError ?? 'Something went wrong.',
                    onRetry: _detect,
                  );
              }
            }

            final location = provider.currentLocation;
            if (location == null) return const _DetectingView();

            return _LocationFoundView(
              location: location,
              onUseThisLocation: () => _handleUseThisLocation(location),
              onChooseAnother: _handleChooseAnother,
            );
          },
        ),
      ),
    );
  }
}

class _DetectingView extends StatelessWidget {
  const _DetectingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingLocationIndicator(),
            const SizedBox(height: 32),
            const Text(
              'Detecting your location...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please allow location access to\nfind cars near you',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingLocationIndicator extends StatefulWidget {
  const _PulsingLocationIndicator();

  @override
  State<_PulsingLocationIndicator> createState() => _PulsingLocationIndicatorState();
}

class _PulsingLocationIndicatorState extends State<_PulsingLocationIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(0.0),
              _buildRing(0.33),
              _buildRing(0.66),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, spreadRadius: 2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing(double delay) {
    final progress = (_controller.value + delay) % 1.0;
    final size = 180 * (0.3 + progress * 0.7);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity * 0.4,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      ),
    );
  }
}

class _LocationFoundView extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onUseThisLocation;
  final VoidCallback onChooseAnother;

  const _LocationFoundView({
    required this.location,
    required this.onUseThisLocation,
    required this.onChooseAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PulsingLocationIndicator(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Current Location',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(location.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(location.address, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onUseThisLocation,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              label: const Text('Use This Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onChooseAnother,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Choose Another Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRequiredView extends StatelessWidget {
  final VoidCallback onGrant;
  final String buttonLabel;

  const _PermissionRequiredView({required this.onGrant, this.buttonLabel = 'Grant Permission'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.location_off_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Location permission required',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Allow location access so we can find cars near you.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onGrant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesDisabledView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _ServicesDisabledView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.location_disabled_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Turn on Location Services',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Enable location services on your device to detect cars near you.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onOpenSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GenericErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}