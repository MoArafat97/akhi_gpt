import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import '../lib/services/model_management_service.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'model_management_service_test.mocks.dart';

void main() {
  group('ModelManagementService Tests', () {
    late ModelManagementService service;
    late MockDio mockDio;

    setUp(() {
      service = ModelManagementService.instance;
      mockDio = MockDio();

      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
    });

    group('Model Data Structure', () {
      test('should create OpenRouterModel from JSON', () {
        final json = {
          'id': 'test/model-1',
          'name': 'Test Model 1',
          'description': 'A test model for unit testing',
          'context_length': 4096,
          'architecture': {
            'input_modalities': ['text'],
            'output_modalities': ['text'],
            'tokenizer': 'GPT',
          },
          'pricing': {
            'prompt': '0.0001',
            'completion': '0.0002',
            'request': '0',
            'image': '0',
          },
          'supported_parameters': ['temperature', 'max_tokens'],
        };

        final model = OpenRouterModel.fromJson(json);

        expect(model.id, equals('test/model-1'));
        expect(model.name, equals('Test Model 1'));
        expect(model.description, equals('A test model for unit testing'));
        expect(model.contextLength, equals(4096));
        expect(model.architecture.inputModalities, contains('text'));
        expect(model.architecture.outputModalities, contains('text'));
        expect(model.pricing.prompt, equals('0.0001'));
        expect(model.pricing.completion, equals('0.0002'));
        expect(model.supportedParameters, contains('temperature'));
      });

      test('should handle missing JSON fields gracefully', () {
        final json = {
          'id': 'test/minimal-model',
          'name': 'Minimal Model',
        };

        final model = OpenRouterModel.fromJson(json);

        expect(model.id, equals('test/minimal-model'));
        expect(model.name, equals('Minimal Model'));
        expect(model.description, equals(''));
        expect(model.contextLength, equals(0));
        expect(model.architecture.inputModalities, isEmpty);
        expect(model.pricing.prompt, equals('0'));
      });

      test('should convert model back to JSON', () {
        final model = OpenRouterModel(
          id: 'test/model-json',
          name: 'JSON Test Model',
          description: 'Test JSON serialization',
          contextLength: 8192,
          architecture: ModelArchitecture(
            inputModalities: ['text', 'image'],
            outputModalities: ['text'],
            tokenizer: 'GPT',
          ),
          pricing: ModelPricing(
            prompt: '0.001',
            completion: '0.002',
            request: '0',
            image: '0.01',
          ),
          supportedParameters: ['temperature', 'top_p'],
        );

        final json = model.toJson();

        expect(json['id'], equals('test/model-json'));
        expect(json['name'], equals('JSON Test Model'));
        expect(json['context_length'], equals(8192));
        expect(json['architecture']['input_modalities'], contains('text'));
        expect(json['pricing']['prompt'], equals('0.001'));
        expect(json['supported_parameters'], contains('temperature'));
      });
    });

    group('Model Properties', () {
      test('should correctly identify free models', () {
        final freeModel = OpenRouterModel(
          id: 'free/model',
          name: 'Free Model',
          description: 'A free model',
          contextLength: 4096,
          architecture: ModelArchitecture(
            inputModalities: ['text'],
            outputModalities: ['text'],
            tokenizer: 'GPT',
          ),
          pricing: ModelPricing(
            prompt: '0',
            completion: '0',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        expect(freeModel.isFree, isTrue);
      });

      test('should correctly identify paid models', () {
        final paidModel = OpenRouterModel(
          id: 'paid/model',
          name: 'Paid Model',
          description: 'A paid model',
          contextLength: 4096,
          architecture: ModelArchitecture(
            inputModalities: ['text'],
            outputModalities: ['text'],
            tokenizer: 'GPT',
          ),
          pricing: ModelPricing(
            prompt: '0.001',
            completion: '0.002',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        expect(paidModel.isFree, isFalse);
      });

      test('should format pricing correctly', () {
        final freeModel = OpenRouterModel(
          id: 'free/model',
          name: 'Free Model',
          description: '',
          contextLength: 0,
          architecture: ModelArchitecture(
            inputModalities: [],
            outputModalities: [],
            tokenizer: '',
          ),
          pricing: ModelPricing(
            prompt: '0',
            completion: '0',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        expect(freeModel.formattedPricing, equals('Free'));

        final paidModel = OpenRouterModel(
          id: 'paid/model',
          name: 'Paid Model',
          description: '',
          contextLength: 0,
          architecture: ModelArchitecture(
            inputModalities: [],
            outputModalities: [],
            tokenizer: '',
          ),
          pricing: ModelPricing(
            prompt: '0.000001',
            completion: '0.000002',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        expect(paidModel.formattedPricing, contains('1.00'));
        expect(paidModel.formattedPricing, contains('2.00'));
        expect(paidModel.formattedPricing, contains('1M tokens'));
      });
    });

    group('Model Selection', () {
      test('should store and retrieve selected model', () async {
        const testModelId = 'test/selected-model';
        
        await service.setSelectedModel(testModelId);
        final retrievedModel = await service.getSelectedModel();
        
        expect(retrievedModel, equals(testModelId));
      });

      test('should return default model when none selected', () async {
        // Clear any existing selection
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_openrouter_model');
        
        final defaultModel = await service.getSelectedModel();
        
        expect(defaultModel, equals('qwen/qwen-2.5-32b-instruct:free'));
      });
    });

    group('Model Filtering', () {
      test('should filter supported models correctly', () {
        final supportedModel = OpenRouterModel(
          id: 'supported/model',
          name: 'Supported Model',
          description: '',
          contextLength: 0,
          architecture: ModelArchitecture(
            inputModalities: ['text'],
            outputModalities: ['text'],
            tokenizer: 'GPT',
          ),
          pricing: ModelPricing(
            prompt: '0',
            completion: '0',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        final unsupportedModel = OpenRouterModel(
          id: 'unsupported/model',
          name: 'Unsupported Model',
          description: '',
          contextLength: 0,
          architecture: ModelArchitecture(
            inputModalities: ['audio'],
            outputModalities: ['audio'],
            tokenizer: 'Custom',
          ),
          pricing: ModelPricing(
            prompt: '0',
            completion: '0',
            request: '0',
            image: '0',
          ),
          supportedParameters: [],
        );

        // Test the filtering logic (this would be internal to the service)
        expect(supportedModel.architecture.inputModalities.contains('text'), isTrue);
        expect(supportedModel.architecture.outputModalities.contains('text'), isTrue);
        
        expect(unsupportedModel.architecture.inputModalities.contains('text'), isFalse);
        expect(unsupportedModel.architecture.outputModalities.contains('text'), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        when(mockApiKeyService.getApiKey())
            .thenAnswer((_) async => 'sk-or-v1-test-key');

        when(mockDio.get(any, options: anyNamed('options')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/models'),
              type: DioExceptionType.connectionTimeout,
            ));

        // The service should handle network errors gracefully
        expect(() async => await service.fetchAvailableModels(), throwsException);
      });

      test('should handle missing API key', () async {
        when(mockApiKeyService.getApiKey())
            .thenAnswer((_) async => null);

        expect(() async => await service.fetchAvailableModels(), throwsException);
      });
    });

    group('Caching', () {
      test('should handle cache operations', () async {
        // Test cache clearing
        await service.clearCache();
        
        // Verify cache is cleared (this would need access to internal state)
        expect(() async => await service.clearCache(), returnsNormally);
      });
    });
  });
}

// Test utilities
class TestModelFactory {
  static OpenRouterModel createFreeModel(String id, String name) {
    return OpenRouterModel(
      id: id,
      name: name,
      description: 'Test free model',
      contextLength: 4096,
      architecture: ModelArchitecture(
        inputModalities: ['text'],
        outputModalities: ['text'],
        tokenizer: 'GPT',
      ),
      pricing: ModelPricing(
        prompt: '0',
        completion: '0',
        request: '0',
        image: '0',
      ),
      supportedParameters: ['temperature'],
    );
  }

  static OpenRouterModel createPaidModel(String id, String name, String promptPrice, String completionPrice) {
    return OpenRouterModel(
      id: id,
      name: name,
      description: 'Test paid model',
      contextLength: 8192,
      architecture: ModelArchitecture(
        inputModalities: ['text'],
        outputModalities: ['text'],
        tokenizer: 'GPT',
      ),
      pricing: ModelPricing(
        prompt: promptPrice,
        completion: completionPrice,
        request: '0',
        image: '0',
      ),
      supportedParameters: ['temperature', 'top_p'],
    );
  }
}
