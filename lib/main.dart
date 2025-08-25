import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/hive_service.dart';
import 'services/openrouter_service.dart';
import 'services/subscription_service.dart';
import 'services/message_counter_service.dart';
import 'services/secure_config_service.dart';
import 'config/debug_config.dart';
import 'theme/app_theme.dart';

import 'pages/chat_screen.dart';
import 'pages/chat_page.dart';
import 'pages/dashboard.dart';
import 'pages/settings_page.dart';
import 'pages/splash_screen.dart';
import 'pages/paywall_screen.dart';
import 'services/settings_service.dart';

/// Generate routes with developer mode protection
Route<dynamic>? _generateRoute(RouteSettings settings) {
  final routeName = settings.name;

  final builder = MyApp.routes[routeName];
  if (builder == null) {
    return null; // Route not found
  }

  return MaterialPageRoute(
    builder: builder,
    settings: settings,
  );
}

void main() async {
  print('🔥🔥🔥 MAIN FUNCTION STARTED 🔥🔥🔥');
  WidgetsFlutterBinding.ensureInitialized();
  print('🔥 MAIN: Flutter binding initialized');

  // Log debug configuration
  if (DebugConfig.hasDebugFlags) {
    print('🔧 DEBUG: Debug flags enabled: ${DebugConfig.debugStatus}');
  }

  try {
    print('🔥 MAIN: Attempting to load .env file...');
    await dotenv.load(fileName: ".env");
    print('🔥 MAIN: .env file loaded successfully');
    print('🔥 MAIN: Environment variables loaded: ${dotenv.env.keys.toList()}');

    // Enhanced configuration validation
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    print('🔥 MAIN: API Key: ${apiKey != null ? "✅ Found (${apiKey.length} chars)" : "❌ Not found"}');
    if (apiKey != null) {
      print('🔥 MAIN: API Key starts with: ${apiKey.substring(0, 10)}...');
      print('🔥 MAIN: API Key format valid: ${apiKey.startsWith('sk-or-v1-') ? "✅" : "❌"}');
    }

    // Validate models
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModels = dotenv.env['FALLBACK_MODELS'];
    print('🔥 MAIN: Default Model: ${defaultModel ?? "❌ Not set"}');
    print('🔥 MAIN: Fallback Models: ${fallbackModels ?? "❌ Not set"}');

    if (fallbackModels != null) {
      final models = fallbackModels.split(',').map((m) => m.trim()).toList();
      print('🔥 MAIN: Fallback Models Count: ${models.length}');
      print('🔥 MAIN: Fallback Models List: $models');
    }

    // Validate proxy configuration
    final enableProxy = dotenv.env['ENABLE_PROXY'];
    final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
    print('🔥 MAIN: Proxy Enabled: ${enableProxy ?? "false"}');
    if (enableProxy?.toLowerCase() == 'true') {
      print('🔥 MAIN: Proxy Endpoint: ${proxyEndpoint ?? "❌ Not set"}');
    }

    // Quick validation check
    final isBasicConfigValid = apiKey != null &&
                              apiKey.isNotEmpty &&
                              apiKey.startsWith('sk-or-v1-') &&
                              defaultModel != null &&
                              defaultModel.contains('/') &&
                              fallbackModels != null &&
                              fallbackModels.isNotEmpty;

    print('🔥 MAIN: Basic Configuration Valid: ${isBasicConfigValid ? "✅" : "❌"}');

    if (!isBasicConfigValid) {
      print('🔥 MAIN: ⚠️ Configuration issues detected - app may not function properly');
      print('🔥 MAIN: ⚠️ Please check your .env file configuration');
    }

    // Log secure configuration status
    SecureConfigService.instance.logConfigurationStatus();

  } catch (e) {
    print('🔥 MAIN: ❌ Error loading .env: $e');
    print('🔥 MAIN: Error type: ${e.runtimeType}');
    print('🔥 MAIN: Error details: $e');
    print('🔥 MAIN: ⚠️ App will start but may not function properly without proper configuration');
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

  // Define route mappings
  static final routes = <String, Widget Function(BuildContext)>{
    '/dashboard': (context) => const Dashboard(),
    '/chat': (context) => const ChatScreen(),
    '/chat_page': (context) => const ChatPage(),
    '/settings': (context) => const SettingsPage(),
    '/paywall': (context) => const PaywallScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NafsAI',
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
      routes: MyApp.routes,
      onGenerateRoute: _generateRoute,
    );
  }
}
