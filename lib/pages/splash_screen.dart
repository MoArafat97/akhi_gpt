import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/gender_util.dart';
import '../services/user_api_key_service.dart';
import '../services/openrouter_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkGenderAndNavigate();
  }

  Future<void> _checkGenderAndNavigate() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      // Check if user has ever seen onboarding (this ensures onboarding is shown exactly once)
      final hasSeenOnboarding = await GenderUtil.hasSeenOnboarding();

      if (!hasSeenOnboarding) {
        // User has never seen onboarding, show it and mark as seen
        await GenderUtil.setHasSeenOnboarding();
        Navigator.pushReplacementNamed(context, '/onboard1');
        return;
      }

      // Check if OpenRouter service is configured (either via environment or user API key)
      final openRouterService = OpenRouterService();
      final isServiceConfigured = await openRouterService.isConfigured;

      if (isServiceConfigured) {
        // Service is configured (via environment or user key), go to main app
        Navigator.pushReplacementNamed(context, '/card_navigation');
      } else {
        // Service not configured, check if user has their own API key
        final apiKeyStatus = await UserApiKeyService.instance.getApiKeyStatus();

        if (apiKeyStatus == ApiKeyStatus.notSet) {
          // User needs to set up their API key
          Navigator.pushReplacementNamed(context, '/openrouter_setup');
        } else {
          // User has API key, go to main app
          Navigator.pushReplacementNamed(context, '/card_navigation');
        }
      }
    } catch (e) {
      // On error, default to onboarding
      Navigator.pushReplacementNamed(context, '/onboard1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCF8F1), // Top cream
              Color(0xFFE8E0D8), // Bottom darker cream
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C6644),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App title
              Text(
                'NafsAI',
                style: GoogleFonts.lexend(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F372D),
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Your supportive companion',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4F372D).withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C6644)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
