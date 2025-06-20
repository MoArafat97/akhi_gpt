import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'services/hive_service.dart';
import 'theme/app_theme.dart';
import 'pages/onboarding/intro_page_one.dart';
import 'pages/onboarding/intro_page_two.dart';
import 'pages/onboarding/intro_page_three.dart';
import 'pages/onboarding/intro_page_four.dart';
import 'pages/onboarding/intro_page_five.dart';
import 'pages/onboarding/intro_page_six.dart';
import 'pages/onboarding/intro_page_seven.dart';
import 'pages/onboarding/intro_page_eight.dart';
import 'pages/onboarding/intro_page_nine.dart';
import 'pages/dashboard.dart';
import 'pages/card_navigation_page.dart';
import 'pages/chat_screen.dart';
import 'pages/chat_page.dart';
import 'pages/journal_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    developer.log('✅ .env loaded successfully', name: 'Main');
    developer.log('API Key present: ${dotenv.env['OPENROUTER_API_KEY']?.isNotEmpty ?? false}', name: 'Main');
    developer.log('Model: ${dotenv.env['DEFAULT_MODEL']}', name: 'Main');
  } catch (e) {
    developer.log('❌ Error loading .env: $e', name: 'Main');
  }

  try {
    // Initialize Hive database for local storage
    await HiveService.instance.init();
    developer.log('✅ Hive database initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('❌ Failed to initialize Hive database: $e', name: 'Main');
    // Continue without database - app will show error in journal page
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akhi GPT',
      theme: AppTheme.akhigptTheme,
      // ✨ NAVIGATION: Set CardNavigationPage as home, direct routing to pages
      home: const CardNavigationPage(),
      routes: {
        '/onboard1': (context) => const IntroPageOne(),
        '/onboard2': (context) => const IntroPageTwo(),
        '/onboard3': (context) => const IntroPageThree(),
        '/onboard4': (context) => const IntroPageFour(),
        '/onboard5': (context) => const IntroPageFive(),
        '/onboard6': (context) => const IntroPageSix(),
        '/onboard7': (context) => const IntroPageSeven(),
        '/onboard8': (context) => const IntroPageEight(),
        '/onboard9': (context) => const IntroPageNine(),
        '/dashboard': (context) => const Dashboard(),
        '/card_navigation': (context) => const CardNavigationPage(),
        '/chat': (context) => const ChatScreen(),
        '/chat_page': (context) => const ChatPage(),
        '/journal': (context) => const JournalPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
