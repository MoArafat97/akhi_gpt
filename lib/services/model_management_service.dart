import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_api_key_service.dart';

/// Service for managing OpenRouter model selection and caching
class ModelManagementService {
  static const String _selectedModelKey = 'selected_openrouter_model';
  static const String _cachedModelsKey = 'cached_openrouter_models';
  static const String _lastModelFetchKey = 'last_model_fetch_time';
  static const String _defaultModelId = 'qwen/qwen-2.5-32b-instruct:free';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://openrouter.ai/api/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static ModelManagementService? _instance;
  static ModelManagementService get instance => _instance ??= ModelManagementService._();
  
  ModelManagementService._();

  /// Get the user's selected model
  Future<String> getSelectedModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedModelKey) ?? _defaultModelId;
    } catch (e) {
      developer.log('Failed to get selected model: $e', name: 'ModelManagementService');
      return _defaultModelId;
    }
  }

  /// Set the user's selected model
  Future<void> setSelectedModel(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedModelKey, modelId);
      developer.log('Selected model updated: $modelId', name: 'ModelManagementService');
    } catch (e) {
      developer.log('Failed to set selected model: $e', name: 'ModelManagementService');
      throw Exception('Failed to save model selection');
    }
  }

  /// Fetch available models from OpenRouter API
  Future<List<OpenRouterModel>> fetchAvailableModels({bool forceRefresh = false}) async {
    // Check if we have cached models and they're still fresh
    if (!forceRefresh) {
      final cachedModels = await _getCachedModels();
      if (cachedModels.isNotEmpty && await _isCacheValid()) {
        developer.log('Using cached models (${cachedModels.length} models)', name: 'ModelManagementService');
        return cachedModels;
      }
    }

    // Get user's API key
    final apiKey = await UserApiKeyService.instance.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key available. Please set your OpenRouter API key first.');
    }

    try {
      developer.log('Fetching models from OpenRouter API...', name: 'ModelManagementService');
      
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://nafs-ai.app',
            'X-Title': 'NafsAI',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final modelsData = data['data'] as List;
        
        final models = modelsData
            .map((modelData) => OpenRouterModel.fromJson(modelData))
            .where((model) => _isModelSupported(model))
            .toList();

        // Sort models by preference (free models first, then by name)
        models.sort((a, b) {
          // Free models first
          final aIsFree = a.pricing.prompt == '0' && a.pricing.completion == '0';
          final bIsFree = b.pricing.prompt == '0' && b.pricing.completion == '0';
          
          if (aIsFree && !bIsFree) return -1;
          if (!aIsFree && bIsFree) return 1;
          
          // Then sort by name
          return a.name.compareTo(b.name);
        });

        // Cache the models
        await _cacheModels(models);
        
        developer.log('Fetched ${models.length} supported models', name: 'ModelManagementService');
        return models;
      } else {
        throw Exception('Failed to fetch models (HTTP ${response.statusCode})');
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
      } else {
        errorMessage = 'Network error: ${e.message}';
      }
      
      developer.log('Failed to fetch models: $errorMessage', name: 'ModelManagementService');
      throw Exception(errorMessage);
    }
  }

  /// Get cached models from local storage
  Future<List<OpenRouterModel>> _getCachedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedModelsKey);
      
      if (cachedJson == null) return [];
      
      final List<dynamic> modelsData = jsonDecode(cachedJson);
      return modelsData
          .map((data) => OpenRouterModel.fromJson(data))
          .toList();
    } catch (e) {
      developer.log('Failed to load cached models: $e', name: 'ModelManagementService');
      return [];
    }
  }

  /// Cache models to local storage
  Future<void> _cacheModels(List<OpenRouterModel> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modelsJson = jsonEncode(models.map((m) => m.toJson()).toList());
      
      await prefs.setString(_cachedModelsKey, modelsJson);
      await prefs.setInt(_lastModelFetchKey, DateTime.now().millisecondsSinceEpoch);
      
      developer.log('Cached ${models.length} models', name: 'ModelManagementService');
    } catch (e) {
      developer.log('Failed to cache models: $e', name: 'ModelManagementService');
    }
  }

  /// Check if cached models are still valid (within 24 hours)
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastModelFetchKey);
      
      if (lastFetch == null) return false;
      
      final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final cacheExpiry = lastFetchTime.add(const Duration(hours: 24));
      
      return DateTime.now().isBefore(cacheExpiry);
    } catch (e) {
      return false;
    }
  }

  /// Check if a model is supported for chat completion
  bool _isModelSupported(OpenRouterModel model) {
    // Only include models that support text input and output
    final supportsTextInput = model.architecture.inputModalities.contains('text');
    final supportsTextOutput = model.architecture.outputModalities.contains('text');
    
    return supportsTextInput && supportsTextOutput;
  }

  /// Get model by ID from cached models
  Future<OpenRouterModel?> getModelById(String modelId) async {
    try {
      final models = await _getCachedModels();
      return models.firstWhere(
        (model) => model.id == modelId,
        orElse: () => throw StateError('Model not found'),
      );
    } catch (e) {
      developer.log('Model not found: $modelId', name: 'ModelManagementService');
      return null;
    }
  }

  /// Clear cached models (useful for testing or troubleshooting)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedModelsKey);
      await prefs.remove(_lastModelFetchKey);
      developer.log('Model cache cleared', name: 'ModelManagementService');
    } catch (e) {
      developer.log('Failed to clear model cache: $e', name: 'ModelManagementService');
    }
  }
}

/// OpenRouter model data structure
class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final int contextLength;
  final ModelArchitecture architecture;
  final ModelPricing pricing;
  final List<String> supportedParameters;

  OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.contextLength,
    required this.architecture,
    required this.pricing,
    required this.supportedParameters,
  });

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    return OpenRouterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contextLength: json['context_length'] ?? 0,
      architecture: ModelArchitecture.fromJson(json['architecture'] ?? {}),
      pricing: ModelPricing.fromJson(json['pricing'] ?? {}),
      supportedParameters: List<String>.from(json['supported_parameters'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'context_length': contextLength,
      'architecture': architecture.toJson(),
      'pricing': pricing.toJson(),
      'supported_parameters': supportedParameters,
    };
  }

  /// Check if this model is free to use
  bool get isFree => pricing.prompt == '0' && pricing.completion == '0';

  /// Get formatted pricing information
  String get formattedPricing {
    if (isFree) return 'Free';
    
    final promptPrice = double.tryParse(pricing.prompt) ?? 0;
    final completionPrice = double.tryParse(pricing.completion) ?? 0;
    
    if (promptPrice > 0 || completionPrice > 0) {
      return '\$${(promptPrice * 1000000).toStringAsFixed(2)}/\$${(completionPrice * 1000000).toStringAsFixed(2)} per 1M tokens';
    }
    
    return 'Pricing varies';
  }
}

class ModelArchitecture {
  final List<String> inputModalities;
  final List<String> outputModalities;
  final String tokenizer;

  ModelArchitecture({
    required this.inputModalities,
    required this.outputModalities,
    required this.tokenizer,
  });

  factory ModelArchitecture.fromJson(Map<String, dynamic> json) {
    return ModelArchitecture(
      inputModalities: List<String>.from(json['input_modalities'] ?? []),
      outputModalities: List<String>.from(json['output_modalities'] ?? []),
      tokenizer: json['tokenizer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input_modalities': inputModalities,
      'output_modalities': outputModalities,
      'tokenizer': tokenizer,
    };
  }
}

class ModelPricing {
  final String prompt;
  final String completion;
  final String request;
  final String image;

  ModelPricing({
    required this.prompt,
    required this.completion,
    required this.request,
    required this.image,
  });

  factory ModelPricing.fromJson(Map<String, dynamic> json) {
    return ModelPricing(
      prompt: json['prompt']?.toString() ?? '0',
      completion: json['completion']?.toString() ?? '0',
      request: json['request']?.toString() ?? '0',
      image: json['image']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'completion': completion,
      'request': request,
      'image': image,
    };
  }
}
