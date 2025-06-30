import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:developer' as developer;
import '../services/subscription_service.dart';
import '../services/message_counter_service.dart';

class PaywallScreen extends StatefulWidget {
  final String? source; // Track where user came from (messages, personality, etc.)
  
  const PaywallScreen({super.key, this.source});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final offerings = await SubscriptionService.instance.getOfferings();
      
      if (offerings != null && offerings.current != null) {
        setState(() {
          _offerings = offerings;
          // Default to monthly package if available
          _selectedPackage = offerings.current!.monthly ?? offerings.current!.availablePackages.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No subscription plans available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      final success = await SubscriptionService.instance.purchasePackage(package);
      
      if (success) {
        // Show success message and close paywall
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Welcome to Premium! Enjoy unlimited messages and all personality styles.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate successful purchase
        }
      } else {
        setState(() {
          _error = 'Purchase failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Purchase error: $e';
      });
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      final success = await SubscriptionService.instance.restorePurchases();
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Purchases restored successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _error = 'No previous purchases found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to restore purchases: $e';
      });
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F372D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Upgrade to Premium',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Benefits section
                  _buildBenefits(),
                  const SizedBox(height: 32),
                  
                  // Pricing section
                  if (_offerings?.current != null) ...[
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Purchase button
                  _buildPurchaseButton(),
                  const SizedBox(height: 16),
                  
                  // Restore purchases button
                  _buildRestoreButton(),
                  
                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          color: Colors.red[200],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Terms and privacy
                  _buildTermsAndPrivacy(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final messageStats = MessageCounterService.instance.getUsageStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF9C6644),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.star,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        Text(
          _getHeaderTitle(),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          _getHeaderSubtitle(messageStats),
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _getHeaderTitle() {
    switch (widget.source) {
      case 'messages':
        return 'Daily Limit Reached';
      case 'personality':
        return 'Unlock All Personalities';
      default:
        return 'Upgrade to Premium';
    }
  }

  String _getHeaderSubtitle(Map<String, dynamic> stats) {
    switch (widget.source) {
      case 'messages':
        return 'You\'ve used all ${stats['dailyLimit']} messages today. Upgrade to get ${SubscriptionTier.premium.dailyMessageLimit} messages daily.';
      case 'personality':
        return 'Access all personality styles including Bro, Brudda, Akhi, Sis, Habibi, and Ukhti.';
      default:
        return 'Get unlimited messages and access to all personality styles.';
    }
  }

  Widget _buildBenefits() {
    final benefits = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': '500 Messages Daily',
        'subtitle': 'vs 75 messages on free plan',
      },
      {
        'icon': Icons.psychology,
        'title': 'All Personality Styles',
        'subtitle': 'Bro, Brudda, Akhi, Sis, Habibi, Ukhti',
      },
      {
        'icon': Icons.priority_high,
        'title': 'Priority Support',
        'subtitle': 'Faster response times',
      },
      {
        'icon': Icons.update,
        'title': 'Early Access',
        'subtitle': 'New features before everyone else',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Benefits',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => _buildBenefitItem(
          benefit['icon'] as IconData,
          benefit['title'] as String,
          benefit['subtitle'] as String,
        )),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF9C6644).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF9C6644), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final offering = _offerings!.current!;
    final packages = offering.availablePackages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...packages.map((package) => _buildPricingOption(package)),
      ],
    );
  }

  Widget _buildPricingOption(Package package) {
    final isSelected = _selectedPackage?.identifier == package.identifier;
    final isAnnual = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C6644).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C6644)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF9C6644) : Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF9C6644) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 16),

            // Package info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getPackageTitle(package),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isAnnual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SAVE 20%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _getPackageSubtitle(package),
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              package.storeProduct.priceString,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPackageTitle(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      case PackageType.weekly:
        return 'Weekly';
      default:
        return package.storeProduct.title;
    }
  }

  String _getPackageSubtitle(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'Billed monthly, cancel anytime';
      case PackageType.annual:
        return 'Billed yearly, best value';
      case PackageType.weekly:
        return 'Billed weekly';
      default:
        return package.storeProduct.description;
    }
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing || _selectedPackage == null
            ? null
            : () => _purchasePackage(_selectedPackage!),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C6644),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _selectedPackage != null
                    ? 'Start Premium - ${_selectedPackage!.storeProduct.priceString}'
                    : 'Start Premium',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _isPurchasing ? null : _restorePurchases,
        child: Text(
          'Restore Purchases',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless cancelled.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Open terms of service
              },
              child: Text(
                'Terms',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9C6644),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' • ',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Open privacy policy
              },
              child: Text(
                'Privacy',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9C6644),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
