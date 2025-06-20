import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _prefs = SharedPreferences.getInstance();
final _secure = const FlutterSecureStorage();

Future<bool> getBool(String k, bool d) async =>
  (await _prefs).getBool(k) ?? d;
Future<void> setBool(String k, bool v) async =>
  (await _prefs).setBool(k, v);

Future<double> getDouble(String k, double d) async =>
  (await _prefs).getDouble(k) ?? d;
Future<void> setDouble(String k, double v) async =>
  (await _prefs).setDouble(k, v);

Future<String> getString(String k, String d) async =>
  (await _prefs).getString(k) ?? d;
Future<void> setString(String k, String v) async =>
  (await _prefs).setString(k, v);

Future<String?> getSecure(String k) => _secure.read(key: k);
Future<void> setSecure(String k, String v) => _secure.write(key: k, value: v);

// Developer-only settings (not exposed in UI)
// Example: Daily chat limit - set by developer, not user
// Usage: await setDouble('chatCap', 100); // Set limit to 100 messages/day
// Usage: double limit = await getDouble('chatCap', 50); // Get limit, default 50
