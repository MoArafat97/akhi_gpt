import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../services/terms_acceptance_service.dart';
import '../theme/app_theme.dart';

class TermsConditionsPage extends StatefulWidget {
  final bool isViewOnly;
  
  const TermsConditionsPage({
    super.key,
    this.isViewOnly = false,
  });

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Consider "scrolled to bottom" when within 50 pixels of the end
      if (maxScroll - currentScroll <= 50 && !_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _acceptTerms() async {
    if (_isAccepting) return;
    
    setState(() {
      _isAccepting = true;
    });

    try {
      await TermsAcceptanceService.acceptTerms();
      developer.log('Terms accepted successfully', name: 'TermsConditionsPage');
      
      if (mounted) {
        // Navigate to dashboard after acceptance
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      developer.log('Failed to accept terms: $e', name: 'TermsConditionsPage');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save acceptance. Please try again.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  void _declineTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryCream,
        title: Text(
          'Terms Required',
          style: GoogleFonts.lexend(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You must accept the Terms and Conditions to use NafsAI. The app will now close.',
          style: GoogleFonts.inter(
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Close the app
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: AppTheme.warmBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCream,
        elevation: 0,
        leading: widget.isViewOnly 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        automaticallyImplyLeading: widget.isViewOnly,
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.lexend(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(
                color: Colors.white,
                borderRadius: 16,
              ),
              child: Column(
                children: [
                  // Header section
                  if (!widget.isViewOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: AppTheme.warmBrown,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to NafsAI',
                            style: GoogleFonts.lexend(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please read and accept our Terms & Conditions to continue',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Divider(color: AppTheme.darkCream, height: 1),
                  ],
                  
                  // Scrollable terms content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      child: _buildTermsContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons (only show for acceptance flow)
          if (!widget.isViewOnly) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Scroll indicator
                  if (!_hasScrolledToBottom)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.warmBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.warmBrown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Please scroll to read all terms',
                            style: GoogleFonts.inter(
                              color: AppTheme.warmBrown,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _declineTerms,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.textMedium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMedium,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Accept button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _hasScrolledToBottom && !_isAccepting ? _acceptTerms : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warmBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isAccepting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Accept & Continue',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'App Purpose',
          'NafsAI is designed solely for conversational support and companionship. This application provides AI-generated responses to help users with general emotional support and Islamic perspective sharing.',
        ),

        _buildSection(
          'NOT Medical or Therapeutic Services',
          'IMPORTANT: This app is NOT a therapy application and is NOT designed to diagnose, treat, cure, or prevent any mental health conditions. NafsAI does not provide medical advice, professional counseling, or therapeutic services. If you are experiencing serious mental health concerns, suicidal thoughts, or psychological distress, please seek immediate professional help from qualified healthcare providers, therapists, or emergency services.',
          isWarning: true,
        ),

        _buildSection(
          'Data Storage & Privacy',
          'All user data including chat history, preferences, and personal information is stored locally on your device only. We do not collect, transmit, or store your personal data on external servers. Your conversations remain private and are only accessible on your device.',
        ),

        _buildSection(
          'Data Deletion',
          'When you uninstall NafsAI from your device, all user data including chat history, preferences, and any personal information stored by the app will be permanently deleted. This data cannot be recovered after uninstallation.',
        ),

        _buildSection(
          'User Responsibility',
          'You are solely responsible for your own wellbeing while using this app. You should discontinue use immediately if the app causes you distress, anxiety, or any negative emotional response. You acknowledge that AI responses may not always be appropriate or helpful for your specific situation.',
        ),

        _buildSection(
          'Limitations of AI',
          'The AI responses provided by NafsAI are generated by artificial intelligence and may not always be accurate, appropriate, or suitable for your specific circumstances. The app cannot replace human judgment, professional advice, or real-world support systems.',
        ),

        _buildSection(
          'Islamic Content Disclaimer',
          'While NafsAI aims to provide Islamic perspectives and guidance, the AI-generated content should not be considered as authoritative religious rulings or replace consultation with qualified Islamic scholars for important religious matters.',
        ),

        _buildSection(
          'Contact Information',
          'For support, questions, or concerns about this app, please contact us at: khotarafat@gmail.com',
        ),

        _buildSection(
          'Terms Updates',
          'These terms may be updated from time to time. Continued use of the app after updates constitutes acceptance of the revised terms.',
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warmBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warmBrown.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important Acknowledgment',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By accepting these terms, you acknowledge that:\n\n'
                '• This app is NOT a substitute for professional mental health care\n'
                '• You will seek professional help when circumstances require it\n'
                '• You understand the limitations outlined above\n'
                '• You use the app entirely at your own risk',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Version: ${TermsAcceptanceService.getCurrentTermsVersion()}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWarning) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isWarning ? Colors.orange.shade800 : AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: isWarning ? const EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: isWarning ? BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ) : null,
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
