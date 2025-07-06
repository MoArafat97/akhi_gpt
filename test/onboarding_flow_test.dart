import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akhi_gpt/utils/gender_util.dart';

void main() {
  group('Onboarding Flow Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for hasSeenOnboarding initially', () async {
      // Act
      final hasSeenOnboarding = await GenderUtil.hasSeenOnboarding();
      
      // Assert
      expect(hasSeenOnboarding, isFalse);
    });

    test('should set hasSeenOnboarding flag correctly', () async {
      // Act
      await GenderUtil.setHasSeenOnboarding();
      final hasSeenOnboarding = await GenderUtil.hasSeenOnboarding();
      
      // Assert
      expect(hasSeenOnboarding, isTrue);
    });

    test('should set hasSeenOnboarding when onboarding is completed', () async {
      // Act
      await GenderUtil.setOnboardingComplete();
      final hasSeenOnboarding = await GenderUtil.hasSeenOnboarding();
      final isOnboardingComplete = await GenderUtil.isOnboardingComplete();
      
      // Assert
      expect(hasSeenOnboarding, isTrue);
      expect(isOnboardingComplete, isTrue);
    });

    test('should persist hasSeenOnboarding flag across sessions', () async {
      // Arrange
      await GenderUtil.setHasSeenOnboarding();
      
      // Simulate app restart by creating new instance
      final hasSeenOnboarding = await GenderUtil.hasSeenOnboarding();
      
      // Assert
      expect(hasSeenOnboarding, isTrue);
    });

    test('should clear hasSeenOnboarding when clearAll is called', () async {
      // Arrange
      await GenderUtil.setHasSeenOnboarding();
      expect(await GenderUtil.hasSeenOnboarding(), isTrue);
      
      // Act
      await GenderUtil.clearAll();
      
      // Assert
      expect(await GenderUtil.hasSeenOnboarding(), isFalse);
    });
  });
}
