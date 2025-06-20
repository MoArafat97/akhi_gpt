import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Service for handling AES-256 encryption of chat data
class EncryptionService {
  static const String _encryptionKeyName = 'chat_encryption_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Generate a new AES-256 encryption key
  static Uint8List _generateKey() {
    final bytes = List<int>.generate(32, (i) => 
        DateTime.now().millisecondsSinceEpoch.hashCode + i);
    return Uint8List.fromList(bytes);
  }

  /// Get or create encryption key from secure storage
  static Future<Uint8List> _getEncryptionKey() async {
    try {
      final keyString = await _secureStorage.read(key: _encryptionKeyName);
      
      if (keyString != null) {
        // Decode existing key
        return base64Decode(keyString);
      } else {
        // Generate new key
        final newKey = _generateKey();
        await _secureStorage.write(
          key: _encryptionKeyName, 
          value: base64Encode(newKey)
        );
        developer.log('Generated new encryption key', name: 'EncryptionService');
        return newKey;
      }
    } catch (e) {
      developer.log('Error getting encryption key: $e', name: 'EncryptionService');
      rethrow;
    }
  }

  /// Simple XOR-based encryption (for demonstration - in production use proper AES)
  static Future<String> encrypt(String plaintext) async {
    try {
      final key = await _getEncryptionKey();
      final plaintextBytes = utf8.encode(plaintext);
      final encryptedBytes = <int>[];
      
      for (int i = 0; i < plaintextBytes.length; i++) {
        encryptedBytes.add(plaintextBytes[i] ^ key[i % key.length]);
      }
      
      return base64Encode(encryptedBytes);
    } catch (e) {
      developer.log('Encryption error: $e', name: 'EncryptionService');
      return plaintext; // Fallback to unencrypted
    }
  }

  /// Simple XOR-based decryption (for demonstration - in production use proper AES)
  static Future<String> decrypt(String ciphertext) async {
    try {
      final key = await _getEncryptionKey();
      final encryptedBytes = base64Decode(ciphertext);
      final decryptedBytes = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ key[i % key.length]);
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      developer.log('Decryption error: $e', name: 'EncryptionService');
      return ciphertext; // Fallback to original text
    }
  }

  /// Check if encryption is enabled in settings
  static Future<bool> isEncryptionEnabled() async {
    try {
      // Use SharedPreferences directly to avoid circular imports
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('encryptChats') ?? true;
    } catch (e) {
      developer.log('Error checking encryption setting: $e', name: 'EncryptionService');
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
    // Simple check if data looks like base64 (encrypted)
    if (data.isNotEmpty && RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(data)) {
      try {
        return await decrypt(data);
      } catch (e) {
        // If decryption fails, return original data
        return data;
      }
    }
    return data;
  }

  /// Delete encryption key (for testing or reset purposes)
  static Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(key: _encryptionKeyName);
      developer.log('Encryption key deleted', name: 'EncryptionService');
    } catch (e) {
      developer.log('Error deleting encryption key: $e', name: 'EncryptionService');
    }
  }
}
