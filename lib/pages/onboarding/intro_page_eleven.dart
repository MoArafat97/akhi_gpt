import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/gender_util.dart';
import '../../services/openrouter_service.dart';
import '../../services/user_api_key_service.dart';

class IntroPageEleven extends StatefulWidget {
  const IntroPageEleven({super.key});

  @override
  State<IntroPageEleven> createState() => _IntroPageElevenState();
}

class _IntroPageElevenState extends State<IntroPageEleven>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _textController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _textAnimation;
  
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  
  bool _isButtonPressed = false;
  bool _isNavigating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Fade in animation for the page
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _textController.forward();
          }
        });
      }
    });

    // Listen to text changes for validation
    _nameController.addListener(_validateName);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _errorMessage = '';
      } else if (name.length > 30) {
        _errorMessage = 'Name must be 30 characters or less';
      } else {
        _errorMessage = '';
      }
    });
  }

  Future<void> _saveName() async {
    if (_isNavigating) return;

    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    if (name.length > 30) {
      setState(() {
        _errorMessage = 'Name must be 30 characters or less';
      });
      return;
    }

    setState(() {
      _isNavigating = true;
      _isButtonPressed = true;
    });

    try {
      // Save display name
      await GenderUtil.setDisplayName(name);

      // Set default gender (Brother) for new users if not already set
      final isGenderSet = await GenderUtil.isGenderSet();
      if (!isGenderSet) {
        await GenderUtil.setUserGender(UserGender.male);
      }

      // Mark onboarding as complete (this also sets hasSeenOnboarding)
      await GenderUtil.setOnboardingComplete();

      // Navigate to main app after a brief delay
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        // Check if API setup is needed
        await _navigateToNextStep();
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _isButtonPressed = false;
          _errorMessage = 'Failed to save name. Please try again.';
        });
      }
    }
  }

  /// Navigate to the next step based on API configuration status
  Future<void> _navigateToNextStep() async {
    try {
      // Check if OpenRouter service is configured (either via environment or user API key)
      final openRouterService = OpenRouterService();
      final isServiceConfigured = await openRouterService.isConfigured;

      if (isServiceConfigured) {
        // Service is already configured, go directly to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/card_navigation',
          (route) => false,
        );
      } else {
        // Service not configured, check if user has their own API key
        final apiKeyStatus = await UserApiKeyService.instance.getApiKeyStatus();

        if (apiKeyStatus == ApiKeyStatus.notSet) {
          // Show API setup as optional step
          _showApiSetupDialog();
        } else {
          // User has API key but it might need validation, go to main app
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/card_navigation',
            (route) => false,
          );
        }
      }
    } catch (e) {
      // On error, default to main app
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/card_navigation',
        (route) => false,
      );
    }
  }

  /// Show optional API setup dialog
  void _showApiSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF7B4F2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'One More Step! 🚀',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'To start chatting with your AI companion, you\'ll need to set up your OpenRouter API key. This gives you access to powerful AI models.\n\nYou can do this now or skip and set it up later in Settings.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Skip setup, go to main app
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/card_navigation',
                  (route) => false,
                );
              },
              child: const Text(
                'Skip for Now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Go to API setup with initial setup flag
                Navigator.pushReplacementNamed(
                  context,
                  '/openrouter_setup',
                  arguments: {'isInitialSetup': true},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B4F2F),
              ),
              child: const Text('Set Up Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Title
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_textAnimation),
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: Text(
                      'What should I call you?',
                      style: GoogleFonts.lexend(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C1810),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_textAnimation),
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: Text(
                      'Enter your preferred name so I can personalize our conversations',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B5B4F),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Name input field
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_textAnimation),
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C6644).withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        maxLength: 30,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2C1810),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9C6644).withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          counterText: '',
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30),
                        ],
                        onSubmitted: (_) => _saveName(),
                      ),
                    ),
                  ),
                ),
                
                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const Spacer(),
                
                // Continue button
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_textAnimation),
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFFBC5E3A),
                          onTap: _isNavigating ? null : _saveName,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                            decoration: BoxDecoration(
                              color: _isButtonPressed
                                  ? const Color(0xFFBC5E3A)
                                  : const Color(0xFF9C6644),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isNavigating
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'TAKE ME TO MY SPACE...',
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
