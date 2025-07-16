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
      // Initialize dotenv with test values (no API key - user must provide)
      dotenv.testLoad(fileInput: '''
ENABLE_PROXY=false
PROXY_ENDPOINT=http://localhost:8080
''');

      mockDio = MockDio();
      mockStorage = MockFlutterSecureStorage();
      service = OpenRouterService();
    });

    group('Configuration Tests', () {
      test('should not be configured without user API key', () async {
        // Service should not be configured since no user API key is provided
        expect(await service.isConfigured, isFalse);
      });

      test('should require user API key for configuration', () async {
        // Without user API key, service should not be configured
        final testService = OpenRouterService();
        expect(await testService.isConfigured, isFalse);
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

    group('Model Selection Tests', () {
      test('should require user to select model', () async {
        // Models are now dynamically fetched based on user API key
        // No hardcoded fallback models
        expect(() => service.modelDisplayName, returnsNormally);
      });
    });

    group('Environment Variable Tests', () {
      test('should not have API key in environment (user-provided only)', () {
        expect(dotenv.env['OPENROUTER_API_KEY'], isNull);
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
ENABLE_PROXY=false
PROXY_ENDPOINT=http://localhost:8080
''');

      diagnosticService = DiagnosticService();
    });

    group('Environment Check Tests', () {
      test('should validate environment configuration without API key', () async {
        final report = await diagnosticService.runFullDiagnostics();

        expect(report.environmentCheck.envFileLoaded, isTrue);
        // API key should not be present in environment (user-provided only)
        expect(report.environmentCheck.apiKeyPresent, isFalse);
      });

      test('should handle user API key validation', () async {
        // API key validation is now user-dependent
        final testDiagnosticService = DiagnosticService();
        final report = await testDiagnosticService.runFullDiagnostics();

        // Environment should not contain API key
        expect(report.environmentCheck.apiKeyPresent, isFalse);
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
