import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UTF-8 Encoding Tests', () {
    test('should properly decode UTF-8 text with Arabic characters', () {
      // Test string with Arabic text and emojis (common in Islamic content)
      const testString = 'Assalamu alaikum أخي 🤲 Allah (SWT) is always with you';
      
      // Convert to bytes and back (simulating the streaming process)
      final bytes = utf8.encode(testString);
      final decoded = utf8.decode(bytes, allowMalformed: true);
      
      expect(decoded, equals(testString));
      expect(decoded.contains('أخي'), isTrue); // Arabic for "my brother"
      expect(decoded.contains('🤲'), isTrue); // Prayer emoji
      expect(decoded.contains('█'), isFalse); // Should not contain block characters
    });

    test('should handle malformed UTF-8 gracefully', () {
      // Test with some invalid UTF-8 bytes
      final invalidBytes = [0xFF, 0xFE, 0x41, 0x42]; // Invalid UTF-8 sequence + "AB"
      
      // Should not throw and should handle gracefully
      expect(() => utf8.decode(invalidBytes, allowMalformed: true), returnsNormally);
      
      final result = utf8.decode(invalidBytes, allowMalformed: true);
      expect(result.contains('AB'), isTrue); // Valid parts should be preserved
      expect(result.contains('█'), isFalse); // Should not contain block characters
    });

    test('should handle streaming chunks correctly', () {
      const fullText = 'This is a test message with emojis 🌟 and Arabic أخي';
      final fullBytes = utf8.encode(fullText);
      
      // Simulate streaming by splitting bytes into chunks
      final chunk1 = fullBytes.sublist(0, 20);
      final chunk2 = fullBytes.sublist(20);
      
      // Decode chunks separately (this might cause issues with naive decoding)
      final decoded1 = utf8.decode(chunk1, allowMalformed: true);
      final decoded2 = utf8.decode(chunk2, allowMalformed: true);
      
      // The combined result should be readable (even if not perfect)
      final combined = decoded1 + decoded2;
      expect(combined.contains('█'), isFalse); // Should not contain block characters
    });

    test('should handle common Islamic phrases correctly', () {
      const phrases = [
        'Bismillah بسم الله',
        'Alhamdulillah الحمد لله',
        'SubhanAllah سبحان الله',
        'Astaghfirullah أستغفر الله',
        'La hawla wa la quwwata illa billah لا حول ولا قوة إلا بالله',
        'Insha\'Allah إن شاء الله',
        'Masha\'Allah ما شاء الله',
        'Barakallahu feek بارك الله فيك',
      ];

      for (final phrase in phrases) {
        final bytes = utf8.encode(phrase);
        final decoded = utf8.decode(bytes, allowMalformed: true);
        
        expect(decoded, equals(phrase));
        expect(decoded.contains('█'), isFalse, reason: 'Block characters found in: $phrase');
      }
    });
  });
}
