import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Companion GPT'**
  String get appTitle;

  /// Greeting for male users
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, brother!'**
  String get greetingBrother;

  /// Greeting for female users
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, sister!'**
  String get greetingSister;

  /// Chat header for male users
  ///
  /// In en, this message translates to:
  /// **'Chat with Akhi'**
  String get chatWithBrother;

  /// Chat header for female users
  ///
  /// In en, this message translates to:
  /// **'Chat with Ukhti'**
  String get chatWithSister;

  /// Description for male persona
  ///
  /// In en, this message translates to:
  /// **'supportive Muslim brother'**
  String get supportiveBrother;

  /// Description for female persona
  ///
  /// In en, this message translates to:
  /// **'supportive Muslim sister'**
  String get supportiveSister;

  /// Big brother reference for male users
  ///
  /// In en, this message translates to:
  /// **'big brother'**
  String get bigBrother;

  /// Big sister reference for female users
  ///
  /// In en, this message translates to:
  /// **'big sister'**
  String get bigSister;

  /// Fallback message for male users
  ///
  /// In en, this message translates to:
  /// **'I\'m having some technical difficulties right now, akhi. Please try again in a moment. 🤲'**
  String get brotherFallback;

  /// Fallback message for female users
  ///
  /// In en, this message translates to:
  /// **'I\'m having some technical difficulties right now, ukhti. Please try again in a moment. 🤲'**
  String get sisterFallback;

  /// Title for gender selection page
  ///
  /// In en, this message translates to:
  /// **'Choose Your Companion'**
  String get genderSelectTitle;

  /// Subtitle for gender selection page
  ///
  /// In en, this message translates to:
  /// **'Who would you like to chat with?'**
  String get genderSelectSubtitle;

  /// Button text to select male companion
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get selectBrother;

  /// Button text to select female companion
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get selectSister;

  /// Description for male companion option
  ///
  /// In en, this message translates to:
  /// **'A supportive older brother who understands your journey'**
  String get brotherDescription;

  /// Description for female companion option
  ///
  /// In en, this message translates to:
  /// **'A caring older sister who shares your experiences'**
  String get sisterDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
