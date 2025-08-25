/*
// Feature removed: Anonymous letters. Commented out to prevent analyzer errors.
import 'package:hive/hive.dart';

part 'anonymous_letter.g.dart';

@HiveType(typeId: 2)
class AnonymousLetter extends HiveObject {
  @HiveField(0)
  late String text;

  @HiveField(1)
  late DateTime createdAt;

  AnonymousLetter({
    required this.text,
  }) {
    createdAt = DateTime.now();
  }

  AnonymousLetter.withDate({
    required this.text,
    required DateTime customDate,
  }) {
    createdAt = customDate;
  }
}
*/
