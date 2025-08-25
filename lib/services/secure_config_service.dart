import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

/// Service for secure configuration management with key obfuscation and verification
class SecureConfigService {
  static const String _keyPrefix = 'rc_';
  static const String _checksumSuffix = '_checksum';
  
  static SecureConfigService? _instance;
  static SecureConfigService get instance => _instance ??= SecureConfigService._();
  
  SecureConfigService._();



  /// Check if the key is a placeholder value
  bool _isPlaceholderKey(String key) {
    final placeholders = [
      'your-android-api-key-here',
      'your-ios-api-key-here',
      'your-api-key-here',
      'placeholder',
      'test-key',
      'demo-key',
    ];
    
    return placeholders.any((placeholder) => 
        key.toLowerCase().contains(placeholder.toLowerCase()));
  }



  /// Verify key integrity using checksum (for release builds)
  bool _verifyKeyIntegrity(String key) {
    try {
      // Generate a simple checksum of the key
      final keyBytes = utf8.encode(key);
      final digest = sha256.convert(keyBytes);
      final checksum = digest.toString().substring(0, 8);
      
      // In a real implementation, you would store expected checksums
      // For now, we'll just verify the key hasn't been obviously tampered with
      
      // Check if key contains suspicious patterns
      final suspiciousPatterns = [
        'modified',
        'hacked',
        'cracked',
        'bypass',
        'fake',
      ];
      
      for (final pattern in suspiciousPatterns) {
        if (key.toLowerCase().contains(pattern)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      developer.log('Error verifying key integrity: $e', name: 'SecureConfig');
      return false;
    }
  }

  /// Obfuscate sensitive configuration for logging
  String obfuscateKey(String key) {
    if (key.length <= 8) {
      return '*' * key.length;
    }
    
    final start = key.substring(0, 4);
    final end = key.substring(key.length - 4);
    final middle = '*' * (key.length - 8);
    
    return '$start$middle$end';
  }

  /// Validate all configuration on app startup
  Map<String, bool> validateConfiguration() {
    final results = <String, bool>{};

    // OpenRouter configuration is now user-dependent, cannot validate synchronously
    results['openrouter_configured'] = false; // Will be checked async when user provides API key

    // RevenueCat removed - no longer validating
    results['revenuecat_configured'] = false;
    results['entitlement_configured'] = false;

    return results;
  }

  /// Generate a secure random string for testing
  String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Check if running in a secure environment
  bool isSecureEnvironment() {
    // In debug mode, always allow
    if (kDebugMode) return true;
    
    // In release mode, perform additional checks
    if (kReleaseMode) {
      // Check if running on a rooted/jailbroken device (basic check)
      // This is a simplified check - in production, use more sophisticated detection
      
      try {
        // Check for common root/jailbreak indicators
        final suspiciousFiles = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
        ];
        
        for (final file in suspiciousFiles) {
          if (File(file).existsSync()) {
            developer.log('Suspicious file detected: $file', name: 'SecureConfig');
            return false;
          }
        }
      } catch (e) {
        // If we can't check, assume it's secure
        developer.log('Could not perform security check: $e', name: 'SecureConfig');
      }
    }
    
    return true;
  }

  /// Log configuration status (with obfuscation)
  void logConfigurationStatus() {
    final config = validateConfiguration();

    developer.log('Configuration Status:', name: 'SecureConfig');
    developer.log('- OpenRouter: ${config['openrouter_configured']! ? "✅" : "❌"}', name: 'SecureConfig');
    developer.log('- RevenueCat: Removed', name: 'SecureConfig');
    developer.log('- Secure Environment: ${isSecureEnvironment() ? "✅" : "❌"}', name: 'SecureConfig');

    // Log obfuscated keys for debugging
    final openRouterKey = dotenv.env['OPENROUTER_API_KEY'];
    if (openRouterKey != null && openRouterKey.isNotEmpty) {
      developer.log('- OpenRouter Key: ${obfuscateKey(openRouterKey)}', name: 'SecureConfig');
    }
  }
}
