import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_service.dart';
import '../config/debug_config.dart';

/// Service for tracking daily message usage and enforcing limits
class MessageCounterService {
  static const String _messageCountKey = 'daily_message_count';
  static const String _lastResetDateKey = 'last_reset_date';
  
  static MessageCounterService? _instance;
  static MessageCounterService get instance => _instance ??= MessageCounterService._();
  
  MessageCounterService._();

  int _currentCount = 0;
  DateTime? _lastResetDate;
  bool _isInitialized = false;

  /// Get current message count for today
  int get currentCount => _currentCount;

  /// Get remaining messages for today
  int get remainingMessages {
    final limit = SubscriptionService.instance.dailyMessageLimit;
    return (limit - _currentCount).clamp(0, limit);
  }

  /// Check if user has reached daily limit
  bool get hasReachedLimit {
    // Never reached limit (RevenueCat removed, unlimited messages)
    return false;
  }

  /// Get daily message limit based on subscription tier
  int get dailyLimit => SubscriptionService.instance.dailyMessageLimit;

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage {
    final limit = SubscriptionService.instance.dailyMessageLimit;
    if (limit == 0) return 0.0;
    return (_currentCount / limit).clamp(0.0, 1.0);
  }

  /// Initialize the message counter service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing MessageCounterService...', name: 'MessageCounterService');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load current count and last reset date
      _currentCount = prefs.getInt(_messageCountKey) ?? 0;
      final lastResetTimestamp = prefs.getInt(_lastResetDateKey);
      _lastResetDate = lastResetTimestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp)
          : null;

      // Check if we need to reset the counter (new day)
      await _checkAndResetIfNewDay();

      _isInitialized = true;
      developer.log('MessageCounterService initialized. Current count: $_currentCount', name: 'MessageCounterService');
    } catch (e) {
      developer.log('Failed to initialize MessageCounterService: $e', name: 'MessageCounterService');
      _currentCount = 0;
      _isInitialized = true;
    }
  }

  /// Check if it's a new day and reset counter if needed
  Future<void> _checkAndResetIfNewDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      await _resetDailyCounter();
    }
  }

  /// Reset the daily message counter
  Future<void> _resetDailyCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      _currentCount = 0;
      _lastResetDate = today;
      
      await prefs.setInt(_messageCountKey, _currentCount);
      await prefs.setInt(_lastResetDateKey, today.millisecondsSinceEpoch);
      
      developer.log('Daily message counter reset for new day', name: 'MessageCounterService');
    } catch (e) {
      developer.log('Failed to reset daily counter: $e', name: 'MessageCounterService');
    }
  }

  /// Increment message count and save to storage
  Future<bool> incrementMessageCount() async {
    // Always allow message increment (RevenueCat removed, unlimited messages)
    return true;
  }

  /// Check if user can send a message (hasn't reached limit)
  Future<bool> canSendMessage() async {
    // Always allow message sending (RevenueCat removed, unlimited messages)
    return true;
  }

  /// Get time until next reset (midnight)
  Duration getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Get formatted time until reset
  String getFormattedTimeUntilReset() {
    final duration = getTimeUntilReset();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Force reset counter (for testing or admin purposes)
  Future<void> forceReset() async {
    await _resetDailyCounter();
  }

  /// Get usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'currentCount': _currentCount,
      'dailyLimit': dailyLimit,
      'remainingMessages': remainingMessages,
      'usagePercentage': usagePercentage,
      'hasReachedLimit': hasReachedLimit,
      'timeUntilReset': getFormattedTimeUntilReset(),
      'subscriptionTier': SubscriptionService.instance.currentTier.displayName,
    };
  }

  /// Get warning level based on usage
  MessageUsageWarningLevel getWarningLevel() {
    final percentage = usagePercentage;
    
    if (percentage >= 1.0) {
      return MessageUsageWarningLevel.limitReached;
    } else if (percentage >= 0.9) {
      return MessageUsageWarningLevel.critical;
    } else if (percentage >= 0.75) {
      return MessageUsageWarningLevel.warning;
    } else {
      return MessageUsageWarningLevel.normal;
    }
  }

  /// Check if user should see upgrade prompt
  bool shouldShowUpgradePrompt() {
    // Show upgrade prompt when user reaches 90% of free tier limit
    return SubscriptionService.instance.currentTier == SubscriptionTier.free &&
           usagePercentage >= 0.9;
  }

  /// Reset counter for testing purposes
  Future<void> resetForTesting() async {
    await _resetDailyCounter();
  }
}

/// Warning levels for message usage
enum MessageUsageWarningLevel {
  normal,
  warning,
  critical,
  limitReached;

  /// Get display message for the warning level
  String get message {
    switch (this) {
      case MessageUsageWarningLevel.normal:
        return '';
      case MessageUsageWarningLevel.warning:
        return 'You\'re approaching your daily message limit';
      case MessageUsageWarningLevel.critical:
        return 'You have very few messages left today';
      case MessageUsageWarningLevel.limitReached:
        return 'You\'ve reached your daily message limit';
    }
  }

  /// Get color for the warning level
  String get colorHex {
    switch (this) {
      case MessageUsageWarningLevel.normal:
        return '#4CAF50'; // Green
      case MessageUsageWarningLevel.warning:
        return '#FF9800'; // Orange
      case MessageUsageWarningLevel.critical:
        return '#F44336'; // Red
      case MessageUsageWarningLevel.limitReached:
        return '#9E9E9E'; // Grey
    }
  }
}
