import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage Terms and Conditions acceptance status
/// This is a legal compliance requirement and must be implemented as a blocking step
class TermsAcceptanceService {
  static const String _termsAcceptedKey = 'terms_accepted';
  static const String _termsAcceptedDateKey = 'terms_accepted_date';
  static const String _termsVersionKey = 'terms_version';
  
  // Current terms version - increment this when terms are updated to require re-acceptance
  static const String _currentTermsVersion = '1.0.0';

  /// Check if user has accepted the current version of Terms and Conditions
  /// Returns false if terms have never been accepted or if terms version has changed
  static Future<bool> hasAcceptedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAccepted = prefs.getBool(_termsAcceptedKey) ?? false;
      final acceptedVersion = prefs.getString(_termsVersionKey) ?? '';
      
      // User must have accepted terms AND it must be the current version
      return isAccepted && acceptedVersion == _currentTermsVersion;
    } catch (e) {
      // On error, assume terms not accepted for safety
      return false;
    }
  }

  /// Record that user has accepted Terms and Conditions
  /// Stores acceptance status, timestamp, and version
  static Future<void> acceptTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      await prefs.setBool(_termsAcceptedKey, true);
      await prefs.setString(_termsAcceptedDateKey, now.toIso8601String());
      await prefs.setString(_termsVersionKey, _currentTermsVersion);
    } catch (e) {
      // Re-throw to allow caller to handle the error
      throw Exception('Failed to save terms acceptance: $e');
    }
  }

  /// Get the date when terms were accepted (if available)
  static Future<DateTime?> getAcceptanceDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_termsAcceptedDateKey);
      
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the version of terms that was accepted (if available)
  static Future<String?> getAcceptedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_termsVersionKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear terms acceptance (for testing or when terms are updated)
  /// This will force user to accept terms again
  static Future<void> clearAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_termsAcceptedKey);
      await prefs.remove(_termsAcceptedDateKey);
      await prefs.remove(_termsVersionKey);
    } catch (e) {
      throw Exception('Failed to clear terms acceptance: $e');
    }
  }

  /// Check if user needs to accept terms
  /// This is the main method that should be called throughout the app
  static Future<bool> needsToAcceptTerms() async {
    return !(await hasAcceptedTerms());
  }

  /// Get current terms version
  static String getCurrentTermsVersion() {
    return _currentTermsVersion;
  }

  /// Validate that terms acceptance is properly recorded
  /// Returns true if acceptance is valid and complete
  static Future<bool> isAcceptanceValid() async {
    try {
      final hasAccepted = await hasAcceptedTerms();
      final acceptanceDate = await getAcceptanceDate();
      final acceptedVersion = await getAcceptedVersion();
      
      return hasAccepted && 
             acceptanceDate != null && 
             acceptedVersion == _currentTermsVersion;
    } catch (e) {
      return false;
    }
  }

  /// Get acceptance summary for debugging/admin purposes
  static Future<Map<String, dynamic>> getAcceptanceSummary() async {
    try {
      final hasAccepted = await hasAcceptedTerms();
      final acceptanceDate = await getAcceptanceDate();
      final acceptedVersion = await getAcceptedVersion();
      
      return {
        'hasAccepted': hasAccepted,
        'acceptanceDate': acceptanceDate?.toIso8601String(),
        'acceptedVersion': acceptedVersion,
        'currentVersion': _currentTermsVersion,
        'needsAcceptance': await needsToAcceptTerms(),
        'isValid': await isAcceptanceValid(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasAccepted': false,
        'needsAcceptance': true,
        'isValid': false,
      };
    }
  }
}
