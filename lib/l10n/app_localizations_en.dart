// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Companion GPT';

  @override
  String get greetingBrother => 'Assalamu alaikum, brother!';

  @override
  String get greetingSister => 'Assalamu alaikum, sister!';

  @override
  String get chatWithBrother => 'Chat with Akhi';

  @override
  String get chatWithSister => 'Chat with Ukhti';

  @override
  String get supportiveBrother => 'supportive Muslim brother';

  @override
  String get supportiveSister => 'supportive Muslim sister';

  @override
  String get bigBrother => 'big brother';

  @override
  String get bigSister => 'big sister';

  @override
  String get brotherFallback =>
      'I\'m having some technical difficulties right now, akhi. Please try again in a moment. 🤲';

  @override
  String get sisterFallback =>
      'I\'m having some technical difficulties right now, ukhti. Please try again in a moment. 🤲';

  @override
  String get genderSelectTitle => 'Choose Your Companion';

  @override
  String get genderSelectSubtitle => 'Who would you like to chat with?';

  @override
  String get selectBrother => 'Brother';

  @override
  String get selectSister => 'Sister';

  @override
  String get brotherDescription =>
      'A supportive older brother who understands your journey';

  @override
  String get sisterDescription =>
      'A caring older sister who shares your experiences';
}
