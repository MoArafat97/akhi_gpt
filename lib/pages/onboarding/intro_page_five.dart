import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPageFive extends StatefulWidget {
  const IntroPageFive({super.key});

  @override
  State<IntroPageFive> createState() => _IntroPageFiveState();
}

class _IntroPageFiveState extends State<IntroPageFive>
    with TickerProviderStateMixin {
  late final AnimationController _headlineController;
  late final AnimationController _researchController;
  late final AnimationController _chartController;
  late final Animation<double> _headlineFadeAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<double> _research1FadeAnimation;
  late final Animation<double> _research2FadeAnimation;
  late final Animation<double> _muslimCircleAnimation;
  late final Animation<double> _nonMuslimCircleAnimation;
  late final Animation<int> _muslimPercentageAnimation;
  late final Animation<int> _nonMuslimPercentageAnimation;

  // Button press animation state
  bool _isPressed = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    // Headline animation controller
    _headlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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

    // Research text animation controller
    _researchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _research1FadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _researchController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _research2FadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _researchController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    // Chart animation controller
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Longer for smoother counting
    );

    _muslimCircleAnimation = Tween<double>(
      begin: 0.0,
      end: 0.33, // 33%
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));

    _nonMuslimCircleAnimation = Tween<double>(
      begin: 0.0,
      end: 0.10, // 10%
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));

    _muslimPercentageAnimation = IntTween(
      begin: 0,
      end: 33,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));

    _nonMuslimPercentageAnimation = IntTween(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _headlineController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _researchController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _chartController.forward();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _researchController.dispose();
    _chartController.dispose();
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
        // Page 5 dot (active)
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

  Widget _buildCircularChart() {
    const double circleSize = 120.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Muslim Men Circle
          Column(
            children: [
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5F1EC),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Animated circular progress
                    AnimatedBuilder(
                      animation: _muslimCircleAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: CircularProgressIndicator(
                            value: _muslimCircleAnimation.value,
                            strokeWidth: 8.0,
                            backgroundColor: const Color(0xFFE0D5C7),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFCC5500), // Main burnt orange
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated percentage text
                    AnimatedBuilder(
                      animation: _muslimPercentageAnimation,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_muslimPercentageAnimation.value}%',
                              style: GoogleFonts.rubik(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F372D),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Muslim Men',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4F372D),
                ),
              ),
            ],
          ),
          // Non-Muslim Men Circle
          Column(
            children: [
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5F1EC),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Animated circular progress
                    AnimatedBuilder(
                      animation: _nonMuslimCircleAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: CircularProgressIndicator(
                            value: _nonMuslimCircleAnimation.value,
                            strokeWidth: 8.0,
                            backgroundColor: const Color(0xFFE0D5C7),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFCC5500), // Medium burnt orange
                            ),
                          ),
                        );
                      },
                    ),
                    // Animated percentage text
                    AnimatedBuilder(
                      animation: _nonMuslimPercentageAnimation,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_nonMuslimPercentageAnimation.value}%',
                              style: GoogleFonts.rubik(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F372D),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Non-Muslim Men',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4F372D),
                ),
              ),
            ],
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

              // ✨ FEATURE: Animated progress indicator dots (5 dots, page 5 active)
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
                            'TRUE REALITY...',
                            style: GoogleFonts.rubik(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F372D),
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✨ RESEARCH BULLETS: Sequential fade-in
                      FadeTransition(
                        opacity: _research1FadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: const Color(0xFF7A6659),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Up to 33% of Muslim men report depressive symptoms, compared to about 10% of non-Muslim men.',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFF7A6659),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      FadeTransition(
                        opacity: _research2FadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: const Color(0xFF7A6659),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Factors include discrimination, socioeconomic stress, and stigma around seeking help.',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFF7A6659),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ✨ CIRCULAR CHART: Animated circular progress indicators
                      _buildCircularChart(),
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
                            // ✨ NAVIGATION: Navigate to next page
                            navigator.pushNamed('/onboard6');
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
                          'I NEED MORE DATA',
                          style: GoogleFonts.rubik(
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
