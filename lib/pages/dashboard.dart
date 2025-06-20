// ⚠️ DEPRECATED: This Dashboard widget has been replaced by CardNavigationPage
// This file is kept for reference but should not be used in new implementations
// Use CardNavigationPage instead for the main landing page

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

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
        child: Stack(
          children: [
            // ✨ HEADER SECTION: Full-width container with wavy bottom edge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFF9C6644), // Primary accent earth brown
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✨ HEADLINE: Main title
                      Text(
                        'Talk to me Akhi',
                        style: GoogleFonts.lexend(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✨ SUBTITLE: Supporting text
                      Text(
                        'Your safe space starts here',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // ✨ FLOATING ACTION BUTTON: Center-docked with "+" icon
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        backgroundColor: const Color(0xFF9C6644), // Primary accent
        elevation: 4,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // ✨ BOTTOM NAVIGATION BAR: Four placeholder icons with notch
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home icon
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0
                      ? const Color(0xFF9C6644)
                      : const Color(0xFF4F372D).withValues(alpha: 0.6),
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              // Chats icon
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: _selectedIndex == 1
                      ? const Color(0xFF9C6644)
                      : const Color(0xFF4F372D).withValues(alpha: 0.6),
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              // Spacer for FAB
              const SizedBox(width: 40),
              // Stats icon
              IconButton(
                icon: Icon(
                  Icons.bar_chart,
                  color: _selectedIndex == 2
                      ? const Color(0xFF9C6644)
                      : const Color(0xFF4F372D).withValues(alpha: 0.6),
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              // Profile icon
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 3
                      ? const Color(0xFF9C6644)
                      : const Color(0xFF4F372D).withValues(alpha: 0.6),
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
