import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'utils/secure_logger.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/hive_service.dart';
import 'services/openrouter_service.dart'; // Proxy-only mode uses backend key
import 'services/subscription_service.dart';
import 'services/message_counter_service.dart';
import 'services/secure_config_service.dart';
import 'config/debug_config.dart';
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
import 'pages/onboarding/intro_page_eleven.dart';
import 'pages/dashboard.dart';
import 'pages/card_navigation_page.dart';
import 'pages/chat_screen.dart';
import 'pages/chat_page.dart';
import 'pages/settings_page.dart';
import 'pages/diagnostic_page.dart';
import 'pages/splash_screen.dart';
import 'pages/terms_conditions_page.dart';

// Setup page removed in proxy-only mode

import 'services/settings_service.dart';

/// Generate routes with developer mode protection
Route<dynamic>? _generateRoute(RouteSettings settings) {
  final routeName = settings.name;

  // Define route mappings
  final routes = <String, Widget Function(BuildContext)>{
    '/onboard1': (context) => const IntroPageOne(),
    '/onboard2': (context) => const IntroPageTwo(),
    '/onboard3': (context) => const IntroPageThree(),
    '/onboard4': (context) => const IntroPageFour(),
    '/onboard5': (context) => const IntroPageFive(),
    '/onboard6': (context) => const IntroPageSix(),
    '/onboard7a': (context) => const IntroPageSevenA(),
    '/onboard7b': (context) => const IntroPageSevenB(),
    '/onboard7c': (context) => const IntroPageSevenC(),
    '/onboard8': (context) => const IntroPageSeven(),
    '/onboard9': (context) => const IntroPageEight(),
    '/onboard10': (context) => const IntroPageNine(),
    '/onboard12': (context) => const IntroPageEleven(),
    '/terms_conditions': (context) => const TermsConditionsPage(isMandatory: true),
    '/dashboard': (context) => const Dashboard(),
    '/card_navigation': (context) => const CardNavigationPage(),
    '/chat': (context) => const ChatScreen(),
    '/chat_page': (context) => const ChatPage(),
    '/settings': (context) => const SettingsPage(),

    '/diagnostics': (context) => const DiagnosticPage(),
  };

  final builder = routes[routeName];
  if (builder == null) {
    return null; // Route not found
  }

  // For developer routes, check access permission
  return MaterialPageRoute(
    builder: (context) => FutureBuilder<bool>(
      future: SettingsService.canAccessDeveloperRoute(routeName!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final canAccess = snapshot.data ?? false;
        if (!canAccess) {
          // Redirect to main page if access denied
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/card_navigation');
          });
          return const Scaffold(
            body: Center(
              child: Text('Access denied'),
            ),
          );
        }

        return builder(context);
      },
    ),
    settings: settings,
  );
}

void main() async {
  SecureLogger.info('Application starting', name: 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  SecureLogger.success('Flutter binding initialized', name: 'Main');

  // Log debug configuration
  if (DebugConfig.hasDebugFlags) {
    SecureLogger.debug('Debug flags enabled: ${DebugConfig.debugStatus}', name: 'Main');
  }

  try {
    SecureLogger.info('Loading environment configuration', name: 'Main');
    await dotenv.load(fileName: ".env");
    SecureLogger.success('Environment configuration loaded', name: 'Main');

    // Enhanced configuration validation
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    SecureLogger.logConfig('OpenRouter API Key', apiKey != null && apiKey.isNotEmpty);
    if (apiKey != null && kDebugMode) {
      SecureLogger.debug('API Key: ${SecureLogger.obfuscateApiKey(apiKey)}', name: 'Main');
      SecureLogger.debug('API Key format valid: ${apiKey.startsWith('sk-or-v1-')}', name: 'Main');
    }

    // Validate models
    final defaultModel = dotenv.env['DEFAULT_MODEL'];
    final fallbackModels = dotenv.env['FALLBACK_MODELS'];
    SecureLogger.logConfig('Default Model', defaultModel != null && defaultModel.isNotEmpty);
    SecureLogger.logConfig('Fallback Models', fallbackModels != null && fallbackModels.isNotEmpty);

    if (fallbackModels != null && kDebugMode) {
      final models = fallbackModels.split(',').map((m) => m.trim()).toList();
      SecureLogger.debug('Fallback Models Count: ${models.length}', name: 'Main');
      SecureLogger.debug('Fallback Models: ${models.join(', ')}', name: 'Main');
    }

    // Validate proxy configuration
    final enableProxy = dotenv.env['ENABLE_PROXY'];
    final proxyEndpoint = dotenv.env['PROXY_ENDPOINT'];
    final proxyEnabled = enableProxy?.toLowerCase() == 'true';
    SecureLogger.logConfig('Proxy', proxyEnabled);
    if (proxyEnabled && kDebugMode) {
      SecureLogger.debug('Proxy Endpoint: ${proxyEndpoint ?? "Not set"}', name: 'Main');
    }

    // Quick validation check
    final isBasicConfigValid = apiKey != null &&
                              apiKey.isNotEmpty &&
                              apiKey.startsWith('sk-or-v1-') &&
                              defaultModel != null &&
                              defaultModel.contains('/') &&
                              fallbackModels != null &&
                              fallbackModels.isNotEmpty;

    SecureLogger.logConfig('Basic Configuration', isBasicConfigValid);

    if (!isBasicConfigValid) {
      SecureLogger.warning('Configuration issues detected - app may not function properly', name: 'Main');
      SecureLogger.warning('Please check your .env file configuration', name: 'Main');
    }

    // Log secure configuration status
    SecureConfigService.instance.logConfigurationStatus();

  } catch (e) {
    SecureLogger.error('Error loading environment configuration', name: 'Main', error: e);
    SecureLogger.warning('App will start but may not function properly without proper configuration', name: 'Main');
  }

  try {
    // Initialize Hive database for local storage
    await HiveService.instance.init();
    SecureLogger.success('Hive database initialized successfully', name: 'Main');
  } catch (e) {
    SecureLogger.error('Failed to initialize Hive database', name: 'Main', error: e);
    // Continue without database - app will show error in journal page
  }

  try {
    // Initialize subscription service (RevenueCat removed)
    await SubscriptionService.instance.initialize();
    SecureLogger.success('Subscription service initialized successfully', name: 'Main');
  } catch (e) {
    SecureLogger.error('Failed to initialize subscription service', name: 'Main', error: e);
    // Continue without subscription service - app will default to premium tier
  }

  try {
    // Initialize message counter service (RevenueCat removed)
    await MessageCounterService.instance.initialize();
    SecureLogger.success('Message counter service initialized successfully', name: 'Main');
  } catch (e) {
    SecureLogger.error('Failed to initialize message counter service', name: 'Main', error: e);
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
      theme: AppTheme.companionTheme,
      debugShowCheckedModeBanner: false,
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
