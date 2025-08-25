import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing app settings including developer mode
class SettingsService {
  static const String _developerModeKey = 'developer_mode_enabled';
  
  /// Check if developer mode is enabled
  /// Automatically returns false in release builds
  static Future<bool> isDeveloperModeEnabled() async {
    // Always disable in release builds
    if (kReleaseMode) {
      return false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_developerModeKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Set developer mode state
  /// Only works in debug/profile builds
  static Future<void> setDeveloperMode(bool enabled) async {
    // Prevent enabling in release builds
    if (kReleaseMode) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_developerModeKey, enabled);
    } catch (e) {
      // Silently fail - developer mode is not critical
    }
  }
  
  /// Toggle developer mode state
  /// Returns the new state
  static Future<bool> toggleDeveloperMode() async {
    final currentState = await isDeveloperModeEnabled();
    final newState = !currentState;
    await setDeveloperMode(newState);
    return newState;
  }
  
  /// Check if a developer route should be accessible
  static Future<bool> canAccessDeveloperRoute(String routeName) async {
    final developerRoutes = ['/diagnostics', '/admin', '/onboard1', '/onboard2', '/onboard3',
                           '/onboard4', '/onboard5', '/onboard6', '/onboard7a',
                           '/onboard7b', '/onboard7c', '/onboard8', '/onboard9',
                           '/onboard10', '/onboard12'];

    if (!developerRoutes.contains(routeName)) {
      return true; // Not a developer route, allow access
    }

    return await isDeveloperModeEnabled();
  }
}
