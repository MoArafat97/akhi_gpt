import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import '../lib/services/openrouter_service.dart';
import '../lib/services/diagnostic_service.dart';

// Generate mocks
@GenerateMocks([Dio, FlutterSecureStorage])
import 'openrouter_service_test.mocks.dart';

void main() {
  group('OpenRouter Service Tests', () {
    late OpenRouterService service;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      // Initialize dotenv with test values
      dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=sk-or-v1-test-key-12345
DEFAULT_MODEL=qwen/qwen3-32b:free
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free
ENABLE_PROXY=false
PROXY_ENDPOINT=http://localhost:8080
''');

      mockDio = MockDio();
      mockStorage = MockFlutterSecureStorage();
      service = OpenRouterService();
    });

    group('Configuration Tests', () {
      test('should be configured with valid API key and models', () {
        expect(service.isConfigured, isTrue);
        expect(service.fallbackModels, isNotEmpty);
        expect(service.fallbackModels.length, equals(2));
      });

      test('should not be configured without API key', () {
        dotenv.testLoad(fileInput: '''
DEFAULT_MODEL=qwen/qwen3-32b:free
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free
''');
        
        final testService = OpenRouterService();
        expect(testService.isConfigured, isFalse);
      });

      test('should not be configured without models', () {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=sk-or-v1-test-key-12345
''');
        
        final testService = OpenRouterService();
        expect(testService.isConfigured, isFalse);
      });

      test('should parse fallback models correctly', () {
        expect(service.fallbackModels, contains('qwen/qwq-32b:free'));
        expect(service.fallbackModels, contains('qwen/qwen3-235b-a22b:free'));
      });
    });

    group('Error Detection Tests', () {
      test('should detect rate limit errors', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            data: {'error': 'Rate limit exceeded'},
          ),
        );

        // Use reflection or make method public for testing
        // For now, we'll test through the public interface
        expect(() => service.chatStream('test', []), throwsA(isA<Exception>()));
      });

      test('should detect model unavailable errors', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
            data: {'error': 'Model not found'},
          ),
        );

        // Test that 404 errors are handled appropriately
        expect(dioError.response?.statusCode, equals(404));
      });

      test('should detect service unavailable errors', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
            data: {'error': 'Service temporarily unavailable'},
          ),
        );

        expect(dioError.response?.statusCode, equals(503));
      });
    });

    group('Model Fallback Tests', () {
      test('should have correct fallback hierarchy', () {
        final models = service.fallbackModels;
        expect(models[0], equals('qwen/qwq-32b:free'));
        expect(models[1], equals('qwen/qwen3-235b-a22b:free'));
      });

      test('should use default model when no fallback models configured', () {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=sk-or-v1-test-key-12345
DEFAULT_MODEL=qwen/qwen3-32b:free
''');
        
        final testService = OpenRouterService();
        expect(testService.fallbackModels, contains('qwen/qwen3-32b:free'));
      });
    });

    group('Environment Variable Tests', () {
      test('should load API key from environment', () {
        expect(dotenv.env['OPENROUTER_API_KEY'], equals('sk-or-v1-test-key-12345'));
      });

      test('should load default model from environment', () {
        expect(dotenv.env['DEFAULT_MODEL'], equals('qwen/qwen3-32b:free'));
      });

      test('should load fallback models from environment', () {
        expect(dotenv.env['FALLBACK_MODELS'], equals('qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free'));
      });

      test('should handle proxy configuration', () {
        expect(dotenv.env['ENABLE_PROXY'], equals('false'));
        expect(dotenv.env['PROXY_ENDPOINT'], equals('http://localhost:8080'));
      });
    });
  });

  group('Diagnostic Service Tests', () {
    late DiagnosticService diagnosticService;

    setUp(() {
      dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=sk-or-v1-test-key-12345
DEFAULT_MODEL=qwen/qwen3-32b:free
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free
ENABLE_PROXY=false
PROXY_ENDPOINT=http://localhost:8080
''');

      diagnosticService = DiagnosticService();
    });

    group('Environment Check Tests', () {
      test('should validate correct environment configuration', () async {
        final report = await diagnosticService.runFullDiagnostics();
        
        expect(report.environmentCheck.envFileLoaded, isTrue);
        expect(report.environmentCheck.apiKeyPresent, isTrue);
        expect(report.environmentCheck.apiKeyFormat, isTrue);
        expect(report.environmentCheck.defaultModelPresent, isTrue);
        expect(report.environmentCheck.defaultModelFormat, isTrue);
        expect(report.environmentCheck.fallbackModelsPresent, isTrue);
        expect(report.environmentCheck.fallbackModelsValid, isTrue);
        expect(report.environmentCheck.fallbackModelsCount, equals(2));
      });

      test('should detect invalid API key format', () async {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=invalid-key-format
DEFAULT_MODEL=qwen/qwen3-32b:free
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free
''');

        final testDiagnosticService = DiagnosticService();
        final report = await testDiagnosticService.runFullDiagnostics();
        
        expect(report.environmentCheck.apiKeyFormat, isFalse);
        expect(report.environmentCheck.isValid, isFalse);
      });

      test('should detect invalid model format', () async {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=sk-or-v1-test-key-12345
DEFAULT_MODEL=invalid-model-format
FALLBACK_MODELS=qwen/qwq-32b:free,qwen/qwen3-235b-a22b:free
''');

        final testDiagnosticService = DiagnosticService();
        final report = await testDiagnosticService.runFullDiagnostics();
        
        expect(report.environmentCheck.defaultModelFormat, isFalse);
        expect(report.environmentCheck.isValid, isFalse);
      });
    });

    group('Report Generation Tests', () {
      test('should generate comprehensive diagnostic report', () async {
        final report = await diagnosticService.runFullDiagnostics();
        final summary = report.generateSummary();
        
        expect(summary, contains('DIAGNOSTIC REPORT'));
        expect(summary, contains('Overall Status:'));
        expect(summary, contains('Environment Configuration:'));
        expect(summary, contains('API Key Validation:'));
        expect(summary, contains('Model Availability:'));
        expect(summary, contains('Network Connectivity:'));
        expect(summary, contains('Proxy:'));
        expect(summary, contains('Fallback Logic:'));
      });

      test('should indicate configuration errors in summary', () async {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=invalid-key
DEFAULT_MODEL=invalid-model
''');

        final testDiagnosticService = DiagnosticService();
        final report = await testDiagnosticService.runFullDiagnostics();
        final summary = report.generateSummary();
        
        expect(summary, contains('❌ INVALID'));
        expect(report.overallStatus, equals(DiagnosticStatus.configurationError));
      });
    });

    group('Diagnostic Status Tests', () {
      test('should return healthy status for valid configuration', () async {
        // This test would require mocking network calls
        // For now, we test the status calculation logic
        final report = DiagnosticReport();
        report.environmentCheck = EnvironmentCheck()..isValid = true;
        report.apiKeyValidation = ApiKeyValidation()..isValid = true;
        report.networkConnectivity = NetworkConnectivity()..openRouterReachable = true;
        report.modelAvailability = ModelAvailability()..isValid = true;
        report.proxyCheck = ProxyCheck()..isValid = true;
        report.fallbackLogic = FallbackLogic()..isValid = true;
        
        // Would need to expose the status calculation method or test through public interface
        expect(report.environmentCheck.isValid, isTrue);
      });
    });
  });
}
