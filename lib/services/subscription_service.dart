import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
        return 500;
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
  SubscriptionTier _currentTier = SubscriptionTier.free;
  CustomerInfo? _customerInfo;

  /// Get current subscription tier
  SubscriptionTier get currentTier {
    // Debug bypass for testing
    if (DebugConfig.skipPremium) {
      return SubscriptionTier.premium;
    }
    return _currentTier;
  }

  /// Check if user has premium subscription
  bool get isPremium {
    // Debug bypass for testing
    if (DebugConfig.skipPremium) {
      developer.log('Debug mode: Bypassing premium check', name: 'SubscriptionService');
      return true;
    }
    return _currentTier == SubscriptionTier.premium;
  }

  /// Get customer info
  CustomerInfo? get customerInfo => _customerInfo;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing RevenueCat SDK...', name: 'SubscriptionService');

      // Check if running in secure environment
      if (!SecureConfigService.instance.isSecureEnvironment()) {
        developer.log('Insecure environment detected, running in free mode', name: 'SubscriptionService');
        _currentTier = SubscriptionTier.free;
        _isInitialized = true;
        return;
      }

      // Get API key using secure configuration service
      final apiKey = SecureConfigService.instance.getRevenueCatApiKey();

      if (apiKey == null) {
        developer.log('RevenueCat API key not configured or invalid, running in free mode', name: 'SubscriptionService');
        _currentTier = SubscriptionTier.free;
        _isInitialized = true;
        return;
      }

      // Configure RevenueCat
      final configuration = PurchasesConfiguration(apiKey);
      // Note: enableDebugLogs is not available in this version of purchases_flutter

      await Purchases.configure(configuration);

      // Set up listener for customer info updates
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      // Load initial subscription status
      await _loadSubscriptionStatus();

      _isInitialized = true;
      developer.log('RevenueCat SDK initialized successfully', name: 'SubscriptionService');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize RevenueCat: $e', name: 'SubscriptionService', stackTrace: stackTrace);
      // Fall back to free tier on initialization failure
      _currentTier = SubscriptionTier.free;
      _isInitialized = true;
    }
  }

  /// Load subscription status from RevenueCat and cache
  Future<void> _loadSubscriptionStatus() async {
    try {
      // Check cached status first
      final prefs = await SharedPreferences.getInstance();
      final cachedTier = prefs.getString(_subscriptionTierKey);
      final lastCheck = prefs.getInt(_lastSubscriptionCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Use cached status if it's less than 1 hour old
      if (cachedTier != null && (now - lastCheck) < 3600000) {
        _currentTier = cachedTier == 'premium' ? SubscriptionTier.premium : SubscriptionTier.free;
        developer.log('Using cached subscription status: $_currentTier', name: 'SubscriptionService');
        return;
      }

      // Fetch fresh status from RevenueCat
      _customerInfo = await Purchases.getCustomerInfo();
      final entitlementId = SecureConfigService.instance.getEntitlementId();
      final hasEntitlement = _customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;
      
      _currentTier = hasEntitlement ? SubscriptionTier.premium : SubscriptionTier.free;

      // Cache the result
      await prefs.setString(_subscriptionTierKey, _currentTier == SubscriptionTier.premium ? 'premium' : 'free');
      await prefs.setInt(_lastSubscriptionCheckKey, now);

      developer.log('Subscription status loaded: $_currentTier', name: 'SubscriptionService');
    } catch (e) {
      developer.log('Failed to load subscription status: $e', name: 'SubscriptionService');
      // Keep current tier on error
    }
  }

  /// Handle customer info updates from RevenueCat
  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    final entitlementId = SecureConfigService.instance.getEntitlementId();
    final hasEntitlement = customerInfo.entitlements.active.containsKey(entitlementId);
    final newTier = hasEntitlement ? SubscriptionTier.premium : SubscriptionTier.free;
    
    if (newTier != _currentTier) {
      _currentTier = newTier;
      developer.log('Subscription tier updated: $_currentTier', name: 'SubscriptionService');
      
      // Cache the new status
      _cacheSubscriptionStatus();
    }
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

  /// Get available offerings from RevenueCat
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      developer.log('Failed to get offerings: $e', name: 'SubscriptionService');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      developer.log('Attempting to purchase package: ${package.identifier}', name: 'SubscriptionService');
      
      final purchaserInfo = await Purchases.purchasePackage(package);
      final entitlementId = SecureConfigService.instance.getEntitlementId();
      final hasEntitlement = purchaserInfo.entitlements.active.containsKey(entitlementId);
      
      if (hasEntitlement) {
        _currentTier = SubscriptionTier.premium;
        _customerInfo = purchaserInfo;
        await _cacheSubscriptionStatus();
        developer.log('Purchase successful, upgraded to premium', name: 'SubscriptionService');
        return true;
      } else {
        developer.log('Purchase completed but entitlement not active', name: 'SubscriptionService');
        return false;
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        developer.log('Purchase cancelled by user', name: 'SubscriptionService');
      } else {
        developer.log('Purchase failed: ${e.message}', name: 'SubscriptionService');
      }
      return false;
    } catch (e) {
      developer.log('Purchase failed with unexpected error: $e', name: 'SubscriptionService');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      developer.log('Attempting to restore purchases', name: 'SubscriptionService');
      
      final customerInfo = await Purchases.restorePurchases();
      final entitlementId = SecureConfigService.instance.getEntitlementId();
      final hasEntitlement = customerInfo.entitlements.active.containsKey(entitlementId);
      
      _currentTier = hasEntitlement ? SubscriptionTier.premium : SubscriptionTier.free;
      _customerInfo = customerInfo;
      await _cacheSubscriptionStatus();
      
      developer.log('Purchases restored, tier: $_currentTier', name: 'SubscriptionService');
      return hasEntitlement;
    } catch (e) {
      developer.log('Failed to restore purchases: $e', name: 'SubscriptionService');
      return false;
    }
  }

  /// Check if a feature is available for current subscription tier
  bool isFeatureAvailable(String feature) {
    // Debug bypass for testing
    if (DebugConfig.skipPremium) {
      return true; // All features available in debug mode
    }

    switch (feature) {
      case 'personality_styles':
        return _currentTier.hasPersonalityStyles;
      case 'unlimited_messages':
        return _currentTier == SubscriptionTier.premium;
      default:
        return true; // Default to available for unknown features
    }
  }

  /// Get daily message limit for current tier
  int get dailyMessageLimit {
    // Debug bypass for testing - unlimited messages
    if (DebugConfig.skipPremium) {
      return 999999; // Effectively unlimited for testing
    }
    return _currentTier.dailyMessageLimit;
  }

  /// Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    await _loadSubscriptionStatus();
  }

  /// Dispose resources
  void dispose() {
    // RevenueCat doesn't require explicit disposal
  }
}
