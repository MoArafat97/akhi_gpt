import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page.dart';
import 'settings_page.dart';
import '../utils/gender_util.dart';
import '../services/settings_service.dart';
import '../services/terms_acceptance_service.dart';

// Navigation card data structure
class _NavCard {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  const _NavCard(this.title, this.icon, this.color, this.destination);

  // Non-const constructor for dynamic titles
  _NavCard.dynamic(this.title, this.icon, this.color, this.destination);
}

class CardNavigationPage extends StatefulWidget {
  const CardNavigationPage({super.key});

  @override
  State<CardNavigationPage> createState() => _CardNavigationPageState();
}

class _CardNavigationPageState extends State<CardNavigationPage>
    with TickerProviderStateMixin {
  // Dynamic card data that will be built with user's name
  List<_NavCard> _cards = [];
  bool _isDeveloperMode = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    // Validate Terms acceptance before allowing access
    _validateTermsAcceptance();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buildCards();
    _loadDeveloperMode();

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Validate Terms and Conditions acceptance
  /// This is a legal compliance requirement - user must accept terms to access app
  Future<void> _validateTermsAcceptance() async {
    try {
      final hasAcceptedTerms = await TermsAcceptanceService.hasAcceptedTerms();

      if (!hasAcceptedTerms && mounted) {
        // User has not accepted terms, redirect to Terms page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/terms_conditions');
        });
      }
    } catch (e) {
      // On error, assume terms not accepted for safety
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/terms_conditions');
        });
      }
    }
  }

  /// Load developer mode state
  Future<void> _loadDeveloperMode() async {
    final isDeveloper = await SettingsService.isDeveloperModeEnabled();
    if (mounted) {
      setState(() {
        _isDeveloperMode = isDeveloper;
      });
    }
  }

  // Build cards with simplified titles
  Future<void> _buildCards() async {
    print('🐛 DEBUG: Building cards with simplified titles');

    if (mounted) {
      setState(() {
        _cards = [
          _NavCard('Chat', Icons.chat_bubble_outline, const Color(0xFF7B4F2F), const ChatPage()),
          _NavCard('Settings', Icons.settings, const Color(0xFFB7AFA3), const SettingsPage()),
        ];
        print('🐛 DEBUG: Cards built successfully. Count: ${_cards.length}');
        for (int i = 0; i < _cards.length; i++) {
          print('🐛 DEBUG: Card $i: ${_cards[i].title}');
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Vertical gradient background matching onboarding pages with floating elements
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
        child: Stack(
          children: [
            // ✨ FLOATING ELEMENTS: Subtle geometric shapes for visual interest
            Positioned(
              top: 120,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9C6644).withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7B4F2F).withOpacity(0.02),
                ),
              ),
            ),
            
            // ✨ MAIN CONTENT: With fade animation
            SafeArea(
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ HEADING SECTION: Enhanced typography with Islamic greeting
                    _buildHeadingSection(),

                    // ✨ SIMPLE CARD STACK: Static cards with direct navigation
                    Expanded(
                      child: _buildSimpleCardStack(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build heading section with enhanced typography and Islamic greeting
  Widget _buildHeadingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0), // More breathing room
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced title section with greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✨ ISLAMIC GREETING: With gentle animation
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'As-salāmu ʿalaykum', // Islamic greeting
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9C6644).withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ✨ ENHANCED MAIN TITLE: Larger, stronger, better spacing
                Text(
                  'Your Dashboard',
                  style: GoogleFonts.lexend(
                    fontSize: 42, // Slightly larger for more impact
                    fontWeight: FontWeight.w700, // Stronger weight
                    color: const Color(0xFF4F372D),
                    letterSpacing: -0.5, // Tighter letter spacing for elegance
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                // ✨ SUBTLE ACCENT: Underline for visual hierarchy
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C6644).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // ✨ TEST BUTTON: Access onboarding pages for testing (developer mode only)
          if (_isDeveloperMode)
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () async {
                  if (await SettingsService.canAccessDeveloperRoute('/onboard1')) {
                    Navigator.pushNamed(context, '/onboard1');
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF9C6644).withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: const Color(0xFF9C6644),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Test Onboarding',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9C6644),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build simple card stack with direct navigation
  Widget _buildSimpleCardStack(BuildContext context) {
    // Show loading indicator while cards are being built
    if (_cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9C6644),
          strokeWidth: 3,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: _cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              // Staggered animation for each card
              final animationDelay = index * 0.1;
              final slideAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Interval(
                  animationDelay,
                  (animationDelay + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ));

              return AnimatedBuilder(
                animation: slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - slideAnimation.value) * 50),
                    child: Opacity(
                      opacity: slideAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildSimpleCard(context, card, index),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Build simple card with direct navigation
  Widget _buildSimpleCard(BuildContext context, _NavCard card, int index) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => isPressed = true),
            onTapUp: (_) => setState(() => isPressed = false),
            onTapCancel: () => setState(() => isPressed = false),
            onTap: () => _navigateToCard(context, card),
            child: AnimatedScale(
              scale: isPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      card.color,
                      card.color.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      color: card.color.withOpacity(0.25),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      blurRadius: 24,
                      offset: Offset(0, 8 + (index * 2)),
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(
                        card.icon,
                        size: 120,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              card.icon,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.title,
                                  style: GoogleFonts.lexend(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getCardSubtitle(card.title),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  /// Helper method to get contextual subtitles for cards
  String _getCardSubtitle(String title) {
    if (title == 'Chat') return 'Start a conversation';
    if (title == 'Settings') return 'Customize your experience';
    if (title == '🧪 Test Onboarding') return 'Development mode';
    return 'Tap to explore';
  }



  /// Navigate to card destination with enhanced navigation
  void _navigateToCard(BuildContext context, _NavCard card) {
    print('🐛 DEBUG: Navigating to card: ${card.title}');
    print('🐛 DEBUG: Card destination type: ${card.destination.runtimeType}');
    
    // Handle special case for test onboarding card
    if (card.title == '🧪 Test Onboarding') {
      Navigator.pushNamed(context, '/onboard1');
      return;
    }

    // Navigate to destination page with card color
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          // Pass the card color to each destination page, except ChatPage which should keep cream background
          if (card.destination is ChatPage) {
            print('🐛 DEBUG: Navigating to ChatPage');
            return const ChatPage(); // Use default cream background
          } else if (card.destination is SettingsPage) {
            print('🐛 DEBUG: Navigating to SettingsPage');
            return SettingsPage(bgColor: card.color);
          } else {
            print('🐛 DEBUG: Navigating to generic destination');
            return card.destination;
          }
        },
      ),
    );
  }
}

