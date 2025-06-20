import 'package:hive/hive.dart';

part 'anonymous_letter.g.dart';

@HiveType(typeId: 2)
class AnonymousLetter extends HiveObject {
  @HiveField(0)
  late String text;

  @HiveField(1)
  late DateTime createdAt;

  // Constructor
  AnonymousLetter({
    required this.text,
  }) {
    createdAt = DateTime.now();
  }

  // Named constructor with custom date
  AnonymousLetter.withDate({
    required this.text,
    required DateTime customDate,
  }) {
    createdAt = customDate;
  }

  // Helper method to check if letter should be auto-deleted (24 hours)
  bool get shouldAutoDelete {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours >= 24;
  }

  // Helper method to get remaining time until auto-deletion
  Duration get timeUntilDeletion {
    final now = DateTime.now();
    final deleteTime = createdAt.add(const Duration(hours: 24));
    final remaining = deleteTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Helper method to format remaining time for display
  String get remainingTimeString {
    final remaining = timeUntilDeletion;
    if (remaining == Duration.zero) {
      return 'Expired';
    }
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
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

  // Helper method to get preview text (first 100 characters)
  String get previewText {
    if (text.length <= 100) {
      return text;
    }
    return '${text.substring(0, 100)}...';
  }

  // Copy method for updates
  AnonymousLetter copyWith({
    String? text,
    DateTime? createdAt,
  }) {
    return AnonymousLetter.withDate(
      text: text ?? this.text,
      customDate: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AnonymousLetter(key: $key, createdAt: $createdAt, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnonymousLetter &&
        other.key == key &&
        other.text == text &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        text.hashCode ^
        createdAt.hashCode;
  }
}
