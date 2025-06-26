import 'dart:async';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/anonymous_letter.dart';
import '../models/chat_history.dart';
import 'encryption_service.dart';

/// Singleton service for managing Hive database operations
/// Provides offline-first local storage for journal entries, mood entries, and anonymous letters
class HiveService {
  static HiveService? _instance;
  static Box<JournalEntry>? _journalBox;
  static Box<MoodEntry>? _moodsBox;
  static Box<AnonymousLetter>? _lettersBox;
  static Box<ChatHistory>? _chatBox;

  // Private constructor for singleton pattern
  HiveService._();

  /// Get the singleton instance
  static HiveService get instance {
    _instance ??= HiveService._();
    return _instance!;
  }

  /// Get the journal box
  Box<JournalEntry> get journalBox {
    if (_journalBox == null || !_journalBox!.isOpen) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return _journalBox!;
  }

  /// Get the moods box
  Box<MoodEntry> get moodsBox {
    if (_moodsBox == null || !_moodsBox!.isOpen) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return _moodsBox!;
  }

  /// Get the letters box
  Box<AnonymousLetter> get lettersBox {
    if (_lettersBox == null || !_lettersBox!.isOpen) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return _lettersBox!;
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
      if (_journalBox != null && _journalBox!.isOpen &&
          _moodsBox != null && _moodsBox!.isOpen &&
          _lettersBox != null && _lettersBox!.isOpen &&
          _chatBox != null && _chatBox!.isOpen) {
        developer.log('HiveService already initialized', name: 'HiveService');
        return;
      }

      developer.log('Initializing HiveService...', name: 'HiveService');

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();

      // Initialize Hive
      await Hive.initFlutter(dir.path);

      // Register the adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(JournalEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MoodEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AnonymousLetterAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatHistoryAdapter());
      }

      // Open the boxes
      _journalBox = await Hive.openBox<JournalEntry>('journal_entries');
      _moodsBox = await Hive.openBox<MoodEntry>('moods');
      _lettersBox = await Hive.openBox<AnonymousLetter>('letters');
      _chatBox = await Hive.openBox<ChatHistory>('chat_history');

      // Purge old letters on startup
      await purgeOldLetters();

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

  /// Add a new journal entry
  Future<int> addEntry(JournalEntry entry) async {
    try {
      developer.log('Adding journal entry: ${entry.title}', name: 'HiveService');

      final key = await journalBox.add(entry);

      developer.log('Journal entry added with key: $key', name: 'HiveService');
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add journal entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all journal entries, sorted by date (newest first)
  Future<List<JournalEntry>> getAllEntries() async {
    try {
      developer.log('Fetching all journal entries', name: 'HiveService');

      final entries = journalBox.values.toList();
      
      // Sort by date (newest first)
      entries.sort((a, b) => b.date.compareTo(a.date));

      developer.log('Found ${entries.length} journal entries', name: 'HiveService');
      return entries;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch journal entries: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get entries for a specific date range
  Future<List<JournalEntry>> getEntriesInDateRange(DateTime start, DateTime end) async {
    try {
      developer.log('Fetching entries from $start to $end', name: 'HiveService');

      final entries = journalBox.values
          .where((entry) => 
              entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
              entry.date.isBefore(end.add(const Duration(days: 1))))
          .toList();

      // Sort by date (newest first)
      entries.sort((a, b) => b.date.compareTo(a.date));

      developer.log('Found ${entries.length} entries in date range', name: 'HiveService');
      return entries;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch entries in date range: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get entries by mood tag
  Future<List<JournalEntry>> getEntriesByMood(String moodTag) async {
    try {
      developer.log('Fetching entries with mood: $moodTag', name: 'HiveService');

      final entries = journalBox.values
          .where((entry) => entry.moodTag == moodTag)
          .toList();

      // Sort by date (newest first)
      entries.sort((a, b) => b.date.compareTo(a.date));

      developer.log('Found ${entries.length} entries with mood: $moodTag', name: 'HiveService');
      return entries;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch entries by mood: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      developer.log('Updating journal entry key: ${entry.key}', name: 'HiveService');

      await entry.save();

      developer.log('Journal entry updated successfully', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update journal entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a journal entry by key
  Future<bool> deleteEntry(dynamic key) async {
    try {
      developer.log('Deleting journal entry key: $key', name: 'HiveService');

      if (journalBox.containsKey(key)) {
        await journalBox.delete(key);
        developer.log('Journal entry deleted successfully', name: 'HiveService');
        return true;
      } else {
        developer.log('Journal entry not found for deletion', name: 'HiveService');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete journal entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a journal entry object
  Future<bool> deleteEntryObject(JournalEntry entry) async {
    try {
      developer.log('Deleting journal entry: ${entry.title}', name: 'HiveService');

      await entry.delete();
      developer.log('Journal entry deleted successfully', name: 'HiveService');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete journal entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get the total count of journal entries
  Future<int> getEntryCount() async {
    try {
      final count = journalBox.length;
      developer.log('Total journal entries: $count', name: 'HiveService');
      return count;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get entry count: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Watch for changes in journal entries (reactive updates)
  Stream<BoxEvent> watchAllEntries() {
    try {
      developer.log('Setting up watch stream for journal entries', name: 'HiveService');

      return journalBox.watch();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to setup watch stream: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clear all journal entries (for testing or reset purposes)
  Future<void> clearAllEntries() async {
    try {
      developer.log('Clearing all journal entries', name: 'HiveService');

      await journalBox.clear();

      developer.log('All journal entries cleared', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to clear journal entries: $e',
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

      if (_journalBox != null && _journalBox!.isOpen) {
        await _journalBox!.close();
        _journalBox = null;
      }

      if (_moodsBox != null && _moodsBox!.isOpen) {
        await _moodsBox!.close();
        _moodsBox = null;
      }

      if (_lettersBox != null && _lettersBox!.isOpen) {
        await _lettersBox!.close();
        _lettersBox = null;
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

  // ========== MOOD ENTRY METHODS ==========

  /// Add a new mood entry
  Future<int> addMoodEntry(MoodEntry entry) async {
    try {
      developer.log('Adding mood entry: ${entry.mood}', name: 'HiveService');

      final key = await moodsBox.add(entry);

      developer.log('Mood entry added with key: $key', name: 'HiveService');
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add mood entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all mood entries, sorted by date (newest first)
  Future<List<MoodEntry>> getMoodEntries() async {
    try {
      developer.log('Fetching all mood entries', name: 'HiveService');

      final entries = moodsBox.values.toList();

      // Sort by date (newest first)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      developer.log('Found ${entries.length} mood entries', name: 'HiveService');
      return entries;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch mood entries: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a mood entry
  Future<bool> deleteMoodEntry(dynamic key) async {
    try {
      developer.log('Deleting mood entry key: $key', name: 'HiveService');

      if (moodsBox.containsKey(key)) {
        await moodsBox.delete(key);
        developer.log('Mood entry deleted successfully', name: 'HiveService');
        return true;
      } else {
        developer.log('Mood entry not found for deletion', name: 'HiveService');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete mood entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a mood entry object
  Future<bool> deleteMoodEntryObject(MoodEntry entry) async {
    try {
      developer.log('Deleting mood entry: ${entry.mood}', name: 'HiveService');

      await entry.delete();
      developer.log('Mood entry deleted successfully', name: 'HiveService');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete mood entry: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ========== ANONYMOUS LETTER METHODS ==========

  /// Add a new anonymous letter
  Future<int> addLetter(AnonymousLetter letter) async {
    try {
      developer.log('Adding anonymous letter', name: 'HiveService');

      final key = await lettersBox.add(letter);

      developer.log('Anonymous letter added with key: $key', name: 'HiveService');
      return key;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add anonymous letter: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all active letters (not expired)
  Future<List<AnonymousLetter>> getActiveLetters() async {
    try {
      developer.log('Fetching active anonymous letters', name: 'HiveService');

      final letters = lettersBox.values
          .where((letter) => !letter.shouldAutoDelete)
          .toList();

      // Sort by date (newest first)
      letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      developer.log('Found ${letters.length} active letters', name: 'HiveService');
      return letters;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch active letters: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Purge old letters (24+ hours old)
  Future<void> purgeOldLetters() async {
    try {
      developer.log('Purging old anonymous letters', name: 'HiveService');

      final expiredLetters = lettersBox.values
          .where((letter) => letter.shouldAutoDelete)
          .toList();

      for (final letter in expiredLetters) {
        await letter.delete();
      }

      developer.log('Purged ${expiredLetters.length} expired letters', name: 'HiveService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to purge old letters: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a letter
  Future<bool> deleteLetter(dynamic key) async {
    try {
      developer.log('Deleting anonymous letter key: $key', name: 'HiveService');

      if (lettersBox.containsKey(key)) {
        await lettersBox.delete(key);
        developer.log('Anonymous letter deleted successfully', name: 'HiveService');
        return true;
      } else {
        developer.log('Anonymous letter not found for deletion', name: 'HiveService');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete anonymous letter: $e',
        name: 'HiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a letter object
  Future<bool> deleteLetterObject(AnonymousLetter letter) async {
    try {
      developer.log('Deleting anonymous letter', name: 'HiveService');

      await letter.delete();
      developer.log('Anonymous letter deleted successfully', name: 'HiveService');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete anonymous letter: $e',
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

      // Decrypt message contents if needed
      final decryptedHistories = <ChatHistory>[];
      for (final history in histories) {
        decryptedHistories.add(await _decryptChatHistory(history));
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

      // Create new ChatHistory with decrypted contents
      final decryptedHistory = ChatHistory.withDates(
        sessionId: chatHistory.sessionId,
        customCreatedAt: chatHistory.createdAt,
        customLastUpdated: chatHistory.lastUpdated,
        title: chatHistory.title,
      );

      // Manually set the decrypted message data
      decryptedHistory.messageRoles = List.from(chatHistory.messageRoles);
      decryptedHistory.messageContents = decryptedContents;
      decryptedHistory.messageTimestamps = List.from(chatHistory.messageTimestamps);

      return decryptedHistory;
    } catch (e) {
      developer.log('Error decrypting chat history: $e', name: 'HiveService');
      return chatHistory; // Return original on error
    }
  }
}
