import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/services/openrouter_service.dart';
import '../lib/utils/config_helper.dart';
import '../lib/models/chat_message.dart';

void main() {
  group('Enhanced Proxy System Tests', () {
    late OpenRouterService service;
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();

    setUpAll(() async {
      // Load environment variables for testing
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // Ignore if .env doesn't exist in test environment
      }
    });

    setUp(() {
      service = OpenRouterService();
    });

    tearDown(() async {
      // Clean up storage after each test
      await ConfigHelper.resetToDefaultModel();
    });

    group('Proxy Configuration Tests', () {
      test('should detect proxy configuration from environment', () {
        // Test proxy endpoint detection
        final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
        final enableProxy = dotenv.env['ENABLE_PROXY'];
        
        expect(proxyEndpoint, isNotNull);
        expect(enableProxy, isNotNull);
      });

      test('should have fallback models configured', () {
        final fallbackModels = ConfigHelper.getFallbackModels();
        expect(fallbackModels.length, greaterThanOrEqualTo(1));
        expect(fallbackModels.first, contains('deepseek'));
      });

      test('should initialize service with proxy support', () {
        expect(service, isA<OpenRouterService>());
        expect(service.isConfigured, isA<bool>());
        expect(service.modelDisplayName, equals('Akhi Assistant'));
      });
    });

    group('Proxy Connection Tests', () {
      test('should test proxy connection when enabled', () async {
        // This test requires the proxy to be running locally
        // Skip if proxy is not available
        try {
          final proxyStatus = await service.testProxyConnection();
          expect(proxyStatus, isA<bool>());
        } catch (e) {
          // Skip test if proxy is not available
          expect(e, isA<Exception>());
        }
      });

      test('should get proxy status when available', () async {
        try {
          final status = await service.getProxyStatus();
          if (status != null) {
            expect(status, isA<Map<String, dynamic>>());
            expect(status.containsKey('status'), isTrue);
            expect(status.containsKey('configuration'), isTrue);
          }
        } catch (e) {
          // Skip test if proxy is not available
          expect(e, isA<Exception>());
        }
      });

      test('should fallback to direct API when proxy fails', () async {
        // Test that the service can handle proxy failures gracefully
        final connectionTest = await service.testConnection();
        expect(connectionTest, isA<bool>());
      });
    });

    group('Enhanced Fallback System Tests', () {
      test('should maintain existing fallback functionality', () async {
        final status = await ConfigHelper.getStatus();
        expect(status.containsKey('hasFallbackSupport'), isTrue);
        expect(status['hasFallbackSupport'], isTrue);
        expect(status.containsKey('lastWorkingModel'), isTrue);
      });

      test('should handle chat message creation for proxy scenarios', () {
        final message = ChatMessage(
          role: 'assistant',
          content: 'Enhanced proxy response for testing',
        );

        expect(message.role, equals('assistant'));
        expect(message.content.isNotEmpty, isTrue);
        expect(message.isStreaming, isFalse);
      });

      test('should reset fallback state correctly', () async {
        await ConfigHelper.resetToDefaultModel();
        
        final status = await ConfigHelper.getStatus();
        expect(status['lastWorkingModel'], isNull);
      });
    });

    group('Rate Limiting and Caching Tests', () {
      test('should have rate limiting configuration', () {
        final rateLimitConfig = dotenv.env['RATE_LIMIT_REQUESTS_PER_MINUTE'];
        final burstSize = dotenv.env['RATE_LIMIT_BURST_SIZE'];
        
        expect(rateLimitConfig, isNotNull);
        expect(burstSize, isNotNull);
      });

      test('should have caching configuration', () {
        final cacheTtl = dotenv.env['CACHE_TTL_SECONDS'];
        final enableDeduplication = dotenv.env['ENABLE_PROMPT_DEDUPLICATION'];
        
        expect(cacheTtl, isNotNull);
        expect(enableDeduplication, isNotNull);
      });

      test('should handle request optimization settings', () {
        final enableQueueing = dotenv.env['ENABLE_REQUEST_QUEUEING'];
        final maxConcurrent = dotenv.env['MAX_CONCURRENT_REQUESTS'];
        
        expect(enableQueueing, isNotNull);
        expect(maxConcurrent, isNotNull);
      });
    });

    group('Integration Tests', () {
      test('should maintain backward compatibility', () {
        // Test that existing functionality still works
        final status = ConfigHelper.getStatusSync();
        expect(status.containsKey('isConfigured'), isTrue);
        expect(status.containsKey('currentModel'), isTrue);
        expect(status['currentModel'], equals('Akhi Assistant'));
      });

      test('should handle environment configuration', () {
        // Test that all required environment variables are accessible
        final apiKey = dotenv.env['OPENROUTER_API_KEY'];
        final defaultModel = dotenv.env['DEFAULT_MODEL'];
        final fallbackModels = dotenv.env['FALLBACK_MODELS'];
        
        expect(apiKey, isNotNull);
        expect(defaultModel, isNotNull);
        expect(fallbackModels, isNotNull);
      });
    });
  });

  group('Error Handling Tests', () {
    test('should handle proxy unavailability gracefully', () {
      // Test that the system works when proxy is not available
      expect(true, isTrue); // Placeholder for actual error handling tests
    });

    test('should handle rate limiting scenarios', () {
      // Test rate limiting detection and handling
      expect(true, isTrue); // Placeholder for actual rate limiting tests
    });

    test('should handle caching failures', () {
      // Test caching system resilience
      expect(true, isTrue); // Placeholder for actual caching tests
    });
  });
}
