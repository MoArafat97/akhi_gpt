import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

/// Utility class for validating configuration and environment setup
class ConfigValidator {
  
  /// Validate API key format and presence (now user-dependent)
  static ValidationResult validateApiKey() {
    developer.log('🔍 Skipping client API key validation (managed elsewhere)', name: 'ConfigValidator');
    return const ValidationResult(isValid: true);
  }
  
  /// Validate model configuration
  static ValidationResult validateModels() {
    developer.log('🔍 Validating model configuration...', name: 'ConfigValidator');
    
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModelsStr = dotenv.env['FALLBACK_MODELS'];
    
    // Check default model
    if (defaultModel == null || defaultModel.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Default model not configured',
        suggestion: 'Add DEFAULT_MODEL to your .env file (e.g., qwen/qwen3-32b:free)',
      );
    }
    
    if (!defaultModel.contains('/')) {
      return ValidationResult(
        isValid: false,
        error: 'Default model format is invalid',
        suggestion: 'Model names should be in format "provider/model-name" (e.g., qwen/qwen3-32b:free)',
      );
    }
    
    // Check fallback models
    if (fallbackModelsStr == null || fallbackModelsStr.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'No fallback models configured',
        suggestion: 'Add FALLBACK_MODELS to your .env file with comma-separated model names',
      );
    }
    
    final fallbackModels = fallbackModelsStr.split(',').map((m) => m.trim()).toList();
    
    if (fallbackModels.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Fallback models list is empty',
        suggestion: 'Add at least one fallback model to FALLBACK_MODELS',
      );
    }
    
    // Validate each fallback model format
    for (final model in fallbackModels) {
      if (!model.contains('/')) {
        return ValidationResult(
          isValid: false,
          error: 'Fallback model "$model" has invalid format',
          suggestion: 'All model names should be in format "provider/model-name"',
        );
      }
    }
    
    // Check for duplicates
    final uniqueModels = fallbackModels.toSet();
    if (uniqueModels.length != fallbackModels.length) {
      return ValidationResult(
        isValid: false,
        error: 'Duplicate models found in fallback list',
        suggestion: 'Remove duplicate model names from FALLBACK_MODELS',
      );
    }
    
    // Check if default model is also in fallback list
    if (fallbackModels.contains(defaultModel)) {
      developer.log('⚠️ Default model is also in fallback list - this is redundant but not invalid', name: 'ConfigValidator');
    }
    
    developer.log('✅ Model configuration validation passed', name: 'ConfigValidator');
    return ValidationResult(isValid: true);
  }
  
  /// Validate proxy configuration
  static ValidationResult validateProxyConfig() {
    developer.log('🔍 Validating proxy configuration...', name: 'ConfigValidator');
    
    final enableProxy = dotenv.env['ENABLE_PROXY']?.toLowerCase();
    final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
    
    if (enableProxy != 'true' && enableProxy != 'false') {
      return ValidationResult(
        isValid: false,
        error: 'ENABLE_PROXY must be either "true" or "false"',
        suggestion: 'Set ENABLE_PROXY to "true" or "false" in your .env file',
      );
    }
    
    if (enableProxy == 'true') {
      if (proxyEndpoint == null || proxyEndpoint.isEmpty) {
        return ValidationResult(
          isValid: false,
          error: 'Proxy enabled but PROXY_ENDPOINT not configured',
          suggestion: 'Add PROXY_ENDPOINT to your .env file (e.g., http://localhost:8080)',
        );
      }
      
      if (!proxyEndpoint.startsWith('http://') && !proxyEndpoint.startsWith('https://')) {
        return ValidationResult(
          isValid: false,
          error: 'Proxy endpoint must start with http:// or https://',
          suggestion: 'Update PROXY_ENDPOINT to include the protocol (e.g., http://localhost:8080)',
        );
      }
    }
    
    developer.log('✅ Proxy configuration validation passed', name: 'ConfigValidator');
    return ValidationResult(isValid: true);
  }
  
  /// Validate all environment variables
  static ValidationResult validateEnvironment() {
    developer.log('🔍 Validating complete environment configuration...', name: 'ConfigValidator');
    
    // Check if .env file was loaded
    if (dotenv.env.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Environment variables not loaded',
        suggestion: 'Ensure .env file exists and is being loaded in main.dart',
      );
    }
    
    // Validate each component
    final apiKeyResult = validateApiKey();
    if (!apiKeyResult.isValid) return apiKeyResult;
    
    final modelsResult = validateModels();
    if (!modelsResult.isValid) return modelsResult;
    
    final proxyResult = validateProxyConfig();
    if (!proxyResult.isValid) return proxyResult;
    
    developer.log('✅ Complete environment validation passed', name: 'ConfigValidator');
    return ValidationResult(isValid: true);
  }
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModelsStr = dotenv.env['FALLBACK_MODELS'];
    final enableProxy = dotenv.env['ENABLE_PROXY'];
    final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
    
    return {
      'environment_loaded': dotenv.env.isNotEmpty,
      'api_key_present': apiKey != null && apiKey.isNotEmpty,
      'api_key_format_valid': apiKey?.startsWith('sk-or-v1-') ?? false,
      'api_key_length': apiKey?.length ?? 0,
      'default_model': defaultModel,
      'default_model_valid': defaultModel?.contains('/') ?? false,
      'fallback_models_raw': fallbackModelsStr,
      'fallback_models_count': fallbackModelsStr?.split(',').length ?? 0,
      'proxy_enabled': enableProxy?.toLowerCase() == 'true',
      'proxy_endpoint': proxyEndpoint,
      'proxy_endpoint_valid': proxyEndpoint?.startsWith('http') ?? false,
      'total_env_vars': dotenv.env.length,
      'env_var_keys': dotenv.env.keys.toList(),
    };
  }
  
  /// Generate human-readable configuration report
  static String generateConfigReport() {
    final summary = getConfigSummary();
    final buffer = StringBuffer();
    
    buffer.writeln('📋 CONFIGURATION REPORT');
    buffer.writeln('=======================');
    buffer.writeln('');
    
    buffer.writeln('🔧 Environment:');
    buffer.writeln('  - Variables loaded: ${(summary['environment_loaded'] as bool) ? "✅" : "❌"}');
    buffer.writeln('  - Total variables: ${summary['total_env_vars']}');
    buffer.writeln('');
    
    buffer.writeln('🔑 API Key:');
    buffer.writeln('  - Present: ${(summary['api_key_present'] as bool) ? "✅" : "❌"}');
    buffer.writeln('  - Format valid: ${(summary['api_key_format_valid'] as bool) ? "✅" : "❌"}');
    buffer.writeln('  - Length: ${summary['api_key_length']} characters');
    buffer.writeln('');
    
    buffer.writeln('🤖 Models:');
    buffer.writeln('  - Default model: ${summary['default_model'] ?? "❌ Not set"}');
    buffer.writeln('  - Default model valid: ${(summary['default_model_valid'] as bool) ? "✅" : "❌"}');
    buffer.writeln('  - Fallback models count: ${summary['fallback_models_count']}');
    buffer.writeln('  - Fallback models: ${summary['fallback_models_raw'] ?? "❌ Not set"}');
    buffer.writeln('');
    
    buffer.writeln('🔄 Proxy:');
    buffer.writeln('  - Enabled: ${(summary['proxy_enabled'] as bool) ? "✅ Yes" : "❌ No"}');
    if ((summary['proxy_enabled'] as bool)) {
      buffer.writeln('  - Endpoint: ${summary['proxy_endpoint'] ?? "❌ Not set"}');
      buffer.writeln('  - Endpoint valid: ${(summary['proxy_endpoint_valid'] as bool) ? "✅" : "❌"}');
    }
    buffer.writeln('');
    
    buffer.writeln('🔍 Available Environment Variables:');
    final envKeys = summary['env_var_keys'] as List<String>;
    for (final key in envKeys) {
      buffer.writeln('  - $key');
    }
    
    return buffer.toString();
  }
  
  /// Quick validation check for startup
  static bool isBasicConfigValid() {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      final defaultModel = dotenv.env['DEFAULT_MODEL'];
      final fallbackModels = dotenv.env['FALLBACK_MODELS'];
      
      return apiKey != null && 
             apiKey.isNotEmpty && 
             apiKey.startsWith('sk-or-v1-') &&
             defaultModel != null && 
             defaultModel.contains('/') &&
             fallbackModels != null && 
             fallbackModels.isNotEmpty;
    } catch (e) {
      developer.log('❌ Basic config validation failed: $e', name: 'ConfigValidator');
      return false;
    }
  }
}

/// Result of a validation check
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? suggestion;
  
  const ValidationResult({
    required this.isValid,
    this.error,
    this.suggestion,
  });
  
  @override
  String toString() {
    if (isValid) return 'ValidationResult: Valid';
    return 'ValidationResult: Invalid - $error${suggestion != null ? " | Suggestion: $suggestion" : ""}';
  }
}
