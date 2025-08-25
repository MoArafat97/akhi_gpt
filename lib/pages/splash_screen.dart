import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/terms_acceptance_service.dart';

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
      // Check if user has accepted terms and conditions
      final hasAcceptedTerms = await TermsAcceptanceService.hasAcceptedTerms();

      if (hasAcceptedTerms) {
        // User has accepted terms, navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // User needs to accept terms first
        Navigator.pushReplacementNamed(context, '/terms_conditions');
      }
    } catch (e) {
      // On error, assume terms not accepted for safety
      developer.log('Failed to check terms acceptance in splash: $e', name: 'SplashScreen');
      Navigator.pushReplacementNamed(context, '/terms_conditions');
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
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'images/nafs-ai.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
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
