import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/openrouter_service.dart';

class ConfigHelper {
  static final OpenRouterService _service = OpenRouterService();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Check if the service is properly configured
  static Future<bool> isConfigured() async {
    return await _service.isConfigured;
  }

  /// Get current configuration status with fallback model info
  static Future<Map<String, dynamic>> getStatus() async {
    final lastWorkingModel = await _secureStorage.read(key: 'last_working_model');
    final isConfigured = await _service.isConfigured;

    return {
      'isConfigured': isConfigured,
      'currentModel': _service.modelDisplayName,
      'hasApiKey': isConfigured,
      'lastWorkingModel': lastWorkingModel,
      'hasFallbackSupport': true,
    };
  }

  /// Get current configuration status (synchronous version for backward compatibility)
  static Map<String, dynamic> getStatusSync() {
    return {
      'isConfigured': _service.isConfiguredSync,
      'currentModel': _service.modelDisplayName,
      'hasApiKey': _service.isConfiguredSync,
      'hasFallbackSupport': true,
    };
  }

  /// Test the connection with a simple message
  static Future<bool> testConnection() async {
    try {
      return await _service.testConnection();
    } catch (e) {
      return false;
    }
  }

  /// Reset fallback model to primary (useful for testing)
  static Future<void> resetToDefaultModel() async {
    await _secureStorage.delete(key: 'last_working_model');
    await _secureStorage.delete(key: 'model_failure_count');
  }

  /// Get the list of available fallback models from environment
  static List<String> getFallbackModels() {
    return _service.fallbackModels;
  }
}

