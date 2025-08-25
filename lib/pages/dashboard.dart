import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/modern_ui_components.dart';
import '../theme/app_theme.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ ORIGINAL GRADIENT BACKGROUND - keeping original colors
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCF8F1), // Original top cream
              Color(0xFFE8E0D8), // Original bottom darker cream
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ✨ ENHANCED HEADER with bold typography
                    _buildHeader(),

                    const SizedBox(height: 50),

                    // ✨ COMPACT MAIN TILES positioned closer to header
                    _buildCompactTile(
                      title: 'Chat',
                      icon: Icons.chat_bubble_outline,
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                      isPrimary: true,
                      delay: 200,
                    ),

                    const SizedBox(height: 20),

                    _buildCompactTile(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                      isPrimary: false,
                      delay: 400,
                    ),

                    // ✨ FLEXIBLE SPACER to prevent overflow
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✨ ENHANCED HEADER with bold typography
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'As-salāmu \'alaykum',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B5A3C).withValues(alpha: 0.8), // Original color
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your Safe Space',
          style: GoogleFonts.lexend(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4F372D), // Original color
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back to your personal sanctuary',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF666666), // Original color
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ✨ COMPACT TILE with minimal design
  Widget _buildCompactTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: isPrimary ? _buildPrimaryCompactTile(title, icon, onTap) : _buildSecondaryCompactTile(title, icon, onTap),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryCompactTile(String title, IconData icon, VoidCallback onTap) {
    return GlassmorphicContainer(
      borderRadius: 16,
      color: const Color(0xFF9C6644).withValues(alpha: 0.9), // Original brown
      borderColor: const Color(0xFF9C6644).withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCompactTile(String title, IconData icon, VoidCallback onTap) {
    return AnimatedCard(
      onTap: onTap,
      borderRadius: 16,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.neumorphicDecoration(
              color: const Color(0xFFFCF8F1), // Original cream
              borderRadius: 12,
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF9C6644), // Original brown
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F372D), // Original text color
                letterSpacing: -0.1,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: const Color(0xFF9C6644).withValues(alpha: 0.7), // Original brown
          ),
        ],
      ),
    );
  }


}
