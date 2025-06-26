import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/hive_service.dart';
import 'services/openrouter_service.dart';
import 'theme/app_theme.dart';
import 'pages/onboarding/intro_page_one.dart';
import 'pages/onboarding/intro_page_two.dart';
import 'pages/onboarding/intro_page_three.dart';
import 'pages/onboarding/intro_page_four.dart';
import 'pages/onboarding/intro_page_five.dart';
import 'pages/onboarding/intro_page_six.dart';
import 'pages/onboarding/intro_page_seven_a.dart';
import 'pages/onboarding/intro_page_seven_b.dart';
import 'pages/onboarding/intro_page_seven_c.dart';
import 'pages/onboarding/intro_page_seven.dart'; // This will become page 8
import 'pages/onboarding/intro_page_eight.dart'; // This will become page 9
import 'pages/onboarding/intro_page_nine.dart';
import 'pages/onboarding/intro_page_ten.dart';
import 'pages/dashboard.dart';
import 'pages/card_navigation_page.dart';
import 'pages/chat_screen.dart';
import 'pages/chat_page.dart';
import 'pages/journal_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    developer.log('✅ .env loaded successfully', name: 'Main');
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    developer.log('API Key present: ${apiKey?.isNotEmpty ?? false}', name: 'Main');
    developer.log('API Key length: ${apiKey?.length ?? 0}', name: 'Main');
    developer.log('API Key starts with: ${apiKey?.substring(0, 20) ?? 'null'}...', name: 'Main');
    developer.log('Model: ${dotenv.env['DEFAULT_MODEL']}', name: 'Main');

    // Test OpenRouter service configuration
    final service = OpenRouterService();
    developer.log('Service configured: ${service.isConfigured}', name: 'Main');
    developer.log('Model display name: ${service.modelDisplayName}', name: 'Main');
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
      title: 'Companion GPT',
      theme: AppTheme.companionTheme,
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
      ],
      // ✨ NAVIGATION: Set SplashScreen as home to check gender preference
      home: const SplashScreen(),
      routes: {
        '/onboard1': (context) => const IntroPageOne(),
        '/onboard2': (context) => const IntroPageTwo(),
        '/onboard3': (context) => const IntroPageThree(),
        '/onboard4': (context) => const IntroPageFour(),
        '/onboard5': (context) => const IntroPageFive(),
        '/onboard6': (context) => const IntroPageSix(),
        '/onboard7a': (context) => const IntroPageSevenA(),
        '/onboard7b': (context) => const IntroPageSevenB(),
        '/onboard7c': (context) => const IntroPageSevenC(),
        '/onboard8': (context) => const IntroPageSeven(), // Renamed from page 7
        '/onboard9': (context) => const IntroPageEight(), // Renamed from page 8
        '/onboard10': (context) => const IntroPageNine(), // Renamed from page 9
        '/onboard11': (context) => const IntroPageTen(), // Renamed from page 10
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
