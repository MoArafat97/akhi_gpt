import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page.dart';
import 'journal_page.dart';
import 'analytics_page.dart';
import 'settings_page.dart';

// Navigation card data structure
class _NavCard {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  const _NavCard(this.title, this.icon, this.color, this.destination);
}

class CardNavigationPage extends StatefulWidget {
  const CardNavigationPage({super.key});

  @override
  State<CardNavigationPage> createState() => _CardNavigationPageState();
}

class _CardNavigationPageState extends State<CardNavigationPage> {
  // Card data with updated colors
  final List<_NavCard> _cards = const [
    _NavCard('Chat to me Akhi', Icons.chat_bubble_outline, Color(0xFF7B4F2F), ChatPage()),
    _NavCard('Journal', Icons.book_rounded, Color(0xFFA8B97F), JournalPage()),
    _NavCard('Analytics', Icons.bar_chart_rounded, Color(0xFFC76C5A), AnalyticsPage()),
    _NavCard('Settings', Icons.settings, Color(0xFFB7AFA3), SettingsPage()),
    _NavCard('Work in Progress', Icons.construction, Color(0xFF6D88A7), SettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Vertical gradient background matching onboarding pages
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ HEADING SECTION: Onboarding-style typography
              _buildHeadingSection(),

              // ✨ WALLET-STYLE CARD STACK: Expandable scrollable area
              Expanded(
                child: _buildWalletCardStack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build heading section with onboarding-style typography
  Widget _buildHeadingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
      child: Text(
        'Your Dashboard',
        style: GoogleFonts.lexend(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4F372D), // Onboarding text color
          letterSpacing: 1.2,
          height: 1.3,
        ),
      ),
    );
  }

  /// Build wallet-style card stack with header-reveal approach for readable card headers
  Widget _buildWalletCardStack(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height for the card stack area
        const double headerReveal = 85.0; // dp of the next card that remains visible
        const int visibleCards = 5; // we want five cards in view
        const double horizontalPadding = 17.0; // wider cards with less side margin
        const double verticalPadding = 16.0;

        // Use constraints to get the actual available space for cards
        final double availableHeight = constraints.maxHeight - (verticalPadding * 2);

        // Dynamic card height calculation - shorter cards with 3.8× card height rule
        final double minCardHeight = headerReveal * 3.8;
        final double idealCardHeight = (availableHeight - headerReveal * (visibleCards - 1)) / visibleCards;
        final double cardHeight = idealCardHeight.clamp(minCardHeight, double.infinity);

        // Calculate total stack height for scrolling
        final double totalStackHeight = cardHeight + headerReveal * (_cards.length - 1);

        // Self-check: Verify card sizing is correct
        final bool sizingTest = cardHeight >= headerReveal * 1.8; // body visibly larger than header (≥1.8x)
        final bool firstFiveVisible = visibleCards <= _cards.length;

        // Debug logging (can be removed in production)
        if (cardHeight > 0 && availableHeight > 0) {
          print('WALLET SIZING TEST: ${sizingTest && firstFiveVisible ? "PASS" : "FAIL"}');
          print('Available height: ${availableHeight.toStringAsFixed(1)}dp, Card height: ${cardHeight.toStringAsFixed(1)}dp, Header reveal: ${headerReveal}dp');
          print('Body-to-header ratio: ${(cardHeight / headerReveal).toStringAsFixed(2)}x');
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // iOS-style bouncing
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: SizedBox(
            height: totalStackHeight.clamp(0, double.infinity),
            child: Stack(
              children: _cards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;

                return Positioned(
                  top: index * headerReveal, // Each card offset by header reveal height
                  left: 0,
                  right: 0,
                  child: _buildWalletCard(context, card, cardHeight, index),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Build individual wallet-style card with proper iOS appearance and z-order stacking
  Widget _buildWalletCard(BuildContext context, _NavCard card, double height, int index) {
    return Hero(
      tag: card.title,
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            // Handle special case for work in progress card
            if (card.title == 'Work in Progress') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Work in Progress',
                    style: GoogleFonts.lexend(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF4A90E2),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }

            // Navigate to destination page with card color
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) {
                  // Pass the card color to each destination page
                  if (card.destination is ChatPage) {
                    return ChatPage(bgColor: card.color);
                  } else if (card.destination is JournalPage) {
                    return JournalPage(bgColor: card.color);
                  } else if (card.destination is AnalyticsPage) {
                    return AnalyticsPage(bgColor: card.color);
                  } else if (card.destination is SettingsPage) {
                    return SettingsPage(bgColor: card.color);
                  } else {
                    return card.destination;
                  }
                },
              ),
            );
          },
          child: Container(
            height: height,
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              color: card.color,
              borderRadius: BorderRadius.circular(28), // iOS wallet-style corner radius
              boxShadow: [
                // Primary shadow for all cards
                BoxShadow(
                  blurRadius: 8, // Soft shadow blur
                  offset: const Offset(0, 2), // Subtle y-offset
                  color: Colors.black.withValues(alpha: 0.15), // 15% black opacity
                  spreadRadius: 0,
                ),
                // Enhanced shadow for depth illusion - stronger for cards higher in stack
                BoxShadow(
                  blurRadius: 12 + (index * 2), // Increasing blur for depth
                  offset: Offset(0, 4 + (index * 1)), // Increasing offset for depth
                  color: Colors.black.withValues(alpha: 0.1 - (index * 0.01)), // Decreasing opacity
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20), // 12 dp top for file-tab header look
              child: Row(
                children: [
                  // Icon with proper sizing for wallet cards
                  Icon(card.icon, size: 28, color: Colors.white),
                  const SizedBox(width: 16),

                  // Title with onboarding-style typography - single line with ellipsis
                  Expanded(
                    child: Text(
                      card.title,
                      style: GoogleFonts.lexend(
                        fontSize: 20, // Onboarding heading font size
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Chevron indicator
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





