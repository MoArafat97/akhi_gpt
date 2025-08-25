import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

import 'services/hive_service.dart';
import 'services/subscription_service.dart';
import 'services/message_counter_service.dart';
import 'services/secure_config_service.dart';
import 'config/debug_config.dart';
import 'theme/app_theme.dart';

import 'pages/chat_screen.dart';
import 'pages/chat_page.dart';
import 'pages/chat_history_page.dart';
import 'pages/dashboard.dart';
import 'pages/settings_page.dart';
import 'pages/splash_screen.dart';
import 'pages/terms_conditions_page.dart';
import 'animations/page_transitions.dart';

/// ✨ GENERATE ROUTES with modern transitions and developer mode protection
Route<dynamic>? _generateRoute(RouteSettings settings) {
  final String? routeName = settings.name;

  if (routeName == null) {
    return null;
  }

  Widget page;
  switch (routeName) {
    case '/dashboard':
      page = const Dashboard();
      break;
    case '/chat':
      page = const ChatScreen();
      break;
    case '/chat_page':
      page = const ChatPage();
      break;
    case '/chat_history':
      page = const ChatHistoryPage();
      break;
    case '/settings':
      page = const SettingsPage();
      break;
    case '/terms_conditions':
      // Check if this is view-only mode (from settings)
      final isViewOnly = settings.arguments as bool? ?? false;
      page = TermsConditionsPage(isViewOnly: isViewOnly);
      break;
    default:
      return null;
  }

  // ✨ APPLY DIFFERENT TRANSITIONS based on route
  switch (routeName) {
    case '/chat':
      return ModernPageTransitions.glassmorphicTransition(page, settings: RouteSettings(name: routeName));
    case '/settings':
      // Use our transition but ensure settings are attached
      return ModernPageTransitions.slideTransition(page, settings: RouteSettings(name: routeName));
    case '/chat_history':
      return ModernPageTransitions.fadeTransition(page, settings: RouteSettings(name: routeName));
    case '/terms_conditions':
      return ModernPageTransitions.scaleTransition(page, settings: RouteSettings(name: routeName));
    case '/onboard1':
    case '/onboard2':
    case '/onboard3':
      return ModernPageTransitions.scaleTransition(page, settings: RouteSettings(name: routeName));
    default:
      return ModernPageTransitions.slideTransition(page, settings: RouteSettings(name: routeName));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log debug configuration only in debug mode
  if (DebugConfig.hasDebugFlags) {
    developer.log('DEBUG: Debug flags enabled: ${DebugConfig.debugStatus}');
  }

  try {
    await dotenv.load(fileName: ".env");

    // Enhanced configuration validation
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your-openrouter-api-key-here') {
      developer.log('WARNING: OpenRouter API key not configured properly');
    }

    // Validate models
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModels = dotenv.env['FALLBACK_MODELS'];

    // Quick validation check
    final isBasicConfigValid = apiKey != null &&
                              apiKey.isNotEmpty &&
                              apiKey != 'your-openrouter-api-key-here' &&
                              defaultModel != null &&
                              defaultModel.contains('/') &&
                              fallbackModels != null &&
                              fallbackModels.isNotEmpty;

    if (!isBasicConfigValid) {
      developer.log('WARNING: Configuration issues detected - app may not function properly');
    }

    // Log secure configuration status
    SecureConfigService.instance.logConfigurationStatus();

  } catch (e) {
    developer.log('ERROR: Failed to load .env configuration: $e');
  }

  try {
    // Initialize Hive database for local storage
    await HiveService.instance.init();
    developer.log('✅ Hive database initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('❌ Failed to initialize Hive database: $e', name: 'Main');
    // Continue without database - app will show error in journal page
  }

  try {
    // Initialize subscription service
    await SubscriptionService.instance.initialize();
    developer.log('✅ Subscription service initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('❌ Failed to initialize subscription service: $e', name: 'Main');
    // Continue without subscription service - app will default to free tier
  }

  try {
    // Initialize message counter service
    await MessageCounterService.instance.initialize();
    developer.log('✅ Message counter service initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('❌ Failed to initialize message counter service: $e', name: 'Main');
    // Continue without message counter - app will allow unlimited messages
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NafsAI',
      debugShowCheckedModeBanner: false,
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
      onGenerateRoute: _generateRoute,
    );
  }
}
