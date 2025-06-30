import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPageSix extends StatefulWidget {
  const IntroPageSix({super.key});

  @override
  State<IntroPageSix> createState() => _IntroPageSixState();
}

class _IntroPageSixState extends State<IntroPageSix>
    with TickerProviderStateMixin {
  late final AnimationController _headlineController;
  late final AnimationController _subtitleController;
  late final AnimationController _countersController;
  late final AnimationController _progressController;
  
  late final Animation<double> _headlineFadeAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _counter1Animation;
  late final Animation<double> _counter2Animation;
  late final Animation<double> _counter3Animation;
  late final Animation<double> _progressScaleAnimation;

  // Button press animation state
  bool _isPressed = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _headlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _countersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // Longer for smoother counting
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Headline animations
    _headlineFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headlineController,
      curve: Curves.easeInOut,
    ));

    _headlineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headlineController,
      curve: Curves.easeInOut,
    ));

    // Subtitle animation
    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    ));

    // Counter animations (33%, 60%, 70%) - optimized for smoother performance
    _counter1Animation = Tween<double>(
      begin: 0.0,
      end: 33.0,
    ).animate(CurvedAnimation(
      parent: _countersController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _counter2Animation = Tween<double>(
      begin: 0.0,
      end: 60.0,
    ).animate(CurvedAnimation(
      parent: _countersController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _counter3Animation = Tween<double>(
      begin: 0.0,
      end: 70.0,
    ).animate(CurvedAnimation(
      parent: _countersController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    // Progress dot scale animation
    _progressScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.elasticOut,
    ));

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Progress dot animation first
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _headlineController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _subtitleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _countersController.forward();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _subtitleController.dispose();
    _countersController.dispose();
    _progressController.dispose();
    super.dispose();
  }

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
        // Page 6 dot (active) - with scale animation
        AnimatedBuilder(
          animation: _progressScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _progressScaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFCC5500), // Active burnt orange
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
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
      ],
    );
  }

  Widget _buildAnimatedCounters() {
    return Column(
      children: [
        // First counter: 33% depression
        AnimatedBuilder(
          animation: _counter1Animation,
          builder: (context, child) {
            return _buildCounterCard(
              _counter1Animation.value,
              'report depression',
              Icons.sentiment_very_dissatisfied,
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Second counter: 60% discrimination
        AnimatedBuilder(
          animation: _counter2Animation,
          builder: (context, child) {
            return _buildCounterCard(
              _counter2Animation.value,
              'face discrimination',
              Icons.heart_broken,
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Third counter: 70% never speak out
        AnimatedBuilder(
          animation: _counter3Animation,
          builder: (context, child) {
            return _buildCounterCard(
              _counter3Animation.value,
              'never speak out',
              Icons.speaker_notes_off,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCounterCard(double value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1EC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C6644).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: const Color(0xFF9C6644),
            ),
          ),
          const SizedBox(width: 20),

          // Counter and label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.lexend(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F372D),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7A6659),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

              // ✨ FEATURE: Animated progress indicator dots (8 dots, page 6 active)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildProgressDots(),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✨ HEADLINE: Animated fade+slide
                      FadeTransition(
                        opacity: _headlineFadeAnimation,
                        child: SlideTransition(
                          position: _headlineSlideAnimation,
                          child: Text(
                            'Here\'s more data',
                            style: GoogleFonts.lexend(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F372D),
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✨ SUBTITLE: Delayed fade-in
                      FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: Text(
                          'Truths you deserve to know',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFF7A6659),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ✨ ANIMATED COUNTERS: Three data points with icons
                      _buildAnimatedCounters(),
                    ],
                  ),
                ),
              ),

              // ✨ CONTINUE BUTTON: Card + InkWell + AnimatedScale
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
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
                            // ✨ NAVIGATION: Navigate to first statistics page
                            navigator.pushNamed('/onboard7a');
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
                          'THEN... WHAT ABOUT THE SISTERS?',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
