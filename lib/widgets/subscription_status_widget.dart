import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';
import '../services/message_counter_service.dart';
import '../pages/paywall_screen.dart';

class SubscriptionStatusWidget extends StatefulWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  State<SubscriptionStatusWidget> createState() => _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Subscription tier card
        _buildSubscriptionTierCard(),
        const SizedBox(height: 8),
        
        // Message usage card (only for free users)
        if (!SubscriptionService.instance.isPremium) ...[
          _buildMessageUsageCard(),
          const SizedBox(height: 8),
        ],
        
        // Subscription actions
        _buildSubscriptionActions(),
      ],
    );
  }

  Widget _buildSubscriptionTierCard() {
    final isPremium = SubscriptionService.instance.isPremium;
    final tier = SubscriptionService.instance.currentTier;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium 
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium 
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPremium ? Colors.amber : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPremium ? Icons.star : Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tier.displayName} Plan',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium 
                      ? 'Enjoy unlimited messages and all personality styles'
                      : 'Limited to ${tier.dailyMessageLimit} messages per day',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Status badge
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PREMIUM',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageUsageCard() {
    final stats = MessageCounterService.instance.getUsageStats();
    final warningLevel = MessageCounterService.instance.getWarningLevel();
    final usagePercentage = stats['usagePercentage'] as double;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Messages',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${stats['currentCount']}/${stats['dailyLimit']}',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usagePercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: _getUsageColor(warningLevel),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Status message
          if (warningLevel.message.isNotEmpty)
            Text(
              warningLevel.message,
              style: GoogleFonts.inter(
                color: _getUsageColor(warningLevel),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          // Reset time
          Text(
            'Resets in ${stats['timeUntilReset']}',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(MessageUsageWarningLevel level) {
    switch (level) {
      case MessageUsageWarningLevel.normal:
        return Colors.green;
      case MessageUsageWarningLevel.warning:
        return Colors.orange;
      case MessageUsageWarningLevel.critical:
        return Colors.red;
      case MessageUsageWarningLevel.limitReached:
        return Colors.grey;
    }
  }

  Widget _buildSubscriptionActions() {
    final isPremium = SubscriptionService.instance.isPremium;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (!isPremium) ...[
            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showPaywall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade to Premium',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Restore purchases button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _restorePurchases,
              child: Text(
                'Restore Purchases',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaywall() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
      ),
    );
    
    if (result == true) {
      // Refresh subscription status
      await SubscriptionService.instance.refreshSubscriptionStatus();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _restorePurchases() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
    
    try {
      final success = await SubscriptionService.instance.restorePurchases();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (success) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Purchases restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous purchases found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
