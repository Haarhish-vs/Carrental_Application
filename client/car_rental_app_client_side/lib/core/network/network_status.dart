import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_colors.dart';

/// Real-time Network Connectivity Monitor Service
class NetworkStatusService extends ChangeNotifier {
  NetworkStatusService._() {
    _init();
  }

  static final NetworkStatusService instance = NetworkStatusService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);

    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global Top-Level Widget that presents a subtle, app-themed bottom banner when offline
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  late final NetworkStatusService _networkService;
  bool _wasOffline = false;
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkStatusService.instance;
    _networkService.addListener(_onNetworkChange);
  }

  void _onNetworkChange() {
    if (!mounted) return;
    final isOnline = _networkService.isOnline;

    if (!isOnline) {
      setState(() {
        _wasOffline = true;
        _showRestoredBanner = false;
      });
      _restoredTimer?.cancel();
    } else if (_wasOffline) {
      setState(() {
        _wasOffline = false;
        _showRestoredBanner = true;
      });
      _restoredTimer?.cancel();
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRestoredBanner = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChange);
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = !_networkService.isOnline;

    return Stack(
      children: [
        widget.child,
        if (isOffline || _showRestoredBanner)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOffline ? const Color(0xFF1E293B) : AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOffline
                            ? 'No internet connection. Please check your connection.'
                            : 'Internet connection restored',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
