import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:akhi_gpt/main.dart';
import 'package:akhi_gpt/utils/gender_util.dart';
import 'package:akhi_gpt/pages/splash_screen.dart';
import 'package:akhi_gpt/pages/onboarding/intro_page_one.dart';
import 'package:akhi_gpt/pages/onboarding/intro_page_ten.dart';
import 'package:akhi_gpt/pages/card_navigation_page.dart';
import 'package:akhi_gpt/pages/settings_page.dart';

void main() {
  group('Gender Integration Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestApp() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        home: const SplashScreen(),
        routes: {
          '/onboard1': (context) => const IntroPageOne(),
          '/onboard11': (context) => const IntroPageTen(), // Updated route number
          '/card_navigation': (context) => const CardNavigationPage(),
          '/settings': (context) => const SettingsPage(),
        },
      );
    }

    testWidgets('Complete male user flow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      
      // Start at splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle();

      // Should navigate to onboarding since gender not set
      expect(find.byType(IntroPageOne), findsOneWidget);

      // Navigate through onboarding to gender selection
      // (In a real test, we'd navigate through all pages)
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const IntroPageTen(),
        routes: {
          '/card_navigation': (context) => const CardNavigationPage(),
        },
      ));
      await tester.pumpAndSettle();

      // Select Brother option
      final brotherCard = find.ancestor(
        of: find.text('Brother'),
        matching: find.byType(InkWell),
      );
      await tester.tap(brotherCard);
      await tester.pumpAndSettle();

      // Should navigate to main app
      expect(find.byType(CardNavigationPage), findsOneWidget);

      // Verify gender was saved
      expect(await GenderUtil.getUserGender(), UserGender.male);
      expect(await GenderUtil.isGenderSet(), true);
    });

    testWidgets('Complete female user flow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      
      // Start at splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle();

      // Navigate to gender selection
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const IntroPageTen(),
        routes: {
          '/card_navigation': (context) => const CardNavigationPage(),
        },
      ));
      await tester.pumpAndSettle();

      // Select Sister option
      final sisterCard = find.ancestor(
        of: find.text('Sister'),
        matching: find.byType(InkWell),
      );
      await tester.tap(sisterCard);
      await tester.pumpAndSettle();

      // Should navigate to main app
      expect(find.byType(CardNavigationPage), findsOneWidget);

      // Verify gender was saved
      expect(await GenderUtil.getUserGender(), UserGender.female);
      expect(await GenderUtil.isGenderSet(), true);
    });

    testWidgets('Returning user flow (gender already set)', (WidgetTester tester) async {
      // Pre-set gender
      await GenderUtil.setUserGender(UserGender.female);

      await tester.pumpWidget(createTestApp());
      
      // Start at splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle();

      // Should skip onboarding and go directly to main app
      expect(find.byType(CardNavigationPage), findsOneWidget);
    });

    testWidgets('Gender change through settings flow', (WidgetTester tester) async {
      // Start with male gender
      await GenderUtil.setUserGender(UserGender.male);

      await tester.pumpWidget(MaterialApp(
        home: const SettingsPage(),
      ));
      await tester.pumpAndSettle();

      // Verify initial state shows Brother
      expect(find.text('Brother'), findsOneWidget);
      expect(await GenderUtil.getUserGender(), UserGender.male);

      // Open gender selection dialog
      final companionTile = find.ancestor(
        of: find.text('Companion Type'),
        matching: find.byType(ListTile),
      );
      await tester.tap(companionTile);
      await tester.pumpAndSettle();

      // Change to Sister
      final sisterOption = find.ancestor(
        of: find.text('A caring older sister'),
        matching: find.byType(InkWell),
      );
      await tester.tap(sisterOption);
      await tester.pumpAndSettle();

      // Verify change was applied
      expect(await GenderUtil.getUserGender(), UserGender.female);
      expect(find.text('Sister'), findsOneWidget);
      expect(find.text('Companion changed to Sister'), findsOneWidget);
    });

    testWidgets('Gender persistence across app restarts', (WidgetTester tester) async {
      // First app session - set gender
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const IntroPageTen(),
        routes: {
          '/card_navigation': (context) => const CardNavigationPage(),
        },
      ));
      await tester.pumpAndSettle();

      // Select Sister
      final sisterCard = find.ancestor(
        of: find.text('Sister'),
        matching: find.byType(InkWell),
      );
      await tester.tap(sisterCard);
      await tester.pumpAndSettle();

      // Verify gender was saved
      expect(await GenderUtil.getUserGender(), UserGender.female);

      // Simulate app restart by creating new app instance
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should skip onboarding and go to main app
      expect(find.byType(CardNavigationPage), findsOneWidget);

      // Gender should still be female
      expect(await GenderUtil.getUserGender(), UserGender.female);
    });

    testWidgets('Gender reset flow', (WidgetTester tester) async {
      // Set initial gender
      await GenderUtil.setUserGender(UserGender.female);
      expect(await GenderUtil.isGenderSet(), true);

      // Clear gender (simulating reset)
      await GenderUtil.clearGender();
      expect(await GenderUtil.isGenderSet(), false);

      // Start app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should go to onboarding since gender is not set
      expect(find.byType(IntroPageOne), findsOneWidget);
    });

    testWidgets('Multiple gender changes in same session', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SettingsPage(),
      ));
      await tester.pumpAndSettle();

      // Start with default (Brother)
      expect(find.text('Brother'), findsOneWidget);

      // Change to Sister
      final companionTile = find.ancestor(
        of: find.text('Companion Type'),
        matching: find.byType(ListTile),
      );
      await tester.tap(companionTile);
      await tester.pumpAndSettle();

      final sisterOption = find.ancestor(
        of: find.text('A caring older sister'),
        matching: find.byType(InkWell),
      );
      await tester.tap(sisterOption);
      await tester.pumpAndSettle();

      expect(await GenderUtil.getUserGender(), UserGender.female);
      expect(find.text('Sister'), findsOneWidget);

      // Change back to Brother
      await tester.tap(companionTile);
      await tester.pumpAndSettle();

      final brotherOption = find.ancestor(
        of: find.text('A supportive older brother'),
        matching: find.byType(InkWell),
      );
      await tester.tap(brotherOption);
      await tester.pumpAndSettle();

      expect(await GenderUtil.getUserGender(), UserGender.male);
      expect(find.text('Brother'), findsOneWidget);
    });
  });
}
