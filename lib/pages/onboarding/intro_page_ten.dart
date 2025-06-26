import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/gender_util.dart';

class IntroPageTen extends StatefulWidget {
  const IntroPageTen({super.key});

  @override
  State<IntroPageTen> createState() => _IntroPageTenState();
}

class _IntroPageTenState extends State<IntroPageTen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  // Button press animation states
  bool _isBrotherPressed = false;
  bool _isSisterPressed = false;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();

    // Fade in animation for the page
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start fade in animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectGender(UserGender gender) async {
    if (_isSelecting) return;

    setState(() {
      _isSelecting = true;
      if (gender == UserGender.male) {
        _isBrotherPressed = true;
      } else {
        _isSisterPressed = true;
      }
    });

    try {
      // Save gender preference
      await GenderUtil.setUserGender(gender);
      
      // Navigate to main app after a brief delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/card_navigation',
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        setState(() {
          _isSelecting = false;
          _isBrotherPressed = false;
          _isSisterPressed = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;
    
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
        child: SafeArea(
          child: Stack(
            children: [
              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF8F1).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Choose Your Companion',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F372D),
                          letterSpacing: 1.2,
                          height: 1.3,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Who would you like to chat with?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4F372D).withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Gender selection cards
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Brother option
                            _buildGenderCard(
                              gender: UserGender.male,
                              title: 'Brother',
                              description: 'A supportive older brother who understands your journey',
                              icon: Icons.person,
                              color: const Color(0xFF9C6644),
                              isPressed: _isBrotherPressed,
                              isEnabled: !_isSelecting,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Sister option
                            _buildGenderCard(
                              gender: UserGender.female,
                              title: 'Sister',
                              description: 'A caring older sister who shares your experiences',
                              icon: Icons.person,
                              color: const Color(0xFFB7AFA3),
                              isPressed: _isSisterPressed,
                              isEnabled: !_isSelecting,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required UserGender gender,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isPressed,
    required bool isEnabled,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: isPressed ? 0.95 : 1.0,
      curve: Curves.easeInOut,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isEnabled ? () => _selectGender(gender) : null,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPressed ? color.withValues(alpha: 0.9) : color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Loading indicator or arrow
                if (_isSelecting && isPressed)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
