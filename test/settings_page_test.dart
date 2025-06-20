import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akhi_gpt/pages/settings_page.dart';

void main() {
  group('SettingsPage Tests', () {
    testWidgets('SettingsPage builds without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsPage(),
        ),
      );

      // Verify that the settings page renders the basic structure
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('SettingsPage has ListView with content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsPage(),
        ),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // Check that ListView has children (settings items)
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Check that there are ListTile widgets (settings items)
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
