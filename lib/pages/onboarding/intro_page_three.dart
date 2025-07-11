import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✨ ANIMATION: Character-by-character typewriter animation
const _fullText = "DON'T WORRY YOU'RE NOT ALONE";

class IntroPageThree extends StatefulWidget {
  const IntroPageThree({super.key});

  @override
  State<IntroPageThree> createState() => _IntroPageThreeState();
}

class _IntroPageThreeState extends State<IntroPageThree>
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

    // Optimized character-by-character typewriter effect
    // Using 60ms per character for smooth, natural typing speed
    final typingDuration = (_fullText.length * 60).clamp(2000, 4000);

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: typingDuration),
    );

    _typewriterAnimation = IntTween(
      begin: 0,
      end: _fullText.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeOut, // Smoother curve for natural typing feel
    ))..addListener(() {
      // Optimize: Only update if the character index actually changed
      final newText = _fullText.substring(0, _typewriterAnimation.value);
      if (newText != _displayedText) {
        setState(() {
          _displayedText = newText;
        });
      }
    });

    // Start animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _typewriterController.forward();
      }
    });

    // Fallback timer to show button after animation completes + buffer
    Future.delayed(Duration(milliseconds: typingDuration + 1000), () {
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
            child: Column(
            children: [
              // ✨ BACK BUTTON: Top-left back arrow with matching style
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 28,
                      color: Color(0xFF4F372D),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ✨ FEATURE: Animated progress indicator dots (3 dots, page 3 active)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page 1 dot (inactive)
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
                    // Page 3 dot (active)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCC5500), // Active burnt orange
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              // ✨ FEATURE: Character-by-character typewriter animation (48sp, left-aligned)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start, // Left alignment as originally intended
                    children: [
                      // ✨ TYPOGRAPHY: Enhanced character-by-character typewriter with left positioning
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
              // Show button after animation completes OR after 4.5 seconds as fallback
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
                                  // ✨ NAVIGATION: Navigate to fourth page
                                  navigator.pushNamed('/onboard4');
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
                                'NO THAT\'S NOT TRUE',
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
          ),
        ),
      ),
    );
  }
}
