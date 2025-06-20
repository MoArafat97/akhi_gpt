import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  String? moodTag; // Optional mood tag (e.g., "happy", "sad", "anxious", etc.)

  // Constructor
  JournalEntry({
    required this.title,
    required this.content,
    this.moodTag,
  }) {
    date = DateTime.now();
  }

  // Named constructor with custom date
  JournalEntry.withDate({
    required DateTime customDate,
    required this.title,
    required this.content,
    this.moodTag,
  }) {
    date = customDate;
  }

  // Helper method to format date for display
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Helper method to get time string
  String get timeString {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method to get mood emoji
  String get moodEmoji {
    switch (moodTag?.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'calm':
        return '😌';
      case 'excited':
        return '🤩';
      case 'angry':
        return '😠';
      case 'grateful':
        return '🙏';
      case 'hopeful':
        return '🌟';
      case 'peaceful':
        return '☮️';
      case 'confused':
        return '😕';
      default:
        return '📝';
    }
  }

  // Copy method for updates
  JournalEntry copyWith({
    DateTime? date,
    String? title,
    String? content,
    String? moodTag,
  }) {
    return JournalEntry.withDate(
      customDate: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      moodTag: moodTag ?? this.moodTag,
    );
  }

  @override
  String toString() {
    return 'JournalEntry(key: $key, date: $date, title: $title, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, moodTag: $moodTag)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.key == key &&
        other.date == date &&
        other.title == title &&
        other.content == content &&
        other.moodTag == moodTag;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        date.hashCode ^
        title.hashCode ^
        content.hashCode ^
        moodTag.hashCode;
  }
}
