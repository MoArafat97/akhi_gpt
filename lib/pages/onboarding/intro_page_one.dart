import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✨ ANIMATION: 3-word segments for improved typewriter animation
const _fullText = "DON'T HAVE ANYONE TO TALK TO?";

class IntroPageOne extends StatefulWidget {
  const IntroPageOne({super.key});

  @override
  State<IntroPageOne> createState() => _IntroPageOneState();
}

class _IntroPageOneState extends State<IntroPageOne>
    with TickerProviderStateMixin {
  late final AnimationController _typewriterController;
  late final Animation<int> _typewriterAnimation;
  String _displayedText = "";

  // Button press animation state
  bool _isPressed = false;
  bool _isButtonPressed = false; // For color-shift effect
  bool _showButtonFallback = false; // Fallback to show button after timeout

  @override
  void initState() {
    super.initState();

    // Character-by-character typewriter effect
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Slower typing duration (4 seconds)
    );

    _typewriterAnimation = IntTween(
      begin: 0,
      end: _fullText.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeInOut,
    ))..addListener(() {
      setState(() {
        _displayedText = _fullText.substring(0, _typewriterAnimation.value);
      });
    });

    // Start animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _typewriterController.forward();
      }
    });

    // Fallback timer to show button after 4.5 seconds regardless of animation state
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && !_isTypingComplete) {
        setState(() {
          _showButtonFallback = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  // Check if typewriter animation is complete
  bool get _isTypingComplete {
    return _typewriterController.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Vertical gradient background (top cream → bottom darker cream)
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
        child: GestureDetector(
          // Tap anywhere to skip animation and show button
          onTap: () {
            if (!_isTypingComplete && !_showButtonFallback) {
              _typewriterController.forward();
              setState(() {
                _showButtonFallback = true;
              });
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // ✨ TESTING: Skip button for direct navigation to card navigation
                Positioned(
                  top: 8,
                  right: 16,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/card_navigation');
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF9C6644).withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9C6644),
                      ),
                    ),
                  ),
                ),

                // Main content column
                Column(
                children: [
                  // ✨ FEATURE: Animated progress indicator dots (3 dots, active/inactive states)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page 1 dot (active)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCC5500), // Active burnt orange
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Page 2 dot (inactive)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD0C5BA), // Inactive light brown
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Page 3 dot (inactive)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD0C5BA), // Inactive light brown
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              // ✨ FEATURE: 3-word segment typewriter animation (36sp, fade + slide effects)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start, // Left alignment as originally intended
                    children: [
                        // ✨ TYPOGRAPHY: Enhanced 3-word segments with improved spacing and timing
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _displayedText,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.lexend(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F372D),
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ✨ FEATURE: Enhanced button with card wrapper, ripple, scale, and color-shift effects
              // Show button after animation completes OR after 2 seconds as fallback
              AnimatedBuilder(
                animation: _typewriterController,
                builder: (context, child) {
                  if (_isTypingComplete || _showButtonFallback) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 100),
                        scale: _isPressed ? 0.95 : 1.0,
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: const Color(0xFFBC5E3A), // Ripple effect color
                            onTap: () {
                              // Button press animation and color-shift
                              setState(() {
                                _isPressed = true;
                                _isButtonPressed = true;
                              });
                              // Store context before async operation
                              final navigator = Navigator.of(context);
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  setState(() {
                                    _isPressed = false;
                                    _isButtonPressed = false;
                                  });
                                  // ✨ NAVIGATION: Direct navigation to IntroPageTwo
                                  navigator.pushNamed('/onboard2');
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                              decoration: BoxDecoration(
                                color: _isButtonPressed
                                    ? const Color(0xFF8E5837) // Darker brown when pressed
                                    : const Color(0xFF9C6644), // Normal earth brown
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'NOT REALLY...',
                                style: GoogleFonts.lexend(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500, // Medium weight
                                  color: const Color(0xFFFCF8F1), // Cream text
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Show placeholder while animation is running
                    return const SizedBox(height: 60); // Reserve space for button
                  }
                },
              ),
            ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

