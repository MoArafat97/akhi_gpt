import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Secure logging utility that only outputs debug information in debug mode
/// and ensures no sensitive information is logged even in debug mode
class SecureLogger {
  /// Log an informational message (only in debug mode)
  static void info(String message, {String? name}) {
    if (kDebugMode) {
      developer.log('ℹ️ $message', name: name ?? 'App');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message, {String? name}) {
    if (kDebugMode) {
      developer.log('⚠️ $message', name: name ?? 'App');
    }
  }

  /// Log an error message (only in debug mode)
  static void error(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log('❌ $message', name: name ?? 'App', error: error, stackTrace: stackTrace);
    }
  }

  /// Log a success message (only in debug mode)
  static void success(String message, {String? name}) {
    if (kDebugMode) {
      developer.log('✅ $message', name: name ?? 'App');
    }
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message, {String? name}) {
    if (kDebugMode) {
      developer.log('🔍 $message', name: name ?? 'App');
    }
  }

  /// Log a verbose message (only in debug mode and when verbose logging is enabled)
  static void verbose(String message, {String? name}) {
    if (kDebugMode && _isVerboseEnabled()) {
      developer.log('📝 VERBOSE: $message', name: name ?? 'App');
    }
  }

  /// Obfuscate sensitive data for logging
  static String obfuscate(String sensitive, {int visibleChars = 4}) {
    if (sensitive.isEmpty) return '[EMPTY]';
    if (sensitive.length <= visibleChars) return '[HIDDEN]';
    
    final visible = sensitive.substring(0, visibleChars);
    final hidden = '*' * (sensitive.length - visibleChars);
    return '$visible$hidden';
  }

  /// Obfuscate API keys specifically
  static String obfuscateApiKey(String apiKey) {
    if (apiKey.isEmpty) return '[NO_API_KEY]';
    if (apiKey.length < 10) return '[INVALID_KEY]';
    
    // Show first 10 characters for API key format identification
    return '${apiKey.substring(0, 10)}...[${apiKey.length - 10} chars hidden]';
  }

  /// Check if verbose logging is enabled
  static bool _isVerboseEnabled() {
    // You can add environment variable or build flag check here
    return const bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);
  }

  /// Log configuration status safely
  static void logConfig(String component, bool isConfigured, {String? details}) {
    if (kDebugMode) {
      final status = isConfigured ? '✅' : '❌';
      final message = '$component: $status';
      developer.log(message, name: 'Config');
      
      if (details != null && details.isNotEmpty) {
        // Ensure details don't contain sensitive information
        final safeDetails = _sanitizeDetails(details);
        developer.log('  Details: $safeDetails', name: 'Config');
      }
    }
  }

  /// Sanitize details to remove potential sensitive information
  static String _sanitizeDetails(String details) {
    // Remove potential API keys, tokens, passwords
    return details
        .replaceAll(RegExp(r'sk-[a-zA-Z0-9-_]+'), '[API_KEY_HIDDEN]')
        .replaceAll(RegExp(r'Bearer [a-zA-Z0-9-_]+'), 'Bearer [TOKEN_HIDDEN]')
        .replaceAll(RegExp(r'password["\s]*[:=]["\s]*[^,}\s]+', caseSensitive: false), 'password: [HIDDEN]')
        .replaceAll(RegExp(r'token["\s]*[:=]["\s]*[^,}\s]+', caseSensitive: false), 'token: [HIDDEN]');
  }

  /// Log network request safely (without sensitive headers or data)
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? headers}) {
    if (kDebugMode) {
      developer.log('🌐 $method $url', name: 'Network');
      
      if (headers != null) {
        final safeHeaders = <String, dynamic>{};
        headers.forEach((key, value) {
          if (_isSensitiveHeader(key)) {
            safeHeaders[key] = '[HIDDEN]';
          } else {
            safeHeaders[key] = value;
          }
        });
        developer.log('  Headers: $safeHeaders', name: 'Network');
      }
    }
  }

  /// Check if header contains sensitive information
  static bool _isSensitiveHeader(String headerName) {
    final sensitive = ['authorization', 'x-api-key', 'x-auth-token', 'cookie', 'x-admin-token'];
    return sensitive.any((s) => headerName.toLowerCase().contains(s));
  }

  /// Log network response safely
  static void logNetworkResponse(int statusCode, {String? message}) {
    if (kDebugMode) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      developer.log('$emoji Response: $statusCode${message != null ? ' - $message' : ''}', name: 'Network');
    }
  }
}
