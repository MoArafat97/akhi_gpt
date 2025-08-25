import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'secure_config_service.dart';
import '../config/debug_config.dart';

/// Subscription tiers available in the app
enum SubscriptionTier {
  free,
  premium;

  /// Get display name for the subscription tier
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  /// Get daily message limit for the tier
  int get dailyMessageLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 75;
      case SubscriptionTier.premium:
        return 1500;
    }
  }

  /// Check if personality styles are available for this tier
  bool get hasPersonalityStyles {
    switch (this) {
      case SubscriptionTier.free:
        return false; // Only Simple Modern English
      case SubscriptionTier.premium:
        return true; // All personality styles
    }
  }
}

/// Service for managing RevenueCat subscriptions
class SubscriptionService {
  static const String _subscriptionTierKey = 'subscription_tier';
  static const String _lastSubscriptionCheckKey = 'last_subscription_check';
  
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  
  SubscriptionService._();

  bool _isInitialized = false;
  SubscriptionTier _currentTier = SubscriptionTier.premium;

  /// Get current subscription tier
  SubscriptionTier get currentTier {
    // Always return premium (RevenueCat removed)
    return SubscriptionTier.premium;
  }

  /// Check if user has premium subscription
  bool get isPremium {
    // Always return true (RevenueCat removed)
    return true;
  }

  /// Get customer info (RevenueCat removed)
  dynamic get customerInfo => null;

  /// Initialize subscription service (RevenueCat removed)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set premium tier (RevenueCat removed)
    _currentTier = SubscriptionTier.premium;
    _isInitialized = true;
    developer.log('Subscription service initialized with premium tier (RevenueCat removed)', name: 'SubscriptionService');
  }

  /// Load subscription status (RevenueCat removed)
  Future<void> _loadSubscriptionStatus() async {
    _currentTier = SubscriptionTier.premium;
    developer.log('Subscription status set to premium (RevenueCat removed)', name: 'SubscriptionService');
  }

  /// Handle customer info updates (RevenueCat removed)
  void _onCustomerInfoUpdate(dynamic customerInfo) {
    // No-op: RevenueCat removed
  }

  /// Cache subscription status to SharedPreferences
  Future<void> _cacheSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionTierKey, _currentTier == SubscriptionTier.premium ? 'premium' : 'free');
      await prefs.setInt(_lastSubscriptionCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      developer.log('Failed to cache subscription status: $e', name: 'SubscriptionService');
    }
  }

  /// Get available offerings (RevenueCat removed)
  Future<dynamic> getOfferings() async {
    return null; // RevenueCat removed
  }

  /// Purchase a package (RevenueCat removed)
  Future<bool> purchasePackage(dynamic package) async {
    return true; // Always successful (RevenueCat removed)
  }

  /// Restore purchases (RevenueCat removed)
  Future<bool> restorePurchases() async {
    return true; // Always successful (RevenueCat removed)
  }

  /// Check if a feature is available for current subscription tier
  bool isFeatureAvailable(String feature) {
    // All features available (RevenueCat removed)
    return true;
  }

  /// Get daily message limit for current tier
  int get dailyMessageLimit {
    // Unlimited messages (RevenueCat removed)
    return 999999; // Effectively unlimited
  }

  /// Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    await _loadSubscriptionStatus();
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose (RevenueCat removed)
  }
}
