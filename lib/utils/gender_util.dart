import 'package:shared_preferences/shared_preferences.dart';
import '../config/personality_config.dart';

/// Enum for personality types within each gender
enum PersonalityType {
  // Male personalities
  brother,
  bro,
  brudda,
  akhi,
  // Female personalities
  sister,
  sis,
  habibi,
  ukhti;

  /// Get display name for the personality
  String get displayName {
    switch (this) {
      case PersonalityType.brother:
        return 'Brother';
      case PersonalityType.bro:
        return 'Bro';
      case PersonalityType.brudda:
        return 'Brudda';
      case PersonalityType.akhi:
        return 'Akhi';
      case PersonalityType.sister:
        return 'Sister';
      case PersonalityType.sis:
        return 'Sis';
      case PersonalityType.habibi:
        return 'Habibi';
      case PersonalityType.ukhti:
        return 'Ukhti';
    }
  }

  /// Get companion name (what the AI calls itself)
  String get companionName {
    switch (this) {
      case PersonalityType.brother:
      case PersonalityType.bro:
      case PersonalityType.brudda:
        return 'Akhi';
      case PersonalityType.akhi:
        return 'Akhi';
      case PersonalityType.sister:
      case PersonalityType.sis:
      case PersonalityType.habibi:
        return 'Ukhti';
      case PersonalityType.ukhti:
        return 'Ukhti';
    }
  }

  /// Get casual address term
  String get casualAddress {
    switch (this) {
      case PersonalityType.brother:
        return 'brother';
      case PersonalityType.bro:
        return 'bro';
      case PersonalityType.brudda:
        return 'brudda';
      case PersonalityType.akhi:
        return 'akhi';
      case PersonalityType.sister:
        return 'sister';
      case PersonalityType.sis:
        return 'sis';
      case PersonalityType.habibi:
        return 'habibi';
      case PersonalityType.ukhti:
        return 'ukhti';
    }
  }

  /// Get formal address term
  String get formalAddress {
    switch (this) {
      case PersonalityType.brother:
      case PersonalityType.bro:
      case PersonalityType.brudda:
      case PersonalityType.akhi:
        return 'brother';
      case PersonalityType.sister:
      case PersonalityType.sis:
      case PersonalityType.habibi:
      case PersonalityType.ukhti:
        return 'sister';
    }
  }

  /// Check if this personality is male-oriented
  bool get isMale {
    switch (this) {
      case PersonalityType.brother:
      case PersonalityType.bro:
      case PersonalityType.brudda:
      case PersonalityType.akhi:
        return true;
      case PersonalityType.sister:
      case PersonalityType.sis:
      case PersonalityType.habibi:
      case PersonalityType.ukhti:
        return false;
    }
  }

  /// Get corresponding UserGender
  UserGender get userGender => isMale ? UserGender.male : UserGender.female;

  /// Get personalities for a specific gender
  static List<PersonalityType> forGender(UserGender gender) {
    switch (gender) {
      case UserGender.male:
        return [PersonalityType.brother, PersonalityType.bro, PersonalityType.brudda, PersonalityType.akhi];
      case UserGender.female:
        return [PersonalityType.sister, PersonalityType.sis, PersonalityType.habibi, PersonalityType.ukhti];
    }
  }

  /// Create enum from string
  static PersonalityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'brother':
        return PersonalityType.brother;
      case 'bro':
        return PersonalityType.bro;
      case 'brudda':
        return PersonalityType.brudda;
      case 'akhi':
        return PersonalityType.akhi;
      case 'sister':
        return PersonalityType.sister;
      case 'sis':
        return PersonalityType.sis;
      case 'habibi':
        return PersonalityType.habibi;
      case 'ukhti':
        return PersonalityType.ukhti;
      default:
        return PersonalityType.brother; // Default fallback
    }
  }

  /// Convert enum to string for storage
  String get value => name;
}

/// Enum for user gender selection
enum UserGender {
  male,
  female;

  /// Convert enum to string for storage
  String get value => name;

  /// Create enum from string
  static UserGender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return UserGender.male; // Default fallback
    }
  }

  /// Get display name for the gender
  String get displayName {
    switch (this) {
      case UserGender.male:
        return 'Brother';
      case UserGender.female:
        return 'Sister';
    }
  }

  /// Get companion name (what the AI calls itself)
  String get companionName {
    switch (this) {
      case UserGender.male:
        return 'Akhi';
      case UserGender.female:
        return 'Ukhti';
    }
  }

  /// Get casual address term
  String get casualAddress {
    switch (this) {
      case UserGender.male:
        return 'akhi';
      case UserGender.female:
        return 'ukhti';
    }
  }

  /// Get formal address term
  String get formalAddress {
    switch (this) {
      case UserGender.male:
        return 'brother';
      case UserGender.female:
        return 'sister';
    }
  }
}

/// Utility class for managing user gender preferences
class GenderUtil {
  static const String _genderKey = 'user_gender';
  static const String _genderSetKey = 'gender_is_set';
  static const String _personalityKey = 'user_personality';
  static const String _displayNameKey = 'user_display_name';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _personalityStyleEnabledKey = 'personality_style_enabled';
  static const String _personalityStyleKey = 'personality_style';

  /// Get the current user gender from storage
  static Future<UserGender> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    final genderString = prefs.getString(_genderKey);

    if (genderString != null) {
      return UserGender.fromString(genderString);
    }

    // Default to male if not set (for backward compatibility)
    return UserGender.male;
  }

  /// Set the user gender in storage
  static Future<void> setUserGender(UserGender gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender.value);
    await prefs.setBool(_genderSetKey, true);
  }

  /// Get the current user personality from storage
  static Future<PersonalityType> getUserPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    final personalityString = prefs.getString(_personalityKey);

    if (personalityString != null) {
      return PersonalityType.fromString(personalityString);
    }

    // Default based on gender for backward compatibility
    final gender = await getUserGender();
    return gender == UserGender.male ? PersonalityType.brother : PersonalityType.sister;
  }

  /// Set the user personality in storage
  static Future<void> setUserPersonality(PersonalityType personality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityKey, personality.value);
    // Also update gender to match personality
    await prefs.setString(_genderKey, personality.userGender.value);
    await prefs.setBool(_genderSetKey, true);
  }

  /// Get the user's display name from storage
  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey);
  }

  /// Set the user's display name in storage
  static Future<void> setDisplayName(String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    // Validate and clean the display name
    final cleanName = displayName.trim();
    if (cleanName.isNotEmpty && cleanName.length <= 30) {
      await prefs.setString(_displayNameKey, cleanName);
    }
  }

  /// Check if gender has been set by the user
  static Future<bool> isGenderSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_genderSetKey) ?? false;
  }

  /// Check if onboarding has been completed (including new pages)
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Check if personality style is enabled
  static Future<bool> isPersonalityStyleEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_personalityStyleEnabledKey) ?? false;
  }

  /// Set personality style enabled/disabled
  static Future<void> setPersonalityStyleEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_personalityStyleEnabledKey, enabled);
  }

  /// Get current personality style
  static Future<PersonalityStyle> getPersonalityStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleString = prefs.getString(_personalityStyleKey);

    if (styleString != null) {
      return PersonalityStyle.fromString(styleString);
    }

    // Default to simple modern
    return PersonalityStyle.simpleModern;
  }

  /// Set personality style
  static Future<void> setPersonalityStyle(PersonalityStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityStyleKey, style.value);
  }

  /// Get effective personality style (considering if it's enabled)
  static Future<PersonalityStyle> getEffectivePersonalityStyle() async {
    final isEnabled = await isPersonalityStyleEnabled();
    if (!isEnabled) {
      return PersonalityStyle.simpleModern;
    }
    return await getPersonalityStyle();
  }

  /// Get companion name based on current settings
  static Future<String> getCompanionName() async {
    final style = await getEffectivePersonalityStyle();
    final gender = await getUserGender();
    return style.getCompanionName(gender == UserGender.male);
  }

  /// Clear all preferences (for testing or reset)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_genderSetKey);
    await prefs.remove(_personalityKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_onboardingCompleteKey);
    await prefs.remove(_personalityStyleEnabledKey);
    await prefs.remove(_personalityStyleKey);
  }

  /// Clear gender preference (for testing or reset) - kept for backward compatibility
  static Future<void> clearGender() async {
    await clearAll();
  }

  /// Get localization key for gender-specific text
  static String getLocalizedKey(String baseKey, UserGender gender) {
    final suffix = gender == UserGender.male ? 'Brother' : 'Sister';
    return '$baseKey$suffix';
  }
}
