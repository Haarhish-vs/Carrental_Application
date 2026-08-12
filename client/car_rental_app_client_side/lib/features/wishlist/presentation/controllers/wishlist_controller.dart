import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../home/models/car_model.dart';
import '../../data/services/wishlist_api_service.dart';

class WishlistController extends ChangeNotifier {
  WishlistController._internal() {
    _init();
  }

  static final WishlistController instance = WishlistController._internal();
  factory WishlistController() => instance;

  final WishlistApiService _apiService = WishlistApiService();

  final Set<String> _wishlistIds = <String>{};
  final List<CarModel> _wishlistCars = <CarModel>[];
  bool _isLoading = false;
  bool _hasLoadedCars = false;
  String? _errorMessage;

  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  List<CarModel> get wishlistCars => List.unmodifiable(_wishlistCars);
  bool get isLoading => _isLoading;
  bool get hasLoadedCars => _hasLoadedCars;
  String? get errorMessage => _errorMessage;
  int get count => _wishlistIds.length;

  void _init() {
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    if (AuthService.isAuthenticated) {
      loadWishlistIds();
      fetchWishlistCars();
    }
  }

  void _onAuthChanged() {
    if (AuthService.isAuthenticated) {
      loadWishlistIds();
      fetchWishlistCars(forceRefresh: true);
    } else {
      _wishlistIds.clear();
      _wishlistCars.clear();
      _hasLoadedCars = false;
      _errorMessage = null;
      _safeNotifyListeners();
    }
  }

  bool isWishlisted(String vehicleId) {
    if (vehicleId.isEmpty) return false;
    return _wishlistIds.contains(vehicleId);
  }

  /// Initial fetch of IDs for instant UI heart activation
  Future<void> loadWishlistIds() async {
    if (!AuthService.isAuthenticated) return;
    try {
      final ids = await _apiService.getWishlistIds();
      _wishlistIds.clear();
      _wishlistIds.addAll(ids);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('⚠️ [WishlistController] Error loading wishlist IDs: $e');
    }
  }

  /// Fetch full list of wishlisted cars
  Future<List<CarModel>> fetchWishlistCars({bool forceRefresh = false}) async {
    if (!AuthService.isAuthenticated) {
      _wishlistCars.clear();
      _wishlistIds.clear();
      _hasLoadedCars = false;
      _errorMessage = null;
      _safeNotifyListeners();
      return [];
    }

    if (_isLoading) {
      return _wishlistCars;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final cars = await _apiService.getWishlist();
      _wishlistCars.clear();
      _wishlistCars.addAll(cars);
      _wishlistIds.clear();
      for (final car in cars) {
        _wishlistIds.add(car.id);
      }
      _isLoading = false;
      _hasLoadedCars = true;
      _safeNotifyListeners();
      return _wishlistCars;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotifyListeners();
      rethrow;
    }
  }

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  /// Toggles wishlist state with optimistic UI update and auth guard
  Future<bool> toggleWishlist(
    String vehicleId, {
    required BuildContext context,
    String? carName,
    CarModel? carModel,
  }) async {
    if (vehicleId.isEmpty) return false;

    // Prevent owner from wishlisting their own vehicle
    final currentUserId = AuthService.currentUser?['id']?.toString() ??
        AuthService.currentUser?['userId']?.toString();
    if (currentUserId != null &&
        carModel != null &&
        carModel.ownerId == currentUserId &&
        !_wishlistIds.contains(vehicleId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You cannot add your own vehicle to wishlist',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF103B66),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    // 1. Auth Guard: prompt login if guest
    if (!AuthService.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Save to Wishlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            'Please log in or register to save your favorite cars and access them anytime.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log In / Register'),
            ),
          ],
        ),
      );

      if (shouldLogin != true || !context.mounted) return false;

      final authSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

      if (authSuccess != true || !context.mounted) return false;
      await loadWishlistIds();
      await fetchWishlistCars(forceRefresh: true);
    }

    // 2. Optimistic UI update
    final wasWishlisted = _wishlistIds.contains(vehicleId);
    CarModel? removedCar;
    int? removedCarIndex;

    if (wasWishlisted) {
      _wishlistIds.remove(vehicleId);
      final index = _wishlistCars.indexWhere((c) => c.id == vehicleId);
      if (index != -1) {
        removedCar = _wishlistCars[index];
        removedCarIndex = index;
        _wishlistCars.removeAt(index);
      }
    } else {
      _wishlistIds.add(vehicleId);
      if (carModel != null && !_wishlistCars.any((c) => c.id == vehicleId)) {
        _wishlistCars.insert(0, carModel);
      }
    }
    _safeNotifyListeners();

    // 3. Feedback snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                wasWishlisted ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                color: wasWishlisted ? Colors.white70 : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasWishlisted
                      ? '${carName ?? 'Vehicle'} removed from wishlist'
                      : '${carName ?? 'Vehicle'} added to wishlist',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    }

    // 4. Perform API call in background
    try {
      final isNowWishlisted = await _apiService.toggleWishlist(vehicleId);
      if (isNowWishlisted) {
        _wishlistIds.add(vehicleId);
        if (carModel != null && !_wishlistCars.any((c) => c.id == vehicleId)) {
          _wishlistCars.insert(0, carModel);
        } else if (carModel == null) {
          fetchWishlistCars(forceRefresh: true);
        }
      } else {
        _wishlistIds.remove(vehicleId);
        _wishlistCars.removeWhere((c) => c.id == vehicleId);
      }
      _safeNotifyListeners();
      return isNowWishlisted;
    } catch (e) {
      // Revert state on network/server error
      if (wasWishlisted) {
        _wishlistIds.add(vehicleId);
        if (removedCar != null && removedCarIndex != null) {
          final insertIdx = (removedCarIndex <= _wishlistCars.length) ? removedCarIndex : _wishlistCars.length;
          _wishlistCars.insert(insertIdx, removedCar);
        }
      } else {
        _wishlistIds.remove(vehicleId);
        _wishlistCars.removeWhere((c) => c.id == vehicleId);
      }
      _safeNotifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return wasWishlisted;
    }
  }
}

