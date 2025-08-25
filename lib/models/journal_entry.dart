/*
// Feature removed: Journal entries. Commented out to prevent analyzer errors.
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

  JournalEntry({
    required this.title,
    required this.content,
  }) {
    date = DateTime.now();
  }

  JournalEntry.withDate({
    required DateTime customDate,
    required this.title,
    required this.content,
  }) {
    date = customDate;
  }
}
*/
