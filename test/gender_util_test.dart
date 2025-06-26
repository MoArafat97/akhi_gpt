import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akhi_gpt/utils/gender_util.dart';

void main() {
  group('UserGender enum tests', () {
    test('should convert enum to string correctly', () {
      expect(UserGender.male.value, 'male');
      expect(UserGender.female.value, 'female');
    });

    test('should create enum from string correctly', () {
      expect(UserGender.fromString('male'), UserGender.male);
      expect(UserGender.fromString('female'), UserGender.female);
      expect(UserGender.fromString('MALE'), UserGender.male);
      expect(UserGender.fromString('FEMALE'), UserGender.female);
      expect(UserGender.fromString('invalid'), UserGender.male); // Default fallback
    });

    test('should return correct display names', () {
      expect(UserGender.male.displayName, 'Brother');
      expect(UserGender.female.displayName, 'Sister');
    });

    test('should return correct companion names', () {
      expect(UserGender.male.companionName, 'Akhi');
      expect(UserGender.female.companionName, 'Ukhti');
    });

    test('should return correct casual addresses', () {
      expect(UserGender.male.casualAddress, 'akhi');
      expect(UserGender.female.casualAddress, 'ukhti');
    });

    test('should return correct formal addresses', () {
      expect(UserGender.male.formalAddress, 'brother');
      expect(UserGender.female.formalAddress, 'sister');
    });
  });

  group('GenderUtil tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return default gender when not set', () async {
      final gender = await GenderUtil.getUserGender();
      expect(gender, UserGender.male);
    });

    test('should save and retrieve gender correctly', () async {
      await GenderUtil.setUserGender(UserGender.female);
      final gender = await GenderUtil.getUserGender();
      expect(gender, UserGender.female);
    });

    test('should track if gender is set', () async {
      expect(await GenderUtil.isGenderSet(), false);
      
      await GenderUtil.setUserGender(UserGender.male);
      expect(await GenderUtil.isGenderSet(), true);
    });

    test('should clear gender correctly', () async {
      await GenderUtil.setUserGender(UserGender.female);
      expect(await GenderUtil.isGenderSet(), true);
      
      await GenderUtil.clearGender();
      expect(await GenderUtil.isGenderSet(), false);
      
      final gender = await GenderUtil.getUserGender();
      expect(gender, UserGender.male); // Should return default
    });

    test('should generate correct localization keys', () {
      expect(
        GenderUtil.getLocalizedKey('greeting', UserGender.male),
        'greetingBrother'
      );
      expect(
        GenderUtil.getLocalizedKey('greeting', UserGender.female),
        'greetingSister'
      );
    });
  });
}
