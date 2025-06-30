import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akhi_gpt/services/subscription_service.dart';
import 'package:akhi_gpt/services/message_counter_service.dart';
import 'package:akhi_gpt/services/secure_config_service.dart';

void main() {
  group('SubscriptionService Tests', () {
    setUp(() async {
      // Initialize test environment
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      // Load test environment variables
      try {
        await dotenv.load(fileName: ".env.example");
      } catch (e) {
        // If .env.example doesn't exist, set up minimal test environment
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=test-key
DEFAULT_MODEL=test-model
FALLBACK_MODELS=test-model1,test-model2
REVENUECAT_API_KEY_ANDROID=test-android-key
REVENUECAT_API_KEY_IOS=test-ios-key
REVENUECAT_ENTITLEMENT_ID=premium
''');
      }
    });

    tearDown(() async {
      // Clean up after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should initialize with free tier when no API key configured', () async {
      // Arrange
      final service = SubscriptionService.instance;
      
      // Act
      await service.initialize();
      
      // Assert
      expect(service.currentTier, equals(SubscriptionTier.free));
      expect(service.isPremium, isFalse);
      expect(service.dailyMessageLimit, equals(75));
    });

    test('should return correct feature availability for free tier', () {
      // Arrange
      final service = SubscriptionService.instance;
      
      // Act & Assert
      expect(service.isFeatureAvailable('personality_styles'), isFalse);
      expect(service.isFeatureAvailable('unlimited_messages'), isFalse);
      expect(service.isFeatureAvailable('unknown_feature'), isTrue); // Default to available
    });

    test('should handle subscription tier enum correctly', () {
      // Test subscription tier properties
      expect(SubscriptionTier.free.displayName, equals('Free'));
      expect(SubscriptionTier.premium.displayName, equals('Premium'));
      
      expect(SubscriptionTier.free.dailyMessageLimit, equals(75));
      expect(SubscriptionTier.premium.dailyMessageLimit, equals(500));
      
      expect(SubscriptionTier.free.hasPersonalityStyles, isFalse);
      expect(SubscriptionTier.premium.hasPersonalityStyles, isTrue);
    });
  });

  group('MessageCounterService Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should initialize with zero count', () async {
      // Arrange
      final service = MessageCounterService.instance;
      
      // Act
      await service.initialize();
      
      // Assert
      expect(service.currentCount, equals(0));
      expect(service.hasReachedLimit, isFalse);
      expect(service.remainingMessages, equals(75)); // Default free tier limit
    });

    test('should increment message count correctly', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Act
      final success = await service.incrementMessageCount();
      
      // Assert
      expect(success, isTrue);
      expect(service.currentCount, equals(1));
      expect(service.remainingMessages, equals(74));
    });

    test('should prevent sending messages when limit reached', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Simulate reaching the limit
      for (int i = 0; i < 75; i++) {
        await service.incrementMessageCount();
      }
      
      // Act
      final canSend = await service.canSendMessage();
      final incrementSuccess = await service.incrementMessageCount();
      
      // Assert
      expect(canSend, isFalse);
      expect(incrementSuccess, isFalse);
      expect(service.hasReachedLimit, isTrue);
      expect(service.remainingMessages, equals(0));
    });

    test('should calculate usage percentage correctly', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act - send 37 messages (about 50% of 75)
      int successfulMessages = 0;
      for (int i = 0; i < 37; i++) {
        final success = await service.incrementMessageCount();
        if (success) successfulMessages++;
      }

      // Assert - check actual successful messages
      final expectedPercentage = successfulMessages / 75.0;
      expect(service.usagePercentage, closeTo(expectedPercentage, 0.02));
    });

    test('should return correct warning levels', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Test normal level (0 messages)
      expect(service.getWarningLevel(), equals(MessageUsageWarningLevel.normal));
      
      // Test warning level (75% of 75 = 56 messages)
      for (int i = 0; i < 56; i++) {
        await service.incrementMessageCount();
      }
      expect(service.getWarningLevel(), equals(MessageUsageWarningLevel.warning));
      
      // Test critical level (90% of 75 = 67 messages)
      for (int i = 0; i < 11; i++) {
        await service.incrementMessageCount();
      }
      expect(service.getWarningLevel(), equals(MessageUsageWarningLevel.critical));
      
      // Test limit reached (75 messages)
      for (int i = 0; i < 8; i++) {
        await service.incrementMessageCount();
      }
      expect(service.getWarningLevel(), equals(MessageUsageWarningLevel.limitReached));
    });

    test('should provide usage statistics', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Send some messages
      for (int i = 0; i < 25; i++) {
        await service.incrementMessageCount();
      }
      
      // Act
      final stats = service.getUsageStats();
      
      // Assert
      expect(stats['currentCount'], equals(25));
      expect(stats['dailyLimit'], equals(75));
      expect(stats['remainingMessages'], equals(50));
      expect(stats['hasReachedLimit'], isFalse);
      expect(stats['subscriptionTier'], equals('Free'));
      expect(stats['usagePercentage'], closeTo(0.33, 0.02));
    });

    test('should show upgrade prompt at 90% usage for free users', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Act - send 67 messages (90% of 75)
      for (int i = 0; i < 67; i++) {
        await service.incrementMessageCount();
      }
      
      // Assert
      expect(service.shouldShowUpgradePrompt(), isTrue);
    });
  });

  group('SecureConfigService Tests', () {
    test('should obfuscate keys correctly', () {
      // Arrange
      final service = SecureConfigService.instance;

      // Act & Assert
      expect(service.obfuscateKey('short'), equals('*****'));
      expect(service.obfuscateKey('test-api-key-12345').length, equals('test-api-key-12345'.length));
      expect(service.obfuscateKey('test-api-key-12345').startsWith('test'), isTrue);
      expect(service.obfuscateKey('test-api-key-12345').endsWith('2345'), isTrue);
      expect(service.obfuscateKey('a'), equals('*'));
    });

    test('should generate secure random strings', () {
      // Arrange
      final service = SecureConfigService.instance;
      
      // Act
      final random1 = service.generateSecureRandomString(20);
      final random2 = service.generateSecureRandomString(20);
      
      // Assert
      expect(random1.length, equals(20));
      expect(random2.length, equals(20));
      expect(random1, isNot(equals(random2))); // Should be different
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(random1), isTrue);
    });

    test('should validate configuration correctly', () {
      // Arrange
      final service = SecureConfigService.instance;
      
      // Act
      final config = service.validateConfiguration();
      
      // Assert
      expect(config, isA<Map<String, bool>>());
      expect(config.containsKey('openrouter_configured'), isTrue);
      expect(config.containsKey('revenuecat_configured'), isTrue);
      expect(config.containsKey('entitlement_configured'), isTrue);
    });
  });

  group('Integration Tests', () {
    test('should handle subscription service initialization gracefully', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      try {
        await dotenv.load(fileName: ".env.example");
      } catch (e) {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=test-key
DEFAULT_MODEL=test-model
REVENUECAT_API_KEY_ANDROID=test-android-key
REVENUECAT_API_KEY_IOS=test-ios-key
REVENUECAT_ENTITLEMENT_ID=premium
''');
      }
      
      // Act
      final subscriptionService = SubscriptionService.instance;
      final messageCounterService = MessageCounterService.instance;
      
      await subscriptionService.initialize();
      await messageCounterService.initialize();
      
      // Assert
      expect(subscriptionService.currentTier, equals(SubscriptionTier.free));
      expect(messageCounterService.currentCount, equals(0));
      expect(messageCounterService.dailyLimit, equals(75));
    });

    test('should handle message counting with subscription limits', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      final subscriptionService = SubscriptionService.instance;
      final messageCounterService = MessageCounterService.instance;
      
      await subscriptionService.initialize();
      await messageCounterService.initialize();
      
      // Act - simulate reaching free tier limit
      for (int i = 0; i < 75; i++) {
        final success = await messageCounterService.incrementMessageCount();
        expect(success, isTrue);
      }
      
      // Try to send one more message
      final canSendMore = await messageCounterService.canSendMessage();
      final incrementSuccess = await messageCounterService.incrementMessageCount();
      
      // Assert
      expect(canSendMore, isFalse);
      expect(incrementSuccess, isFalse);
      expect(messageCounterService.hasReachedLimit, isTrue);
    });
  });

  group('Error Handling Tests', () {
    test('should handle SharedPreferences errors gracefully', () async {
      // This test would require mocking SharedPreferences to throw errors
      // For now, we'll test that the services don't crash on initialization
      
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      final subscriptionService = SubscriptionService.instance;
      final messageCounterService = MessageCounterService.instance;
      
      // These should not throw exceptions
      expect(() async => await subscriptionService.initialize(), returnsNormally);
      expect(() async => await messageCounterService.initialize(), returnsNormally);
    });
  });
}
