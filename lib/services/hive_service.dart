import 'dart:async';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_history.dart';
import 'encryption_service.dart';

/// Singleton service for managing Hive database operations
/// Provides offline-first local storage for journal entries and anonymous letters
class HiveService {
  static HiveService? _instance;

  static Box<ChatHistory>? _chatBox;

  // Private constructor for singleton pattern
  HiveService._();

  /// Get the singleton instance
  static HiveService get instance {
    _instance ??= HiveService._();
    return _instance!;
  }



  /// Get the chat history box
  Box<ChatHistory> get chatBox {
    if (_chatBox == null || !_chatBox!.isOpen) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return _chatBox!;
  }

  /// Initialize the Hive database
  /// Must be called before using any other methods
  Future<void> init() async {
    try {
      if (_chatBox != null && _chatBox!.isOpen) {
        developer.log('HiveService already initialized', name: 'HiveService');
        return;
      }

      developer.log('Initializing HiveService...', name: 'HiveService');

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();

      // Initialize Hive
      await Hive.initFlutter(dir.path);

      // Register the adapters
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatHistoryAdapter());
      }

      // Open the boxes
      _chatBox = await Hive.openBox<ChatHistory>('chat_history');

      developer.log('HiveService initialized successfully', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize HiveService: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }



  /// Close the database connection
  Future<void> close() async {
    try {
      developer.log('Closing HiveService', name: 'HiveService');

      if (_chatBox != null && _chatBox!.isOpen) {
        await _chatBox!.close();
        _chatBox = null;
      }

      _instance = null;
      developer.log('HiveService closed successfully', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to close HiveService: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  // ========== CHAT HISTORY METHODS ==========

  /// Add a new chat history session
  Future<int> addChatHistory(ChatHistory chatHistory) async {
    try {
      developer.log('Adding chat history: ${chatHistory.sessionId}', name: 'HiveService');

      // Encrypt message contents if encryption is enabled
      final encryptedHistory = await _encryptChatHistory(chatHistory);
      final key = await chatBox.add(encryptedHistory);

      developer.log('Chat history added with key: $key', name: 'HiveService');
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add chat history: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update existing chat history
  Future<void> updateChatHistory(int key, ChatHistory chatHistory) async {
    try {
      developer.log('Updating chat history key: $key', name: 'HiveService');

      // Encrypt message contents if encryption is enabled
      final encryptedHistory = await _encryptChatHistory(chatHistory);
      await chatBox.put(key, encryptedHistory);

      developer.log('Chat history updated successfully', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update chat history: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all chat histories
  Future<List<ChatHistory>> getAllChatHistories() async {
    try {
      developer.log('Fetching all chat histories', name: 'HiveService');

      final histories = chatBox.values.toList();

      // Decrypt message contents if needed while preserving keys
      final decryptedHistories = <ChatHistory>[];
      for (final history in histories) {
        final decrypted = await _decryptChatHistory(history);
        decryptedHistories.add(decrypted);
      }

      // Sort by last updated (newest first)
      decryptedHistories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      developer.log('Found ${decryptedHistories.length} chat histories', name: 'HiveService');
      return decryptedHistories;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch chat histories: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get the most recent chat history (for loading on app startup)
  Future<ChatHistory?> getMostRecentChatHistory() async {
    try {
      developer.log('Fetching most recent chat history', name: 'HiveService');

      if (chatBox.isEmpty) {
        developer.log('No chat histories found', name: 'HiveService');
        return null;
      }

      final histories = chatBox.values.toList();

      // Sort by last updated (newest first)
      histories.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      final mostRecent = histories.first;
      developer.log('Found most recent chat history: ${mostRecent.sessionId}', name: 'HiveService');

      // Decrypt message contents if needed
      return await _decryptChatHistory(mostRecent);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch most recent chat history: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get chat history by session ID (returns original object with key for deletion)
  Future<ChatHistory?> getChatHistoryBySessionId(String sessionId) async {
    try {
      developer.log('Fetching chat history for session: $sessionId', name: 'HiveService');

      final history = chatBox.values
          .where((h) => h.sessionId == sessionId)
          .firstOrNull;

      if (history != null) {
        developer.log('Found chat history for session: $sessionId with key: ${history.key}', name: 'HiveService');
        // Return the original object to preserve the key for deletion operations
        // Note: Content may be encrypted, use getChatHistoryBySessionIdDecrypted for display
        return history;
      } else {
        developer.log('No chat history found for session: $sessionId', name: 'HiveService');
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch chat history by session ID: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get chat history by session ID with decrypted content (for display purposes)
  Future<ChatHistory?> getChatHistoryBySessionIdDecrypted(String sessionId) async {
    try {
      final history = await getChatHistoryBySessionId(sessionId);
      if (history != null) {
        return await _decryptChatHistory(history);
      }
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch decrypted chat history by session ID: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete chat history
  Future<bool> deleteChatHistory(dynamic key) async {
    try {
      developer.log('=== VERBOSE: deleteChatHistory started ===', name: 'HiveService');
      developer.log('VERBOSE: Attempting to delete chat history with key: $key (type: ${key.runtimeType})', name: 'HiveService');
      developer.log('VERBOSE: chatBox is open: ${chatBox.isOpen}', name: 'HiveService');
      developer.log('VERBOSE: chatBox length before deletion: ${chatBox.length}', name: 'HiveService');
      developer.log('VERBOSE: chatBox keys: ${chatBox.keys.toList()}', name: 'HiveService');
      
      final containsKey = chatBox.containsKey(key);
      developer.log('VERBOSE: chatBox.containsKey($key): $containsKey', name: 'HiveService');

      if (containsKey) {
        developer.log('VERBOSE: Key found, proceeding with deletion...', name: 'HiveService');
        await chatBox.delete(key);
        developer.log('VERBOSE: chatBox.delete() completed', name: 'HiveService');
        developer.log('VERBOSE: chatBox length after deletion: ${chatBox.length}', name: 'HiveService');
        developer.log('VERBOSE: chatBox keys after deletion: ${chatBox.keys.toList()}', name: 'HiveService');
        developer.log('Chat history deleted successfully', name: 'HiveService');
        developer.log('=== VERBOSE: deleteChatHistory completed successfully ===', name: 'HiveService');
        return true;
      } else {
        developer.log('VERBOSE: Key not found in chatBox', name: 'HiveService');
        developer.log('Chat history not found for deletion', name: 'HiveService');
        developer.log('=== VERBOSE: deleteChatHistory completed (key not found) ===', name: 'HiveService');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log('VERBOSE: Exception in deleteChatHistory: $e', name: 'HiveService');
      developer.log(
        'Failed to delete chat history: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      developer.log('=== VERBOSE: deleteChatHistory failed with exception ===', name: 'HiveService');
      rethrow;
    }
  }

  /// Delete all chat histories
  Future<void> deleteAllChatHistories() async {
    try {
      developer.log('Deleting all chat histories', name: 'HiveService');

      await chatBox.clear();

      developer.log('All chat histories deleted successfully', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete all chat histories: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get chat histories count
  Future<int> getChatHistoriesCount() async {
    try {
      final count = chatBox.length;
      developer.log('Chat histories count: $count', name: 'HiveService');
      return count;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get chat histories count: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ========== ENCRYPTION HELPER METHODS ==========

  /// Encrypt chat history message contents if encryption is enabled
  Future<ChatHistory> _encryptChatHistory(ChatHistory chatHistory) async {
    try {
      if (!await EncryptionService.isEncryptionEnabled()) {
        return chatHistory; // Return as-is if encryption disabled
      }

      // Create a copy with encrypted message contents
      final encryptedContents = <String>[];
      for (final content in chatHistory.messageContents) {
        final encrypted = await EncryptionService.encrypt(content);
        encryptedContents.add(encrypted);
      }

      // Create new ChatHistory with encrypted contents
      final encryptedHistory = ChatHistory.withDates(
        sessionId: chatHistory.sessionId,
        customCreatedAt: chatHistory.createdAt,
        customLastUpdated: chatHistory.lastUpdated,
        title: chatHistory.title,
      );

      // Manually set the encrypted message data
      encryptedHistory.messageRoles = List.from(chatHistory.messageRoles);
      encryptedHistory.messageContents = encryptedContents;
      encryptedHistory.messageTimestamps = List.from(chatHistory.messageTimestamps);

      return encryptedHistory;
    } catch (e) {
      developer.log('Error encrypting chat history: $e', name: 'HiveService');
      return chatHistory; // Return original on error
    }
  }

  /// Decrypt chat history message contents if they appear to be encrypted
  Future<ChatHistory> _decryptChatHistory(ChatHistory chatHistory) async {
    try {
      // Check if decryption is needed
      bool needsDecryption = false;
      final decryptedContents = <String>[];

      for (final content in chatHistory.messageContents) {
        final decrypted = await EncryptionService.decryptIfNeeded(content);
        decryptedContents.add(decrypted);
        if (decrypted != content) {
          needsDecryption = true;
        }
      }

      // If no decryption was needed, return the original to preserve the key
      if (!needsDecryption) {
        return chatHistory;
      }

      // Modify the original object in place to preserve the key
      chatHistory.messageContents = decryptedContents;

      return chatHistory;
    } catch (e) {
      developer.log('Error decrypting chat history: $e', name: 'HiveService');
      return chatHistory; // Return original on error
    }
  }
}
