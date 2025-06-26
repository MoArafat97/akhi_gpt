import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akhi_gpt/models/chat_history.dart';
import 'package:akhi_gpt/models/chat_message.dart';
import 'dart:io';

void main() {
  group('Chat Deletion Tests', () {
    late Box<ChatHistory> chatBox;
    late Directory tempDir;

    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('chat_deletion_test');

      // Initialize Hive with the temporary directory
      Hive.init(tempDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatHistoryAdapter());
      }
    });

    setUp(() async {
      // Open a fresh chat box for each test
      chatBox = await Hive.openBox<ChatHistory>('test_chat_history');
    });

    tearDown(() async {
      // Clear and close the box after each test
      await chatBox.clear();
      await chatBox.close();
    });

    tearDownAll(() async {
      // Close Hive and clean up
      await Hive.close();

      // Delete the temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should delete chat history by session ID correctly', () async {
      // Create test messages
      final messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
        ChatMessage(role: 'user', content: 'How are you?'),
        ChatMessage(role: 'assistant', content: 'I am doing well, thank you!'),
      ];

      // Create chat history
      final chatHistory = ChatHistory(
        sessionId: 'test_session_123',
        messages: messages,
        title: 'Test Chat for Deletion',
      );

      // Add chat history to storage
      final key = await chatBox.add(chatHistory);
      expect(key, isA<int>());

      // Verify it was added
      expect(chatBox.length, equals(1));

      // Get the chat history by session ID (simulate getChatHistoryBySessionId)
      final retrievedHistory = chatBox.values
          .where((h) => h.sessionId == 'test_session_123')
          .firstOrNull;

      expect(retrievedHistory, isNotNull);
      expect(retrievedHistory!.sessionId, equals('test_session_123'));
      expect(retrievedHistory.key, isNotNull);
      expect(retrievedHistory.key, equals(key));

      // Delete the chat history using the key from the retrieved history
      // This simulates the deleteChatHistory method
      final containsKey = chatBox.containsKey(retrievedHistory.key);
      expect(containsKey, isTrue);

      await chatBox.delete(retrievedHistory.key);

      // Verify it was deleted
      expect(chatBox.length, equals(0));

      // Verify we can't find it anymore
      final deletedHistory = chatBox.values
          .where((h) => h.sessionId == 'test_session_123')
          .firstOrNull;
      expect(deletedHistory, isNull);
    });

    test('should handle deletion of non-existent chat history', () async {
      // Try to delete a chat history that doesn't exist
      final containsKey = chatBox.containsKey(999);
      expect(containsKey, isFalse);
    });

    test('should preserve key when retrieving chat history for deletion', () async {
      // Create test messages
      final messages = [
        ChatMessage(role: 'user', content: 'Test message'),
        ChatMessage(role: 'assistant', content: 'Test response'),
      ];

      // Create chat history
      final chatHistory = ChatHistory(
        sessionId: 'key_preservation_test',
        messages: messages,
      );

      // Add to storage
      final originalKey = await chatBox.add(chatHistory);

      // Retrieve by session ID (simulate getChatHistoryBySessionId)
      final retrieved = chatBox.values
          .where((h) => h.sessionId == 'key_preservation_test')
          .firstOrNull;

      // Verify the key is preserved
      expect(retrieved, isNotNull);
      expect(retrieved!.key, equals(originalKey));
      expect(retrieved.key, isNotNull);

      // Verify we can delete using this key
      final containsKey = chatBox.containsKey(retrieved.key);
      expect(containsKey, isTrue);

      await chatBox.delete(retrieved.key);
      expect(chatBox.length, equals(0));
    });

    test('should simulate the chat screen deletion workflow', () async {
      // This test simulates the exact workflow from the chat screen

      // Step 1: Create and save a chat session (like when user sends messages)
      final messages = [
        ChatMessage(role: 'user', content: 'Hello Akhi'),
        ChatMessage(role: 'assistant', content: 'Wa alaykum salaam! How can I help you today?'),
      ];

      final sessionId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final chatHistory = ChatHistory(
        sessionId: sessionId,
        messages: messages,
        title: 'Chat with Akhi',
      );

      await chatBox.add(chatHistory);

      // Step 2: Simulate loading the most recent chat (like on app startup)
      final histories = chatBox.values.toList();
      histories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      final loadedHistory = histories.isNotEmpty ? histories.first : null;

      expect(loadedHistory, isNotNull);
      expect(loadedHistory!.messages.length, equals(2));

      // Step 3: Simulate the deletion process from _clearChat method
      // This is the critical part - finding the history by session ID with key preserved
      final existingHistory = chatBox.values
          .where((h) => h.sessionId == sessionId)
          .firstOrNull;

      expect(existingHistory, isNotNull);
      expect(existingHistory!.key, isNotNull);

      // Step 4: Delete the chat history using the preserved key
      final containsKey = chatBox.containsKey(existingHistory.key);
      expect(containsKey, isTrue);

      await chatBox.delete(existingHistory.key);

      // Step 5: Verify the chat is completely gone
      expect(chatBox.length, equals(0));

      // Step 6: Simulate trying to load chat history again (like when user returns to chat)
      final shouldBeEmpty = chatBox.values.toList();
      expect(shouldBeEmpty, isEmpty);
    });
  });
}
