import 'package:shared_preferences/shared_preferences.dart';

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

  /// Check if gender has been set by the user
  static Future<bool> isGenderSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_genderSetKey) ?? false;
  }

  /// Clear gender preference (for testing or reset)
  static Future<void> clearGender() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_genderSetKey);
  }

  /// Get localization key for gender-specific text
  static String getLocalizedKey(String baseKey, UserGender gender) {
    final suffix = gender == UserGender.male ? 'Brother' : 'Sister';
    return '$baseKey$suffix';
  }
}
