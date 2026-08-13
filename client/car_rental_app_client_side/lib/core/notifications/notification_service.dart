import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:car_rental_app_client_side/core/config/api_config.dart';

/// Top-level background message handler required by FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM BACKGROUND] Received message: ${message.messageId}');
  debugPrint('🔔 [FCM BACKGROUND] Payload data: ${message.data}');
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get _backendBaseUrl => '${ApiConfig.baseUrl}/api';
  // In production / real device, backend URL is resolved dynamically from auth service or environment.

  String? _currentToken;
  String? _currentUserId;
  bool _isInitialized = false;

  /// Global navigator key to handle deep linking on notification tap.
  GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize Firebase & FCM Service
  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (_isInitialized) return;

    if (navKey != null) {
      navigatorKey = navKey;
    }

    debugPrint('[FCM] Initializing Firebase...');
    try {
      await Firebase.initializeApp();
      debugPrint('[FCM] Firebase initialized successfully');

      // Set top-level background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request Permission
      debugPrint('[FCM] Requesting notification permission...');
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Get FCM Token
      debugPrint('[FCM] Getting FCM token...');
      try {
        _currentToken = await _messaging.getToken();
        if (_currentToken != null && _currentToken!.isNotEmpty) {
          debugPrint('[FCM] FCM token generated successfully');
          debugPrint('[FCM] Token snippet: ${_currentToken!.substring(0, _currentToken!.length > 15 ? 15 : _currentToken!.length)}...');
        }
      } catch (e) {
        debugPrint('[FCM ERROR] Failed to get FCM token: $e');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed');
        _currentToken = newToken;
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          syncTokenWithBackend(_currentUserId!);
          debugPrint('[FCM] Updated token synchronized');
        }
      });

      // Handle Foreground Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM FOREGROUND] Notification received!');
        debugPrint('   Title: ${message.notification?.title}');
        debugPrint('   Body: ${message.notification?.body}');
        debugPrint('   Data: ${message.data}');

        if (navigatorKey?.currentContext != null && message.notification != null) {
          _showForegroundSnackbar(
            navigatorKey!.currentContext!,
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? '',
            message.data,
          );
        }
      });

      // Handle App Opened from Background Notification Tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👆 [FCM TAP] App opened from background notification');
        _handleNotificationTap(message.data);
      });

      // Handle App Opened from Terminated State
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('👆 [FCM TAP] App opened from terminated state notification');
        _handleNotificationTap(initialMessage.data);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[FCM ERROR] Initialization failed: $e');
    }
  }

  /// Synchronize FCM token with backend database
  Future<void> syncTokenWithBackend(String userId, {String? customBaseUrl}) async {
    _currentUserId = userId;

    if (_currentToken == null || _currentToken!.isEmpty) {
      try {
        _currentToken = await _messaging.getToken();
      } catch (e) {
        debugPrint('[FCM ERROR] Failed to fetch token for sync: $e');
        return;
      }
    }

    if (_currentToken == null || _currentToken!.isEmpty) {
      debugPrint('[FCM ERROR] Token registration failed: No token available');
      return;
    }

    debugPrint('[FCM] Registering token for user: $userId');

    try {
      final token = await _storage.read(key: 'jwt_token');
      final baseUrl = customBaseUrl ?? _backendBaseUrl;
      final uri = Uri.parse('$baseUrl/notifications/register-token');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': _currentToken,
          'deviceInfo': Platform.isAndroid ? 'Android Device' : (Platform.isIOS ? 'iOS Device' : 'Mobile'),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token synchronized with backend successfully');
      } else {
        debugPrint('[FCM ERROR] Backend request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FCM ERROR] Backend request failed: $e');
    }
  }

  /// Unregister FCM Token on Logout
  Future<void> removeTokenOnLogout(String userId, {String? customBaseUrl}) async {
    if (_currentToken == null || _currentToken!.isEmpty) return;

    debugPrint('[FCM] Disassociating token on logout for user: $userId');
    try {
      final token = await _storage.read(key: 'jwt_token');
      final baseUrl = customBaseUrl ?? _backendBaseUrl;
      final uri = Uri.parse('$baseUrl/notifications/unregister-token');

      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': _currentToken,
        }),
      ).timeout(const Duration(seconds: 5));

      debugPrint('[FCM] Token disassociated from user successfully');
    } catch (e) {
      debugPrint('[FCM ERROR] Failed to unregister token on logout: $e');
    } finally {
      _currentUserId = null;
    }
  }

  /// Show clean in-app banner for foreground notifications
  void _showForegroundSnackbar(
    BuildContext context,
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1E5AA8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.amber,
          onPressed: () {
            _handleNotificationTap(data);
          },
        ),
      ),
    );
  }

  /// Handle Notification Tap / Deep Linking
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();

    debugPrint('🔗 [FCM DEEP LINK] Processing notification tap -> Type: $type, BookingId: $bookingId');

    if (bookingId == null || bookingId.isEmpty) return;

    final context = navigatorKey?.currentContext;
    if (context == null) return;

    // Route based on notification event type
    switch (type) {
      case 'RESERVATION_CREATED':
        // Takes owner to booking management / requests
        debugPrint('🚀 Navigating to Owner Booking Requests for booking: $bookingId');
        break;
      case 'RESERVATION_ACCEPTED':
      case 'RESERVATION_DECLINED':
      case 'PAYMENT_CONFIRMED':
      case 'TRIP_REMINDER':
      case 'TRIP_COMPLETED':
        debugPrint('🚀 Navigating to Booking Detail for booking: $bookingId');
        break;
      default:
        debugPrint('🚀 Navigating default for notification data: $data');
        break;
    }
  }
}
