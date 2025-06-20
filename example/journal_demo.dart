import 'package:hive/hive.dart';
import '../lib/models/journal_entry.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// Demo script to test journal functionality
/// Run with: dart run example/journal_demo.dart
void main() async {

  print('🚀 Starting Akhi GPT Journal Demo...\n');

  Box<JournalEntry>? journalBox;

  try {
    // Initialize Hive database directly
    print('📦 Initializing Hive database...');
    final tempDir = await Directory.systemTemp.createTemp('journal_demo');
    Hive.init(tempDir.path);

    // Register the adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }

    journalBox = await Hive.openBox<JournalEntry>('journal_entries');
    print('✅ Hive database initialized successfully!\n');
    
    // Demo: Add sample journal entries
    print('📝 Adding sample journal entries...');
    await addSampleEntries(journalBox);

    // Demo: Display all entries
    print('\n📖 Displaying all journal entries:');
    await displayAllEntries(journalBox);

    // Demo: Filter by mood
    print('\n😊 Filtering entries by mood (happy):');
    await filterByMood(journalBox, 'happy');

    // Demo: Get entry count
    print('\n📊 Getting entry statistics:');
    await getEntryStats(journalBox);

    // Demo: Update an entry
    print('\n✏️ Updating an entry:');
    await updateEntry(journalBox);

    // Demo: Delete an entry
    print('\n🗑️ Deleting an entry:');
    await deleteEntry(journalBox);

    // Final stats
    print('\n📊 Final statistics:');
    await getEntryStats(journalBox);
    
    print('\n🎉 Demo completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Demo failed: $e');
    developer.log('Demo error', error: e, stackTrace: stackTrace);
  } finally {
    // Clean up
    if (journalBox != null) {
      await journalBox.close();
    }
    await Hive.close();
    print('🔒 Database closed.');
  }
}

Future<void> addSampleEntries(Box<JournalEntry> journalBox) async {
  
  final entries = [
    JournalEntry(
      title: 'Morning Reflection',
      content: 'Started my day with gratitude and prayer. Feeling blessed and ready to tackle the challenges ahead.',
      moodTag: 'grateful',
    ),
    JournalEntry(
      title: 'Work Stress',
      content: 'Had a difficult day at work. Deadlines are piling up and I feel overwhelmed. Need to remember to take breaks and trust in Allah\'s plan.',
      moodTag: 'anxious',
    ),
    JournalEntry(
      title: 'Family Time',
      content: 'Spent quality time with family today. We shared stories, laughed together, and I felt so connected. These moments are precious.',
      moodTag: 'happy',
    ),
    JournalEntry(
      title: 'Evening Prayer',
      content: 'Found peace in my evening prayers. Reflected on the day and asked for guidance. Feeling more centered now.',
      moodTag: 'peaceful',
    ),
    JournalEntry(
      title: 'Learning Journey',
      content: 'Learned something new today about Flutter development. It\'s amazing how much there is to discover. Excited to keep growing.',
      moodTag: 'excited',
    ),
  ];
  
  for (final entry in entries) {
    final key = await journalBox.add(entry);
    print('  ✓ Added: "${entry.title}" (Key: $key)');
  }
}

Future<void> displayAllEntries(Box<JournalEntry> journalBox) async {
  final entries = journalBox.values.toList();
  // Sort by date (newest first)
  entries.sort((a, b) => b.date.compareTo(a.date));
  
  if (entries.isEmpty) {
    print('  📭 No entries found.');
    return;
  }
  
  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    print('  ${i + 1}. ${entry.moodEmoji} "${entry.title}"');
    print('     📅 ${entry.formattedDate} at ${entry.timeString}');
    print('     💭 ${entry.content.length > 80 ? '${entry.content.substring(0, 80)}...' : entry.content}');
    if (entry.moodTag != null) {
      print('     🎭 Mood: ${entry.moodTag}');
    }
    print('');
  }
}

Future<void> filterByMood(Box<JournalEntry> journalBox, String mood) async {
  final entries = journalBox.values.where((entry) => entry.moodTag == mood).toList();
  
  print('  Found ${entries.length} entries with mood "$mood":');
  for (final entry in entries) {
    print('    • ${entry.moodEmoji} "${entry.title}"');
  }
}

Future<void> getEntryStats(Box<JournalEntry> journalBox) async {
  final count = journalBox.length;
  final entries = journalBox.values.toList();
  
  print('  📊 Total entries: $count');
  
  if (entries.isNotEmpty) {
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      if (entry.moodTag != null) {
        moodCounts[entry.moodTag!] = (moodCounts[entry.moodTag!] ?? 0) + 1;
      }
    }
    
    if (moodCounts.isNotEmpty) {
      print('  🎭 Mood breakdown:');
      moodCounts.forEach((mood, count) {
        print('     $mood: $count entries');
      });
    }
  }
}

Future<void> updateEntry(Box<JournalEntry> journalBox) async {
  final entries = journalBox.values.toList();
  
  if (entries.isEmpty) {
    print('  ❌ No entries to update.');
    return;
  }
  
  final entryToUpdate = entries.first;
  final originalTitle = entryToUpdate.title;
  
  entryToUpdate.title = '${entryToUpdate.title} (Updated)';
  entryToUpdate.content = '${entryToUpdate.content}\n\n[Updated with additional thoughts]';

  await entryToUpdate.save();
  print('  ✓ Updated entry: "$originalTitle" → "${entryToUpdate.title}"');
}

Future<void> deleteEntry(Box<JournalEntry> journalBox) async {
  final entries = journalBox.values.toList();
  
  if (entries.isEmpty) {
    print('  ❌ No entries to delete.');
    return;
  }
  
  final entryToDelete = entries.last;
  final title = entryToDelete.title;
  
  await entryToDelete.delete();
  print('  ✓ Deleted entry: "$title"');
}
