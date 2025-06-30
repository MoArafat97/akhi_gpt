import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPageSevenC extends StatefulWidget {
  const IntroPageSevenC({super.key});

  @override
  State<IntroPageSevenC> createState() => _IntroPageSevenCState();
}

class _IntroPageSevenCState extends State<IntroPageSevenC>
    with TickerProviderStateMixin {
  late final AnimationController _headlineController;
  late final AnimationController _subtitleController;
  late final AnimationController _illustrationController;
  late final AnimationController _progressController;
  
  late final Animation<double> _headlineFadeAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _illustrationFadeAnimation;
  late final Animation<Offset> _illustrationSlideAnimation;
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

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly longer for smoother animation
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

    // Illustration animations - optimized for smoother performance
    _illustrationFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _illustrationController,
      curve: Curves.easeOutCubic,
    ));

    _illustrationSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _illustrationController,
      curve: Curves.easeOutCubic,
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
    if (mounted) _illustrationController.forward();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _subtitleController.dispose();
    _illustrationController.dispose();
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
        // Page 7C dot (active) - with scale animation
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
      ],
    );
  }

  Widget _buildSafeSpaceIllustration() {
    return FadeTransition(
      opacity: _illustrationFadeAnimation,
      child: SlideTransition(
        position: _illustrationSlideAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1EC), // Taupe card background (matching other pages)
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Safe space icon illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C6644).withValues(alpha: 0.15), // Taupe brown
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer circle - representing protection
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C6644).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    // Inner heart - representing care and listening
                    const Icon(
                      Icons.favorite_rounded,
                      size: 40,
                      color: Color(0xFF9C6644), // Earth brown (matching other pages)
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supporting text with subtle emphasis
              Text(
                'A space where your voice matters',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A6659), // Taupe brown (matching other pages)
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Three pillars of safe space
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillarIcon(Icons.lock_outline, 'Private'),
                  _buildPillarIcon(Icons.hearing, 'Heard'),
                  _buildPillarIcon(Icons.psychology_outlined, 'Understood'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9C6644).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF9C6644),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7A6659), // Taupe brown (matching other pages)
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Taupe gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCF8F1), // Top cream (matching other pages)
              Color(0xFFE8E0D8), // Bottom darker cream (matching other pages)
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

              // ✨ FEATURE: Animated progress indicator dots (9 dots, page 7C active)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildProgressDots(),
              ),

              // Main content - using SingleChildScrollView for better responsiveness
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ✨ HEADLINE: Animated fade+slide
                      FadeTransition(
                        opacity: _headlineFadeAnimation,
                        child: SlideTransition(
                          position: _headlineSlideAnimation,
                          child: Text(
                            'Everyone Deserves\na Safe Space',
                            style: GoogleFonts.lexend(
                              fontSize: 32,
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
                          'Muslim men and women need a place to express themselves when they cannot do so at home, or when no one is willing to listen.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFF7A6659),
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ✨ SAFE SPACE ILLUSTRATION: Visual representation
                      _buildSafeSpaceIllustration(),

                      const SizedBox(height: 80), // Extra space for button
                    ],
                  ),
                ),
              ),

              // ✨ CONTINUE BUTTON: Fixed at bottom with safe area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE8E0D8).withValues(alpha: 0.0),
                      const Color(0xFFE8E0D8),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
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
                        splashColor: const Color(0xFFBC5E3A), // Earth brown ripple (matching other pages)
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
                              // ✨ NAVIGATION: Navigate to page 8 (formerly page 7)
                              navigator.pushNamed('/onboard8');
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                          decoration: BoxDecoration(
                            color: _isButtonPressed
                                ? const Color(0xFF8E5837) // Darker brown when pressed (matching other pages)
                                : const Color(0xFF9C6644), // Earth brown (matching other pages)
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'THAT\'S WHERE WE COME IN',
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFCF8F1), // Cream text (matching other pages)
                              ),
                            ),
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
