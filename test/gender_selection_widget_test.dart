import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:akhi_gpt/pages/onboarding/intro_page_ten.dart';
import 'package:akhi_gpt/utils/gender_util.dart';

void main() {
  group('Gender Selection Page Widget Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget(Widget child) {
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
        home: child,
      );
    }

    testWidgets('should display gender selection page correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const IntroPageTen()));
      await tester.pumpAndSettle();

      // Check if the page title is displayed
      expect(find.text('Choose Your Companion'), findsOneWidget);
      expect(find.text('Who would you like to chat with?'), findsOneWidget);

      // Check if both gender options are displayed
      expect(find.text('Brother'), findsOneWidget);
      expect(find.text('Sister'), findsOneWidget);

      // Check if descriptions are displayed
      expect(find.text('A supportive older brother who understands your journey'), findsOneWidget);
      expect(find.text('A caring older sister who shares your experiences'), findsOneWidget);

      // Check if back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should have working back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        Navigator(
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(builder: (_) => const IntroPageTen());
            }
            return null;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Find and tap the back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      
      // The page should attempt to navigate back
      // In a real app, this would pop the route
    });

    testWidgets('should respond to gender selection taps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        MaterialApp(
          home: const IntroPageTen(),
          routes: {
            '/card_navigation': (context) => const Scaffold(
              body: Center(child: Text('Card Navigation')),
            ),
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Find the Brother option and tap it
      final brotherCard = find.ancestor(
        of: find.text('Brother'),
        matching: find.byType(InkWell),
      );
      expect(brotherCard, findsOneWidget);

      await tester.tap(brotherCard);
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();

      // Should navigate to card navigation
      expect(find.text('Card Navigation'), findsOneWidget);
    });

    testWidgets('should save gender preference when selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        MaterialApp(
          home: const IntroPageTen(),
          routes: {
            '/card_navigation': (context) => const Scaffold(
              body: Center(child: Text('Card Navigation')),
            ),
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Verify initial state
      expect(await GenderUtil.isGenderSet(), false);

      // Find and tap the Sister option
      final sisterCard = find.ancestor(
        of: find.text('Sister'),
        matching: find.byType(InkWell),
      );
      expect(sisterCard, findsOneWidget);

      await tester.tap(sisterCard);
      await tester.pumpAndSettle();

      // Verify gender was saved
      expect(await GenderUtil.isGenderSet(), true);
      expect(await GenderUtil.getUserGender(), UserGender.female);
    });

    testWidgets('should show correct icons and styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const IntroPageTen()));
      await tester.pumpAndSettle();

      // Check for person icons
      expect(find.byIcon(Icons.person), findsNWidgets(2));

      // Check for arrow forward icons
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(2));

      // Check for gradient background
      expect(find.byType(Container), findsWidgets);
      
      // Check for cards
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should handle animation states correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const IntroPageTen()));
      
      // Initial pump to start animations
      await tester.pump();
      
      // Check that FadeTransition is present
      expect(find.byType(FadeTransition), findsOneWidget);
      
      // Pump and settle to complete animations
      await tester.pumpAndSettle();
      
      // Check that content is visible after animation
      expect(find.text('Choose Your Companion'), findsOneWidget);
    });

    testWidgets('should prevent multiple taps during selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        MaterialApp(
          home: const IntroPageTen(),
          routes: {
            '/card_navigation': (context) => const Scaffold(
              body: Center(child: Text('Card Navigation')),
            ),
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Find the Brother option
      final brotherCard = find.ancestor(
        of: find.text('Brother'),
        matching: find.byType(InkWell),
      );

      // Tap multiple times quickly
      await tester.tap(brotherCard);
      await tester.tap(brotherCard);
      await tester.tap(brotherCard);
      await tester.pump();

      // Should only show one loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
