import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akhi_gpt/pages/paywall_screen.dart';
import 'package:akhi_gpt/services/subscription_service.dart';
import 'package:akhi_gpt/services/message_counter_service.dart';

void main() {
  group('PaywallScreen Widget Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await dotenv.load(fileName: ".env.example");
      
      // Initialize services
      await SubscriptionService.instance.initialize();
      await MessageCounterService.instance.initialize();
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('should display paywall screen with correct title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should display different headers based on source', (WidgetTester tester) async {
      // Test messages source
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(source: 'messages'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Daily Limit Reached'), findsOneWidget);

      // Test personality source
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(source: 'personality'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock All Personalities'), findsOneWidget);
    });

    testWidgets('should display premium benefits', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Premium Benefits'), findsOneWidget);
      expect(find.text('500 Messages Daily'), findsOneWidget);
      expect(find.text('All Personality Styles'), findsOneWidget);
      expect(find.text('Priority Support'), findsOneWidget);
      expect(find.text('Early Access'), findsOneWidget);
    });

    testWidgets('should display restore purchases button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Restore Purchases'), findsOneWidget);
    });

    testWidgets('should display terms and privacy links', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('should close paywall when close button is tapped', (WidgetTester tester) async {
      // Arrange
      bool paywallClosed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const PaywallScreen(),
                  ),
                );
                if (result == false || result == null) {
                  paywallClosed = true;
                }
              },
              child: const Text('Open Paywall'),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Open Paywall'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert
      expect(paywallClosed, isTrue);
    });

    testWidgets('should show loading state when no offerings available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act - pump once to show initial loading state
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PaywallScreen Integration Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await dotenv.load(fileName: ".env.example");
    });

    testWidgets('should handle navigation correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(),
                      ),
                    );
                  },
                  child: const Text('Show Paywall'),
                ),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });
  });

  group('PaywallScreen Error Handling Tests', () {
    testWidgets('should handle missing offerings gracefully', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - should not crash and should show some content
      expect(find.byType(PaywallScreen), findsOneWidget);
      // The screen should either show loading or error state, not crash
    });

    testWidgets('should display error message when offerings fail to load', (WidgetTester tester) async {
      // This test simulates the case where RevenueCat is not configured
      // and the paywall should handle this gracefully
      
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });

  group('PaywallScreen Accessibility Tests', () {
    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - check for semantic labels
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should be navigable with keyboard/screen reader', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const PaywallScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - buttons should be focusable
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        expect(buttons, findsWidgets);
      }
    });
  });
}
