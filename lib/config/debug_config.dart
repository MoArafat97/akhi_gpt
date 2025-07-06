/// Debug configuration for testing and development
/// 
/// This file contains debug flags that can be controlled via dart-define
/// during build time for testing purposes.
class DebugConfig {
  /// Debug flag to bypass premium restrictions for testing
  /// Usage: flutter build appbundle --release --dart-define=DEBUG_SKIP_PREMIUM=true
  static const bool skipPremium = bool.fromEnvironment(
    'DEBUG_SKIP_PREMIUM', 
    defaultValue: false,
  );

  /// Check if any debug flags are enabled
  static bool get hasDebugFlags => skipPremium;

  /// Get debug status summary for logging
  static Map<String, bool> get debugStatus => {
    'skipPremium': skipPremium,
  };
}
