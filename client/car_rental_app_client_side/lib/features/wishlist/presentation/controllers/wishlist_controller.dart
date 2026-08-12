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
  bool _isLoading = false;

  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  bool get isLoading => _isLoading;
  int get count => _wishlistIds.length;

  void _init() {
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    if (AuthService.isAuthenticated) {
      loadWishlistIds();
    }
  }

  void _onAuthChanged() {
    if (AuthService.isAuthenticated) {
      loadWishlistIds();
    } else {
      _wishlistIds.clear();
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [WishlistController] Error loading wishlist IDs: $e');
    }
  }

  /// Fetch full list of wishlisted cars
  Future<List<CarModel>> fetchWishlistCars() async {
    if (!AuthService.isAuthenticated) return [];
    _isLoading = true;
    notifyListeners();
    try {
      final cars = await _apiService.getWishlist();
      _wishlistIds.clear();
      for (final car in cars) {
        _wishlistIds.add(car.id);
      }
      _isLoading = false;
      notifyListeners();
      return cars;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Toggles wishlist state with optimistic UI update and auth guard
  Future<bool> toggleWishlist(
    String vehicleId, {
    required BuildContext context,
    String? carName,
  }) async {
    if (vehicleId.isEmpty) return false;

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
    }

    // 2. Optimistic UI update
    final wasWishlisted = _wishlistIds.contains(vehicleId);
    if (wasWishlisted) {
      _wishlistIds.remove(vehicleId);
    } else {
      _wishlistIds.add(vehicleId);
    }
    notifyListeners();

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
      } else {
        _wishlistIds.remove(vehicleId);
      }
      notifyListeners();
      return isNowWishlisted;
    } catch (e) {
      // Revert state on network/server error
      if (wasWishlisted) {
        _wishlistIds.add(vehicleId);
      } else {
        _wishlistIds.remove(vehicleId);
      }
      notifyListeners();

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
