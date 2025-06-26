import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✨ ANIMATION: Character-by-character typewriter animation
const _fullText = "ARE YOU READY?";

class IntroPageNine extends StatefulWidget {
  const IntroPageNine({super.key});

  @override
  State<IntroPageNine> createState() => _IntroPageNineState();
}

class _IntroPageNineState extends State<IntroPageNine>
    with TickerProviderStateMixin {
  late final AnimationController _typewriterController;
  late final Animation<int> _typewriterAnimation;
  String _displayedText = "";

  // Button press animation state
  bool _isPressed = false;
  bool _isButtonPressed = false;
  bool _showButtonFallback = false;

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

    // Fallback timeout to show button after animation completes + buffer
    Future.delayed(Duration(milliseconds: typingDuration + 1000), () {
      if (mounted && !_showButtonFallback) {
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

  bool get _isTypingComplete => _typewriterController.isCompleted;

  Widget _buildProgressDots() {
    return Row(
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
        const SizedBox(width: 8),
        // Page 4 dot (inactive)
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
        // Page 5 dot (inactive)
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
        // Page 6 dot (inactive)
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
        // Page 7A dot (inactive)
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
        // Page 7B dot (inactive)
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
        // Page 7 dot (inactive)
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
        // Page 8 dot (inactive)
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
        // Page 7C dot (inactive)
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
        // Page 8 dot (inactive)
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
        // Page 9 dot (inactive)
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
        // Page 10 dot (active) - this is the current page
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
    );
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

                // ✨ FEATURE: Animated progress indicator dots (11 dots, page 10 active)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildProgressDots(),
                ),

                // ✨ FEATURE: Character-by-character typewriter animation (36sp, left-aligned)
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
                              fontSize: 36,
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

                // ✨ CONTINUE BUTTON: Card + InkWell + AnimatedScale
                // Show button after animation completes OR after fallback timeout
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
                                    // ✨ NAVIGATION: Navigate to gender selection page (now page 11)
                                    navigator.pushNamed('/onboard11');
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
                                  'Yes...',
                                  style: GoogleFonts.lexend(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFFCF8F1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
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
