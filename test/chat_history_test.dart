import 'package:flutter_test/flutter_test.dart';
import 'package:akhi_gpt/models/chat_message.dart';
import 'package:akhi_gpt/models/chat_history.dart';

void main() {
  group('ChatHistory Tests', () {
    test('should create chat history with messages', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
        title: 'Test Chat',
      );

      expect(history.sessionId, equals('test_session'));
      expect(history.title, equals('Test Chat'));
      expect(history.messageCount, equals(2));
      expect(history.messages.length, equals(2));
      expect(history.messages[0].role, equals('user'));
      expect(history.messages[1].role, equals('assistant'));
    });

    test('should generate preview from first user message', () {
      final messages = [
        ChatMessage(role: 'system', content: 'System prompt'),
        ChatMessage(role: 'user', content: 'This is a test message'),
        ChatMessage(role: 'assistant', content: 'Response'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
      );

      expect(history.preview, equals('This is a test message'));
    });

    test('should truncate long preview', () {
      final messages = [
        ChatMessage(role: 'user', content: 'This is a very long message that should be truncated because it exceeds the preview limit'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
      );

      expect(history.preview.length, lessThanOrEqualTo(53)); // 50 chars + "..."
      expect(history.preview.endsWith('...'), isTrue);
    });

    test('should use title as preview if available', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Some message'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
        title: 'Custom Title',
      );

      expect(history.preview, equals('Custom Title'));
    });

    test('should export to JSON correctly', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi!'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
        title: 'Test Chat',
      );

      final json = history.toJson();

      expect(json['sessionId'], equals('test_session'));
      expect(json['title'], equals('Test Chat'));
      expect(json['messageCount'], equals(2));
      expect(json['messages'], isA<List>());
      expect(json['messages'].length, equals(2));
    });

    test('should export to plain text correctly', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
        title: 'Test Chat',
      );

      final text = history.toPlainText();

      expect(text.contains('Test Chat'), isTrue);
      expect(text.contains('[You]'), isTrue);
      expect(text.contains('[Akhi]'), isTrue);
      expect(text.contains('Hello'), isTrue);
      expect(text.contains('Hi there!'), isTrue);
    });

    test('should export to markdown correctly', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
        title: 'Test Chat',
      );

      final markdown = history.toMarkdown();

      expect(markdown.contains('# Chat Session: Test Chat'), isTrue);
      expect(markdown.contains('## You'), isTrue);
      expect(markdown.contains('## Akhi'), isTrue);
      expect(markdown.contains('Hello'), isTrue);
      expect(markdown.contains('Hi there!'), isTrue);
    });

    test('should update messages correctly', () {
      final initialMessages = [
        ChatMessage(role: 'user', content: 'Hello'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: initialMessages,
      );

      expect(history.messageCount, equals(1));

      final updatedMessages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
      ];

      history.updateMessages(updatedMessages);

      expect(history.messageCount, equals(2));
      expect(history.messages[1].content, equals('Hi there!'));
    });

    test('should detect if conversation is from today', () {
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
      ];

      final history = ChatHistory(
        sessionId: 'test_session',
        messages: messages,
      );

      expect(history.isToday, isTrue);
    });
  });
}
