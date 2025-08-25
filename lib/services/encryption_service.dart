import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' hide Key;
import 'package:encrypt/encrypt.dart' as encrypt show Key;
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

/// Service for handling AES-256-GCM encryption of chat data
class EncryptionService {
  static const String _encryptionKeyName = 'chat_encryption_key_v2';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Encrypter? _encrypter;
  static encrypt.Key? _key;

  /// Get or create encryption key from secure storage
  static Future<encrypt.Key> _getEncryptionKey() async {
    if (_key != null) return _key!;

    try {
      final keyString = await _secureStorage.read(key: _encryptionKeyName);

      if (keyString != null) {
        // Decode existing key
        final keyBytes = base64Decode(keyString);
        _key = encrypt.Key(Uint8List.fromList(keyBytes));
      } else {
        // Generate new AES-256 key (32 bytes)
        _key = encrypt.Key.fromSecureRandom(32);
        await _secureStorage.write(
          key: _encryptionKeyName,
          value: base64Encode(_key!.bytes)
        );
        SecureLogger.success('Generated new AES-256 encryption key', name: 'EncryptionService');
      }

      return _key!;
    } catch (e) {
      SecureLogger.error('Error getting encryption key', name: 'EncryptionService', error: e);
      rethrow;
    }
  }

  /// Get or create encrypter instance
  static Future<Encrypter> _getEncrypter() async {
    if (_encrypter != null) return _encrypter!;

    final key = await _getEncryptionKey();
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return _encrypter!;
  }

  /// AES-256-GCM encryption with secure random IV
  static Future<String> encrypt(String plaintext) async {
    try {
      if (plaintext.isEmpty) return plaintext;

      final encrypter = await _getEncrypter();

      // Generate secure random IV (16 bytes for AES)
      final iv = IV.fromSecureRandom(16);

      // Encrypt using AES-256-GCM
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV and encrypted data for storage
      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {
      SecureLogger.error('Encryption error', name: 'EncryptionService', error: e);
      // In case of encryption failure, return original text
      // This ensures app doesn't break if encryption fails
      return plaintext;
    }
  }

  /// AES-256-GCM decryption
  static Future<String> decrypt(String ciphertext) async {
    try {
      if (ciphertext.isEmpty) return ciphertext;

      // Handle legacy XOR-encrypted data (migration support)
      if (!ciphertext.contains(':')) {
        return await _decryptLegacy(ciphertext);
      }

      final encrypter = await _getEncrypter();

      // Split IV and encrypted data
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted data format');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      // Decrypt using AES-256-GCM
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      SecureLogger.error('Decryption error', name: 'EncryptionService', error: e);
      // In case of decryption failure, return original text
      // This ensures app doesn't break if decryption fails
      return ciphertext;
    }
  }

  /// Legacy XOR decryption for backward compatibility
  static Future<String> _decryptLegacy(String ciphertext) async {
    try {
      // This is the old XOR-based decryption for existing data
      // We'll keep this temporarily for migration purposes
      final combined = base64Decode(ciphertext);

      if (combined.length < 12) {
        return ciphertext; // Invalid format, return as-is
      }

      // Extract IV (first 12 bytes) and encrypted data
      final iv = combined.sublist(0, 12);
      final encryptedBytes = combined.sublist(12);

      // Use a simple hash of the old key format for compatibility
      final keyString = await _secureStorage.read(key: 'chat_encryption_key');
      if (keyString == null) {
        return ciphertext; // No legacy key, return as-is
      }

      final keyBytes = base64Decode(keyString);

      // Decrypt using the old XOR logic
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        final keyByte = keyBytes[i % keyBytes.length];
        final ivByte = iv[i % iv.length];
        decryptedBytes.add(encryptedBytes[i] ^ keyByte ^ ivByte);
      }

      final decrypted = utf8.decode(decryptedBytes);
      return decrypted;
    } catch (e) {
      SecureLogger.error('Legacy decryption error', name: 'EncryptionService', error: e);
      return ciphertext;
    }
  }

  /// Check if encryption is enabled in settings
  static Future<bool> isEncryptionEnabled() async {
    try {
      // Use SharedPreferences directly to avoid circular imports
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('encryptChats') ?? true;
    } catch (e) {
      SecureLogger.error('Error checking encryption setting', name: 'EncryptionService', error: e);
      return true; // Default to enabled for security
    }
  }

  /// Encrypt data if encryption is enabled
  static Future<String> encryptIfEnabled(String data) async {
    if (await isEncryptionEnabled()) {
      return await encrypt(data);
    }
    return data;
  }

  /// Decrypt data if it appears to be encrypted
  static Future<String> decryptIfNeeded(String data) async {
    // Check if data looks encrypted (contains ':' for new format or is base64 for legacy)
    if (data.isNotEmpty && (data.contains(':') || RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(data))) {
      try {
        return await decrypt(data);
      } catch (e) {
        // If decryption fails, return original data
        return data;
      }
    }
    return data;
  }

  /// Clear cached encryption instances (useful for testing)
  static void clearCache() {
    _encrypter = null;
    _key = null;
  }


}
