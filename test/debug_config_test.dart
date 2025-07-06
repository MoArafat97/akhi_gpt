import 'package:flutter_test/flutter_test.dart';
import 'package:akhi_gpt/config/debug_config.dart';

void main() {
  group('Debug Config Tests', () {
    test('should have skipPremium false by default', () {
      // When no dart-define is set, skipPremium should be false
      // Note: This test will pass when run normally, but fail when run with --dart-define=DEBUG_SKIP_PREMIUM=true
      // which is the expected behavior
      expect(DebugConfig.skipPremium, isFalse);
    });

    test('should report no debug flags when skipPremium is false', () {
      // When skipPremium is false, hasDebugFlags should be false
      if (!DebugConfig.skipPremium) {
        expect(DebugConfig.hasDebugFlags, isFalse);
      }
    });

    test('should provide debug status map', () {
      final status = DebugConfig.debugStatus;
      
      expect(status, isA<Map<String, bool>>());
      expect(status.containsKey('skipPremium'), isTrue);
      expect(status['skipPremium'], equals(DebugConfig.skipPremium));
    });
  });
}
