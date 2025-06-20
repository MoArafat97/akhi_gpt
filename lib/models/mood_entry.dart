import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 1)
class MoodEntry extends HiveObject {
  @HiveField(0)
  late String mood;

  @HiveField(1)
  late String duaArabic;

  @HiveField(2)
  late String translit;

  @HiveField(3)
  late String english;

  @HiveField(4)
  late DateTime createdAt;

  // Constructor
  MoodEntry({
    required this.mood,
    required this.duaArabic,
    required this.translit,
    required this.english,
  }) {
    createdAt = DateTime.now();
  }

  // Named constructor with custom date
  MoodEntry.withDate({
    required this.mood,
    required this.duaArabic,
    required this.translit,
    required this.english,
    required DateTime customDate,
  }) {
    createdAt = customDate;
  }

  // Helper method to format date for display
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Helper method to get time string
  String get timeString {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method to get mood emoji
  String get moodEmoji {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joy':
      case 'grateful':
        return '😊';
      case 'sad':
      case 'grief':
      case 'sorrow':
        return '😢';
      case 'anxious':
      case 'worried':
      case 'stress':
        return '😰';
      case 'calm':
      case 'peaceful':
      case 'serene':
        return '😌';
      case 'angry':
      case 'frustrated':
        return '😠';
      case 'hopeful':
      case 'optimistic':
        return '🌟';
      case 'confused':
      case 'uncertain':
        return '😕';
      case 'tired':
      case 'exhausted':
        return '😴';
      case 'excited':
      case 'enthusiastic':
        return '🤩';
      case 'lonely':
      case 'isolated':
        return '😔';
      default:
        return '🤲'; // Duʿāʾ hands
    }
  }

  // Copy method for updates
  MoodEntry copyWith({
    String? mood,
    String? duaArabic,
    String? translit,
    String? english,
    DateTime? createdAt,
  }) {
    return MoodEntry.withDate(
      mood: mood ?? this.mood,
      duaArabic: duaArabic ?? this.duaArabic,
      translit: translit ?? this.translit,
      english: english ?? this.english,
      customDate: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MoodEntry(key: $key, mood: $mood, createdAt: $createdAt, duaArabic: ${duaArabic.length > 30 ? '${duaArabic.substring(0, 30)}...' : duaArabic})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry &&
        other.key == key &&
        other.mood == mood &&
        other.duaArabic == duaArabic &&
        other.translit == translit &&
        other.english == english &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        mood.hashCode ^
        duaArabic.hashCode ^
        translit.hashCode ^
        english.hashCode ^
        createdAt.hashCode;
  }
}
