import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafs_ai/services/subscription_service.dart';
import 'package:nafs_ai/services/message_counter_service.dart';
import 'package:nafs_ai/services/secure_config_service.dart';

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
''');
      }
    });

    tearDown(() async {
      // Clean up after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should initialize with premium tier (RevenueCat removed)', () async {
      // Arrange
      final service = SubscriptionService.instance;

      // Act
      await service.initialize();

      // Assert
      expect(service.currentTier, equals(SubscriptionTier.premium));
      expect(service.isPremium, isTrue);
      expect(service.dailyMessageLimit, equals(999999)); // Unlimited
    });

    test('should return correct feature availability (all features available)', () {
      // Arrange
      final service = SubscriptionService.instance;

      // Act & Assert
      expect(service.isFeatureAvailable('personality_styles'), isTrue);
      expect(service.isFeatureAvailable('unlimited_messages'), isTrue);
      expect(service.isFeatureAvailable('unknown_feature'), isTrue);
    });

    test('should handle subscription tier enum correctly', () {
      // Test subscription tier properties
      expect(SubscriptionTier.free.displayName, equals('Free'));
      expect(SubscriptionTier.premium.displayName, equals('Premium'));
      
      expect(SubscriptionTier.free.dailyMessageLimit, equals(75));
      expect(SubscriptionTier.premium.dailyMessageLimit, equals(1500));
      
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
      expect(service.remainingMessages, equals(999999)); // Unlimited (RevenueCat removed)
    });

    test('should increment message count correctly', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();
      
      // Act
      final success = await service.incrementMessageCount();
      
      // Assert
      expect(success, isTrue);
      expect(service.currentCount, equals(0)); // Count not actually incremented (RevenueCat removed)
      expect(service.remainingMessages, equals(999999)); // Unlimited
    });

    test('should allow unlimited messages (RevenueCat removed)', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act - try to send many messages
      final canSend = await service.canSendMessage();
      final incrementSuccess = await service.incrementMessageCount();

      // Assert - unlimited messages allowed
      expect(canSend, isTrue);
      expect(incrementSuccess, isTrue);
      expect(service.hasReachedLimit, isFalse);
      expect(service.remainingMessages, equals(999999)); // Unlimited
    });

    test('should calculate usage percentage correctly (unlimited)', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act - usage percentage should be 0 for unlimited messages
      final percentage = service.usagePercentage;

      // Assert - 0% usage for unlimited messages
      expect(percentage, equals(0.0));
    });

    test('should return normal warning level (unlimited messages)', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act & Assert - always normal level for unlimited messages
      expect(service.getWarningLevel(), equals(MessageUsageWarningLevel.normal));
    });

    test('should provide usage statistics (unlimited)', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act
      final stats = service.getUsageStats();

      // Assert - unlimited messages
      expect(stats['currentCount'], equals(0));
      expect(stats['dailyLimit'], equals(999999));
      expect(stats['remainingMessages'], equals(999999));
      expect(stats['hasReachedLimit'], isFalse);
      expect(stats['subscriptionTier'], equals('Premium'));
      expect(stats['usagePercentage'], equals(0.0));
    });

    test('should not show upgrade prompt (premium users)', () async {
      // Arrange
      final service = MessageCounterService.instance;
      await service.initialize();

      // Act & Assert - no upgrade prompt for premium users
      expect(service.shouldShowUpgradePrompt(), isFalse);
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
      expect(config['revenuecat_configured'], isFalse); // RevenueCat removed
      expect(config.containsKey('entitlement_configured'), isTrue);
      expect(config['entitlement_configured'], isFalse); // RevenueCat removed
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
''');
      }
      
      // Act
      final subscriptionService = SubscriptionService.instance;
      final messageCounterService = MessageCounterService.instance;
      
      await subscriptionService.initialize();
      await messageCounterService.initialize();
      
      // Assert - premium tier (RevenueCat removed)
      expect(subscriptionService.currentTier, equals(SubscriptionTier.premium));
      expect(messageCounterService.currentCount, equals(0));
      expect(messageCounterService.dailyLimit, equals(999999)); // Unlimited
    });

    test('should handle unlimited message counting (RevenueCat removed)', () async {
      // Arrange
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      final subscriptionService = SubscriptionService.instance;
      final messageCounterService = MessageCounterService.instance;

      await subscriptionService.initialize();
      await messageCounterService.initialize();

      // Act - try to send many messages
      final canSendMore = await messageCounterService.canSendMessage();
      final incrementSuccess = await messageCounterService.incrementMessageCount();

      // Assert - unlimited messages allowed
      expect(canSendMore, isTrue);
      expect(incrementSuccess, isTrue);
      expect(messageCounterService.hasReachedLimit, isFalse);
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
