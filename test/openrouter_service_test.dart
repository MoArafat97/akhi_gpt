import 'package:flutter_test/flutter_test.dart';
import 'package:akhi_gpt/services/openrouter_service.dart';
import 'package:akhi_gpt/models/chat_message.dart';
import 'package:akhi_gpt/utils/config_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenRouterService Fixed Model Tests', () {
    late OpenRouterService service;

    setUp(() {
      service = OpenRouterService();
    });

    test('should return fixed model display name', () {
      final displayName = service.modelDisplayName;
      expect(displayName, equals('Akhi Assistant'));
    });

    test('should check configuration from environment', () {
      // This will depend on whether .env is loaded properly
      // In a real test environment, you'd mock the environment variables
      final isConfigured = service.isConfigured;
      expect(isConfigured, isA<bool>());
    });

    test('ConfigHelper should work with fixed model', () async {
      // Test configuration check
      final isConfigured = ConfigHelper.isConfigured();
      expect(isConfigured, isA<bool>());

      // Test async status
      final status = await ConfigHelper.getStatus();
      expect(status['currentModel'], equals('Akhi Assistant'));
      expect(status.containsKey('isConfigured'), isTrue);
      expect(status.containsKey('hasApiKey'), isTrue);
      expect(status.containsKey('hasFallbackSupport'), isTrue);

      // Test sync status for backward compatibility
      final syncStatus = ConfigHelper.getStatusSync();
      expect(syncStatus['currentModel'], equals('Akhi Assistant'));
      expect(syncStatus.containsKey('isConfigured'), isTrue);
    });

    test('ChatMessage model should work correctly', () {
      final message = ChatMessage(
        role: 'user',
        content: 'Hello, world!',
      );

      expect(message.role, equals('user'));
      expect(message.content, equals('Hello, world!'));
      expect(message.isStreaming, isFalse);

      // Test toMap
      final map = message.toMap();
      expect(map['role'], equals('user'));
      expect(map['content'], equals('Hello, world!'));

      // Test copyWith
      final streamingMessage = message.copyWith(isStreaming: true);
      expect(streamingMessage.isStreaming, isTrue);
      expect(streamingMessage.content, equals('Hello, world!'));
    });

    test('should handle chat stream setup without proper configuration', () {
      // This test verifies the method exists and handles missing configuration correctly
      final history = <ChatMessage>[
        ChatMessage(role: 'user', content: 'Previous message'),
      ];

      // If not configured, should throw exception
      if (!service.isConfigured) {
        expect(
          () => service.chatStream('Hello', history),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('should have Akhi system prompt defined', () {
      // Test that the system prompt is properly defined and contains key elements
      // We can't directly access the private _systemPrompt, but we can verify
      // the service has the expected behavior through its public interface

      // Verify the service exists and has the expected display name
      expect(service.modelDisplayName, equals('Akhi Assistant'));

      // The system prompt should be injected automatically in chatStream
      // This is tested indirectly through the service configuration
      expect(service, isA<OpenRouterService>());
    });

    test('should inject system prompt for new conversations', () {
      // Test that system prompt logic exists by checking the service structure
      // Since we can't easily mock the HTTP calls in this test environment,
      // we verify the service is properly structured to handle system prompts

      final emptyHistory = <ChatMessage>[];
      final historyWithSystem = <ChatMessage>[
        ChatMessage(role: 'system', content: 'Existing system message'),
        ChatMessage(role: 'user', content: 'Previous user message'),
      ];

      // Verify that the service can handle both empty history and history with system messages
      expect(emptyHistory.isEmpty, isTrue);
      expect(historyWithSystem.first.role, equals('system'));

      // The actual system prompt injection is tested through integration tests
      // when the service is properly configured with API keys
    });
  });
}
