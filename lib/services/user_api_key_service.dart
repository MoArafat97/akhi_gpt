import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

/// Service for managing user's OpenRouter API keys
class UserApiKeyService {
  static const String _apiKeyStorageKey = 'user_openrouter_api_key';
  static const String _apiKeyValidatedKey = 'api_key_validated';
  static const String _lastValidationKey = 'last_api_key_validation';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://openrouter.ai/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static UserApiKeyService? _instance;
  static UserApiKeyService get instance => _instance ??= UserApiKeyService._();
  
  UserApiKeyService._();

  /// Get the user's stored API key
  Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _apiKeyStorageKey);
    } catch (e) {
      developer.log('Failed to read API key: $e', name: 'UserApiKeyService');
      return null;
    }
  }

  /// Store the user's API key securely
  Future<void> setApiKey(String apiKey) async {
    try {
      final cleanKey = apiKey.trim();
      if (cleanKey.isEmpty) {
        await clearApiKey();
        return;
      }
      
      await _secureStorage.write(key: _apiKeyStorageKey, value: cleanKey);
      // Reset validation status when key changes
      await _secureStorage.delete(key: _apiKeyValidatedKey);
      await _secureStorage.delete(key: _lastValidationKey);
      
      developer.log('API key stored successfully', name: 'UserApiKeyService');
    } catch (e) {
      developer.log('Failed to store API key: $e', name: 'UserApiKeyService');
      throw Exception('Failed to store API key securely');
    }
  }

  /// Clear the stored API key
  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _apiKeyStorageKey);
      await _secureStorage.delete(key: _apiKeyValidatedKey);
      await _secureStorage.delete(key: _lastValidationKey);
      developer.log('API key cleared', name: 'UserApiKeyService');
    } catch (e) {
      developer.log('Failed to clear API key: $e', name: 'UserApiKeyService');
    }
  }

  /// Check if user has an API key stored
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Validate the API key format
  bool isValidApiKeyFormat(String apiKey) {
    final cleanKey = apiKey.trim();
    // OpenRouter API keys start with 'sk-or-v1-'
    return cleanKey.startsWith('sk-or-v1-') && cleanKey.length > 20;
  }

  /// Validate API key by making a test request to OpenRouter
  Future<ApiKeyValidationResult> validateApiKey([String? apiKey]) async {
    final keyToValidate = apiKey ?? await getApiKey();
    
    if (keyToValidate == null || keyToValidate.isEmpty) {
      return ApiKeyValidationResult(
        isValid: false,
        error: 'No API key provided',
      );
    }

    if (!isValidApiKeyFormat(keyToValidate)) {
      return ApiKeyValidationResult(
        isValid: false,
        error: 'Invalid API key format. OpenRouter keys start with "sk-or-v1-"',
      );
    }

    try {
      developer.log('Validating API key...', name: 'UserApiKeyService');
      
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $keyToValidate',
            'HTTP-Referer': 'https://akhi-gpt.app',
            'X-Title': 'Akhi GPT',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final models = data['data'] as List?;
        
        // Store validation result
        await _secureStorage.write(key: _apiKeyValidatedKey, value: 'true');
        await _secureStorage.write(
          key: _lastValidationKey, 
          value: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        developer.log('API key validated successfully', name: 'UserApiKeyService');
        
        return ApiKeyValidationResult(
          isValid: true,
          availableModels: models?.length ?? 0,
        );
      } else {
        return ApiKeyValidationResult(
          isValid: false,
          error: 'API key validation failed (HTTP ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid API key. Please check your OpenRouter API key.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'API key does not have sufficient permissions.';
      } else if (e.response?.statusCode == 429) {
        errorMessage = 'Rate limit exceeded. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      } else {
        errorMessage = 'Network error: ${e.message}';
      }
      
      developer.log('API key validation failed: $errorMessage', name: 'UserApiKeyService');
      
      return ApiKeyValidationResult(
        isValid: false,
        error: errorMessage,
      );
    } catch (e) {
      developer.log('Unexpected error during API key validation: $e', name: 'UserApiKeyService');
      
      return ApiKeyValidationResult(
        isValid: false,
        error: 'Unexpected error during validation: $e',
      );
    }
  }

  /// Check if the stored API key was recently validated
  Future<bool> isApiKeyRecentlyValidated() async {
    try {
      final validated = await _secureStorage.read(key: _apiKeyValidatedKey);
      final lastValidationStr = await _secureStorage.read(key: _lastValidationKey);
      
      if (validated != 'true' || lastValidationStr == null) {
        return false;
      }
      
      final lastValidation = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastValidationStr),
      );
      
      // Consider validation valid for 24 hours
      final validationExpiry = lastValidation.add(const Duration(hours: 24));
      return DateTime.now().isBefore(validationExpiry);
    } catch (e) {
      developer.log('Error checking validation status: $e', name: 'UserApiKeyService');
      return false;
    }
  }

  /// Get API key validation status
  Future<ApiKeyStatus> getApiKeyStatus() async {
    final hasKey = await hasApiKey();
    if (!hasKey) {
      return ApiKeyStatus.notSet;
    }
    
    final isRecentlyValidated = await isApiKeyRecentlyValidated();
    if (isRecentlyValidated) {
      return ApiKeyStatus.valid;
    }
    
    return ApiKeyStatus.needsValidation;
  }
}

/// Result of API key validation
class ApiKeyValidationResult {
  final bool isValid;
  final String? error;
  final int? availableModels;

  ApiKeyValidationResult({
    required this.isValid,
    this.error,
    this.availableModels,
  });
}

/// Status of user's API key
enum ApiKeyStatus {
  notSet,
  needsValidation,
  valid,
}
