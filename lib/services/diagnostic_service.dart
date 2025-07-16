import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_api_key_service.dart';

/// Comprehensive diagnostic service for OpenRouter API connectivity and configuration
class DiagnosticService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  late final Dio _dio;
  late final Dio? _proxyDio;

  DiagnosticService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://akhi-gpt.app',
        'X-Title': 'Akhi GPT Diagnostics',
      },
    ));

    // Initialize proxy if enabled
    final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
    final useProxy = dotenv.env['ENABLE_PROXY']?.toLowerCase() == 'true';
    
    _proxyDio = useProxy && proxyEndpoint != null
        ? Dio(BaseOptions(
            baseUrl: proxyEndpoint,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'X-User-ID': 'diagnostic-client',
            },
          ))
        : null;
  }

  /// Run comprehensive diagnostics and return detailed report
  Future<DiagnosticReport> runFullDiagnostics() async {
    developer.log('🔍 Starting comprehensive diagnostics...', name: 'DiagnosticService');
    
    final report = DiagnosticReport();
    
    // 1. Environment Configuration Check
    report.environmentCheck = await _checkEnvironmentConfiguration();
    
    // 2. API Key Validation
    report.apiKeyValidation = await _validateApiKey();
    
    // 3. Model Availability Check
    report.modelAvailability = await _checkModelAvailability();
    
    // 4. Proxy Configuration Check
    report.proxyCheck = await _checkProxyConfiguration();
    
    // 5. Network Connectivity Test
    report.networkConnectivity = await _testNetworkConnectivity();
    
    // 6. Fallback Logic Test
    report.fallbackLogic = await _testFallbackLogic();
    
    // Generate overall status
    report.overallStatus = _calculateOverallStatus(report);
    
    developer.log('🔍 Diagnostics completed. Status: ${report.overallStatus}', name: 'DiagnosticService');
    
    return report;
  }

  /// Check environment configuration
  Future<EnvironmentCheck> _checkEnvironmentConfiguration() async {
    developer.log('🔍 Checking environment configuration...', name: 'DiagnosticService');
    
    final check = EnvironmentCheck();
    
    try {
      // Check if .env is loaded
      check.envFileLoaded = dotenv.env.isNotEmpty;
      
      // Check API key presence
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      check.apiKeyPresent = apiKey != null && apiKey.isNotEmpty;
      check.apiKeyFormat = apiKey?.startsWith('sk-or-v1-') ?? false;
      
      // Check default model
      final defaultModel = dotenv.env['DEFAULT_MODEL'];
      check.defaultModelPresent = defaultModel != null && defaultModel.isNotEmpty;
      check.defaultModelFormat = defaultModel?.contains('/') ?? false;
      
      // Check fallback models
      final fallbackModels = dotenv.env['FALLBACK_MODELS'];
      check.fallbackModelsPresent = fallbackModels != null && fallbackModels.isNotEmpty;
      if (fallbackModels != null) {
        final models = fallbackModels.split(',').map((m) => m.trim()).toList();
        check.fallbackModelsCount = models.length;
        check.fallbackModelsValid = models.every((m) => m.contains('/'));
      }
      
      // Check proxy configuration
      check.proxyConfigured = dotenv.env['ENABLE_PROXY']?.toLowerCase() == 'true';
      if (check.proxyConfigured) {
        check.proxyEndpointPresent = dotenv.env['PROXY_ENDPOINT'] != null;
      }
      
      check.isValid = check.apiKeyPresent && 
                     check.apiKeyFormat && 
                     check.defaultModelPresent && 
                     check.defaultModelFormat &&
                     check.fallbackModelsPresent &&
                     check.fallbackModelsValid;
      
    } catch (e) {
      check.error = e.toString();
      check.isValid = false;
    }
    
    return check;
  }

  /// Validate API key with OpenRouter
  Future<ApiKeyValidation> _validateApiKey() async {
    developer.log('🔍 Validating user API key...', name: 'DiagnosticService');

    final validation = ApiKeyValidation();
    final apiKey = await UserApiKeyService.instance.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      validation.error = 'No user API key configured';
      return validation;
    }
    
    try {
      // Test API key with a simple request
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      
      validation.isValid = response.statusCode == 200;
      validation.statusCode = response.statusCode;
      
      if (validation.isValid) {
        final data = response.data as Map<String, dynamic>;
        validation.availableModels = (data['data'] as List?)?.length ?? 0;
      }
      
    } catch (e) {
      if (e is DioException) {
        validation.statusCode = e.response?.statusCode;
        validation.error = e.response?.data?.toString() ?? e.message;
        
        // Check for specific error types
        if (e.response?.statusCode == 401) {
          validation.error = 'Invalid API key - authentication failed';
        } else if (e.response?.statusCode == 403) {
          validation.error = 'API key lacks required permissions';
        }
      } else {
        validation.error = e.toString();
      }
    }
    
    return validation;
  }

  /// Check availability of configured models
  Future<ModelAvailability> _checkModelAvailability() async {
    developer.log('🔍 Checking model availability...', name: 'DiagnosticService');
    
    final availability = ModelAvailability();
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      availability.error = 'API key not available for model testing';
      return availability;
    }
    
    // Get configured models
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModelsStr = dotenv.env['FALLBACK_MODELS'];
    final fallbackModels = fallbackModelsStr?.split(',').map((m) => m.trim()).toList() ?? [];
    
    final allModels = [
      if (defaultModel != null) defaultModel,
      ...fallbackModels,
    ];
    
    availability.totalModels = allModels.length;
    
    for (final model in allModels) {
      final result = await _testSingleModel(model, apiKey);
      availability.modelResults[model] = result;
      
      if (result.isAvailable) {
        availability.availableModels++;
      }
    }
    
    availability.isValid = availability.availableModels > 0;
    
    return availability;
  }

  /// Test a single model's availability
  Future<ModelTestResult> _testSingleModel(String model, String apiKey) async {
    final result = ModelTestResult();
    result.modelName = model;
    
    try {
      developer.log('🔍 Testing model: $model', name: 'DiagnosticService');
      
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'test'}
          ],
          'max_tokens': 1,
        },
      );
      
      result.isAvailable = response.statusCode == 200;
      result.statusCode = response.statusCode;
      result.responseTime = DateTime.now().millisecondsSinceEpoch;
      
    } catch (e) {
      if (e is DioException) {
        result.statusCode = e.response?.statusCode;
        result.error = e.response?.data?.toString() ?? e.message;
        
        // Model-specific error handling
        if (e.response?.statusCode == 404) {
          result.error = 'Model not found or unavailable';
        } else if (e.response?.statusCode == 429) {
          result.error = 'Rate limited - model may be available';
          result.isAvailable = true; // Rate limit doesn't mean model is unavailable
        }
      } else {
        result.error = e.toString();
      }
    }
    
    return result;
  }

  /// Check proxy configuration and connectivity
  Future<ProxyCheck> _checkProxyConfiguration() async {
    developer.log('🔍 Checking proxy configuration...', name: 'DiagnosticService');
    
    final check = ProxyCheck();
    
    check.isEnabled = dotenv.env['ENABLE_PROXY']?.toLowerCase() == 'true';
    check.endpoint = dotenv.env['PROXY_ENDPOINT'];
    
    if (!check.isEnabled) {
      check.isValid = true; // Valid to not use proxy
      return check;
    }
    
    if (check.endpoint == null || check.endpoint!.isEmpty) {
      check.error = 'Proxy enabled but endpoint not configured';
      return check;
    }
    
    if (_proxyDio == null) {
      check.error = 'Proxy Dio client not initialized';
      return check;
    }
    
    try {
      final response = await _proxyDio!.get('/status');
      check.isConnectable = response.statusCode == 200;
      check.statusCode = response.statusCode;
      
      if (check.isConnectable) {
        check.proxyInfo = response.data as Map<String, dynamic>?;
      }
      
      check.isValid = check.isConnectable;
      
    } catch (e) {
      if (e is DioException) {
        check.statusCode = e.response?.statusCode;
        check.error = e.response?.data?.toString() ?? e.message;
      } else {
        check.error = e.toString();
      }
    }
    
    return check;
  }

  /// Test basic network connectivity
  Future<NetworkConnectivity> _testNetworkConnectivity() async {
    developer.log('🔍 Testing network connectivity...', name: 'DiagnosticService');
    
    final connectivity = NetworkConnectivity();
    
    try {
      // Test OpenRouter API base connectivity
      final startTime = DateTime.now();
      final response = await _dio.get('/models');
      final endTime = DateTime.now();
      
      connectivity.openRouterReachable = response.statusCode == 200 || response.statusCode == 401;
      connectivity.responseTime = endTime.difference(startTime).inMilliseconds;
      connectivity.statusCode = response.statusCode;
      
    } catch (e) {
      if (e is DioException) {
        connectivity.statusCode = e.response?.statusCode;
        connectivity.error = e.message ?? 'Network error';
        
        // Even 401 means we can reach the API
        connectivity.openRouterReachable = e.response?.statusCode != null;
      } else {
        connectivity.error = e.toString();
      }
    }
    
    return connectivity;
  }

  /// Test fallback logic
  Future<FallbackLogic> _testFallbackLogic() async {
    developer.log('🔍 Testing fallback logic...', name: 'DiagnosticService');
    
    final logic = FallbackLogic();
    
    try {
      // Check stored fallback state
      final lastWorkingModel = await _secureStorage.read(key: 'last_working_model');
      logic.lastWorkingModel = lastWorkingModel;
      
      final failureCount = await _secureStorage.read(key: 'model_failure_count');
      logic.failureCount = int.tryParse(failureCount ?? '0') ?? 0;
      
      // Test fallback model selection logic
      final fallbackModelsStr = dotenv.env['FALLBACK_MODELS'];
      if (fallbackModelsStr != null) {
        final models = fallbackModelsStr.split(',').map((m) => m.trim()).toList();
        logic.fallbackModelsConfigured = models.length;
        logic.fallbackModels = models;
      }
      
      logic.isValid = logic.fallbackModelsConfigured > 0;
      
    } catch (e) {
      logic.error = e.toString();
    }
    
    return logic;
  }

  /// Calculate overall diagnostic status
  DiagnosticStatus _calculateOverallStatus(DiagnosticReport report) {
    if (!report.environmentCheck.isValid) {
      return DiagnosticStatus.configurationError;
    }
    
    if (!report.apiKeyValidation.isValid) {
      return DiagnosticStatus.authenticationError;
    }
    
    if (!report.networkConnectivity.openRouterReachable) {
      return DiagnosticStatus.networkError;
    }
    
    if (!report.modelAvailability.isValid) {
      return DiagnosticStatus.modelError;
    }
    
    if (report.proxyCheck.isEnabled && !report.proxyCheck.isValid) {
      return DiagnosticStatus.proxyError;
    }
    
    return DiagnosticStatus.healthy;
  }
}

/// Diagnostic report containing all test results
class DiagnosticReport {
  late EnvironmentCheck environmentCheck;
  late ApiKeyValidation apiKeyValidation;
  late ModelAvailability modelAvailability;
  late ProxyCheck proxyCheck;
  late NetworkConnectivity networkConnectivity;
  late FallbackLogic fallbackLogic;
  late DiagnosticStatus overallStatus;
  
  /// Generate human-readable summary
  String generateSummary() {
    final buffer = StringBuffer();
    buffer.writeln('🔍 DIAGNOSTIC REPORT');
    buffer.writeln('Overall Status: ${overallStatus.name.toUpperCase()}');
    buffer.writeln('');
    
    buffer.writeln('📋 Environment Configuration: ${environmentCheck.isValid ? "✅ VALID" : "❌ INVALID"}');
    if (!environmentCheck.isValid && environmentCheck.error != null) {
      buffer.writeln('   Error: ${environmentCheck.error}');
    }
    
    buffer.writeln('🔑 API Key Validation: ${apiKeyValidation.isValid ? "✅ VALID" : "❌ INVALID"}');
    if (!apiKeyValidation.isValid && apiKeyValidation.error != null) {
      buffer.writeln('   Error: ${apiKeyValidation.error}');
    }
    
    buffer.writeln('🤖 Model Availability: ${modelAvailability.availableModels}/${modelAvailability.totalModels} models available');
    
    buffer.writeln('🌐 Network Connectivity: ${networkConnectivity.openRouterReachable ? "✅ CONNECTED" : "❌ DISCONNECTED"}');
    if (networkConnectivity.responseTime != null) {
      buffer.writeln('   Response Time: ${networkConnectivity.responseTime}ms');
    }
    
    if (proxyCheck.isEnabled) {
      buffer.writeln('🔄 Proxy: ${proxyCheck.isValid ? "✅ WORKING" : "❌ FAILED"}');
    } else {
      buffer.writeln('🔄 Proxy: DISABLED');
    }
    
    buffer.writeln('🔄 Fallback Logic: ${fallbackLogic.fallbackModelsConfigured} fallback models configured');
    
    return buffer.toString();
  }
}

/// Overall diagnostic status
enum DiagnosticStatus {
  healthy,
  configurationError,
  authenticationError,
  networkError,
  modelError,
  proxyError,
}

/// Environment configuration check results
class EnvironmentCheck {
  bool envFileLoaded = false;
  bool apiKeyPresent = false;
  bool apiKeyFormat = false;
  bool defaultModelPresent = false;
  bool defaultModelFormat = false;
  bool fallbackModelsPresent = false;
  bool fallbackModelsValid = false;
  int fallbackModelsCount = 0;
  bool proxyConfigured = false;
  bool proxyEndpointPresent = false;
  bool isValid = false;
  String? error;
}

/// API key validation results
class ApiKeyValidation {
  bool isValid = false;
  int? statusCode;
  int availableModels = 0;
  String? error;
}

/// Model availability check results
class ModelAvailability {
  int totalModels = 0;
  int availableModels = 0;
  Map<String, ModelTestResult> modelResults = {};
  bool isValid = false;
  String? error;
}

/// Individual model test result
class ModelTestResult {
  String modelName = '';
  bool isAvailable = false;
  int? statusCode;
  int? responseTime;
  String? error;
}

/// Proxy configuration check results
class ProxyCheck {
  bool isEnabled = false;
  String? endpoint;
  bool isConnectable = false;
  bool isValid = false;
  int? statusCode;
  Map<String, dynamic>? proxyInfo;
  String? error;
}

/// Network connectivity test results
class NetworkConnectivity {
  bool openRouterReachable = false;
  int? responseTime;
  int? statusCode;
  String? error;
}

/// Fallback logic test results
class FallbackLogic {
  String? lastWorkingModel;
  int failureCount = 0;
  int fallbackModelsConfigured = 0;
  List<String> fallbackModels = [];
  bool isValid = false;
  String? error;
}
