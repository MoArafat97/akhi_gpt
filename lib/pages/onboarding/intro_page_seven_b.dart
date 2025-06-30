import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPageSevenB extends StatefulWidget {
  const IntroPageSevenB({super.key});

  @override
  State<IntroPageSevenB> createState() => _IntroPageSevenBState();
}

class _IntroPageSevenBState extends State<IntroPageSevenB>
    with TickerProviderStateMixin {
  late final AnimationController _headlineController;
  late final AnimationController _subtitleController;
  late final AnimationController _chartsController;
  late final AnimationController _progressController;
  
  late final Animation<double> _headlineFadeAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _chart1Animation;
  late final Animation<double> _chart2Animation;
  late final Animation<double> _chart3Animation;
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

    _chartsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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

    // Chart animations (44%, 84%, 52%) - optimized for smoother performance
    _chart1Animation = Tween<double>(
      begin: 0.0,
      end: 44.0,
    ).animate(CurvedAnimation(
      parent: _chartsController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _chart2Animation = Tween<double>(
      begin: 0.0,
      end: 84.0,
    ).animate(CurvedAnimation(
      parent: _chartsController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    _chart3Animation = Tween<double>(
      begin: 0.0,
      end: 52.0,
    ).animate(CurvedAnimation(
      parent: _chartsController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
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
    if (mounted) _chartsController.forward();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _subtitleController.dispose();
    _chartsController.dispose();
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
        // Page 7B dot (active) - with scale animation
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

  Widget _buildAnimatedCharts() {
    return Column(
      children: [
        // First chart: 44% of religious hate crimes target Muslims
        AnimatedBuilder(
          animation: _chart1Animation,
          builder: (context, child) {
            return _buildCompactStatisticCard(
              _chart1Animation.value,
              'of all religious hate crimes (3,400 offenses)',
              'Muslims account for',
              Icons.gavel,
              const Color(0xFF8E44AD), // Purple color for legal statistic
            );
          },
        ),
        const SizedBox(height: 24),

        // Second chart: 84% experienced direct verbal abuse
        AnimatedBuilder(
          animation: _chart2Animation,
          builder: (context, child) {
            return _buildCompactStatisticCard(
              _chart2Animation.value,
              'of British Muslims experienced direct verbal abuse',
              '',
              Icons.speaker_notes_off,
              const Color(0xFFE74C3C), // Red color for abuse statistic
            );
          },
        ),
        const SizedBox(height: 24),

        // Third chart: 52% experienced hostility on the street
        AnimatedBuilder(
          animation: _chart3Animation,
          builder: (context, child) {
            return _buildCompactStatisticCard(
              _chart3Animation.value,
              'experienced hostility on the street',
              '',
              Icons.directions_walk,
              const Color(0xFFE67E22), // Orange color for street hostility
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactStatisticCard(double value, String label, String prefix, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
          // Icon with accent color background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prefix.isNotEmpty) ...[
                  Text(
                    prefix,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7A6659),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${value.toInt()}%',
                      style: GoogleFonts.lexend(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4F372D),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
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

              // ✨ FEATURE: Animated progress indicator dots (8 dots, page 7B active)
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
                      const SizedBox(height: 20),

                      // ✨ HEADLINE: Animated fade+slide
                      FadeTransition(
                        opacity: _headlineFadeAnimation,
                        child: SlideTransition(
                          position: _headlineSlideAnimation,
                          child: Text(
                            'The Broader Picture',
                            style: GoogleFonts.lexend(
                              fontSize: 32, // Slightly smaller for better fit
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F372D),
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✨ SUBTITLE: Delayed fade-in
                      FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: Text(
                          'Understanding the full scope of discrimination',
                          style: GoogleFonts.inter(
                            fontSize: 16, // Slightly smaller for better fit
                            color: const Color(0xFF7A6659),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✨ ANIMATED CHARTS: Three additional statistics
                      _buildAnimatedCharts(),

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
                              // ✨ NAVIGATION: Navigate to page 7C (safe space page)
                              navigator.pushNamed('/onboard7c');
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
                          child: Center(
                            child: Text(
                              'NOW YOU KNOW...',
                              style: GoogleFonts.lexend(
                                fontSize: 16, // Slightly smaller
                                fontWeight: FontWeight.w500, // Medium weight
                                color: const Color(0xFFFCF8F1), // Cream text
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
