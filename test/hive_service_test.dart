import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:akhi_gpt/models/journal_entry.dart';
import 'dart:io';

void main() {
  group('HiveService Integration Tests', () {
    late Box<JournalEntry> testBox;
    late Directory tempDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('hive_test');

      // Initialize Hive with the temporary directory
      Hive.init(tempDir.path);

      // Register the adapter
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(JournalEntryAdapter());
      }
    });

    setUp(() async {
      testBox = await Hive.openBox<JournalEntry>('test_journal_entries');
    });

    tearDown(() async {
      // Clear all entries after each test
      await testBox.clear();
      await testBox.close();
    });

    tearDownAll(() async {
      // Close Hive and clean up
      await Hive.close();

      // Delete the temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should add a journal entry to Hive box', () async {
      final entry = JournalEntry(
        title: 'Test Entry',
        content: 'This is a test entry content.',
        moodTag: 'happy',
      );

      final key = await testBox.add(entry);
      expect(key, isA<int>());
      expect(key, greaterThanOrEqualTo(0));
      expect(testBox.length, equals(1));
    });

    test('should retrieve journal entries from Hive box', () async {
      // Add multiple entries
      final entry1 = JournalEntry(
        title: 'First Entry',
        content: 'First entry content.',
        moodTag: 'happy',
      );

      final entry2 = JournalEntry(
        title: 'Second Entry',
        content: 'Second entry content.',
        moodTag: 'sad',
      );

      await testBox.add(entry1);
      await testBox.add(entry2);

      final entries = testBox.values.toList();
      expect(entries.length, equals(2));
      expect(entries.any((e) => e.title == 'First Entry'), isTrue);
      expect(entries.any((e) => e.title == 'Second Entry'), isTrue);
    });

    test('should delete a journal entry from Hive box', () async {
      final entry = JournalEntry(
        title: 'Entry to Delete',
        content: 'This entry will be deleted.',
        moodTag: 'neutral',
      );

      await testBox.add(entry);
      expect(testBox.length, equals(1));

      // Delete the entry
      await entry.delete();
      expect(testBox.length, equals(0));
    });

    test('should filter entries by mood tag', () async {
      final happyEntry = JournalEntry(
        title: 'Happy Entry',
        content: 'I am feeling happy today!',
        moodTag: 'happy',
      );

      final sadEntry = JournalEntry(
        title: 'Sad Entry',
        content: 'I am feeling sad today.',
        moodTag: 'sad',
      );

      final neutralEntry = JournalEntry(
        title: 'Neutral Entry',
        content: 'Just a regular day.',
        moodTag: null,
      );

      await testBox.add(happyEntry);
      await testBox.add(sadEntry);
      await testBox.add(neutralEntry);

      final happyEntries = testBox.values.where((entry) => entry.moodTag == 'happy').toList();
      expect(happyEntries.length, equals(1));
      expect(happyEntries.first.title, equals('Happy Entry'));

      final sadEntries = testBox.values.where((entry) => entry.moodTag == 'sad').toList();
      expect(sadEntries.length, equals(1));
      expect(sadEntries.first.title, equals('Sad Entry'));
    });

    test('should update a journal entry in Hive box', () async {
      final entry = JournalEntry(
        title: 'Original Title',
        content: 'Original content',
        moodTag: 'happy',
      );

      await testBox.add(entry);

      // Update the entry
      entry.title = 'Updated Title';
      entry.content = 'Updated content';
      entry.moodTag = 'excited';

      await entry.save();

      // Verify the update
      final entries = testBox.values.toList();
      expect(entries.length, equals(1));
      expect(entries.first.title, equals('Updated Title'));
      expect(entries.first.content, equals('Updated content'));
      expect(entries.first.moodTag, equals('excited'));
    });
  });

  group('JournalEntry Model Tests', () {
    test('should create JournalEntry with current date', () {
      final entry = JournalEntry(
        title: 'Test Title',
        content: 'Test Content',
        moodTag: 'happy',
      );

      expect(entry.title, equals('Test Title'));
      expect(entry.content, equals('Test Content'));
      expect(entry.moodTag, equals('happy'));
      expect(entry.date, isA<DateTime>());
    });

    test('should create JournalEntry with custom date', () {
      final customDate = DateTime(2024, 1, 15, 10, 30);
      final entry = JournalEntry.withDate(
        customDate: customDate,
        title: 'Custom Date Entry',
        content: 'Entry with custom date',
      );

      expect(entry.date, equals(customDate));
      expect(entry.title, equals('Custom Date Entry'));
    });

    test('should format date correctly', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final oldDate = DateTime(2024, 1, 15);

      final todayEntry = JournalEntry.withDate(
        customDate: today,
        title: 'Today Entry',
        content: 'Content',
      );

      final yesterdayEntry = JournalEntry.withDate(
        customDate: yesterday,
        title: 'Yesterday Entry',
        content: 'Content',
      );

      final oldEntry = JournalEntry.withDate(
        customDate: oldDate,
        title: 'Old Entry',
        content: 'Content',
      );

      expect(todayEntry.formattedDate, equals('Today'));
      expect(yesterdayEntry.formattedDate, equals('Yesterday'));
      expect(oldEntry.formattedDate, equals('15/1/2024'));
    });

    test('should return correct mood emoji', () {
      final happyEntry = JournalEntry(title: 'Test', content: 'Test', moodTag: 'happy');
      final sadEntry = JournalEntry(title: 'Test', content: 'Test', moodTag: 'sad');
      final unknownEntry = JournalEntry(title: 'Test', content: 'Test', moodTag: 'unknown');
      final nullEntry = JournalEntry(title: 'Test', content: 'Test', moodTag: null);

      expect(happyEntry.moodEmoji, equals('😊'));
      expect(sadEntry.moodEmoji, equals('😢'));
      expect(unknownEntry.moodEmoji, equals('📝'));
      expect(nullEntry.moodEmoji, equals('📝'));
    });

    test('should copy entry with new values', () {
      final original = JournalEntry(
        title: 'Original',
        content: 'Original content',
        moodTag: 'happy',
      );

      final copied = original.copyWith(
        title: 'Copied',
        moodTag: 'sad',
      );

      expect(copied.title, equals('Copied'));
      expect(copied.content, equals('Original content')); // Should remain unchanged
      expect(copied.moodTag, equals('sad'));
    });
  });
}
