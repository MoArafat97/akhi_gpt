import 'package:flutter/material.dart';
import '../utils/gender_util.dart';
import '../config/personality_config.dart';
import '../services/subscription_service.dart';
import '../pages/paywall_screen.dart';

class PersonalitySettingsWidget extends StatefulWidget {
  const PersonalitySettingsWidget({super.key});

  @override
  State<PersonalitySettingsWidget> createState() => _PersonalitySettingsWidgetState();
}

class _PersonalitySettingsWidgetState extends State<PersonalitySettingsWidget> {
  bool _isPersonalityEnabled = false;
  PersonalityStyle _selectedStyle = PersonalityStyle.simpleModern;
  UserGender _userGender = UserGender.male;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final isEnabled = await GenderUtil.isPersonalityStyleEnabled();
      final style = await GenderUtil.getPersonalityStyle();
      final gender = await GenderUtil.getUserGender();

      setState(() {
        _isPersonalityEnabled = isEnabled;
        _selectedStyle = style;
        _userGender = gender;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePersonalityEnabled(bool enabled) async {
    setState(() {
      _isPersonalityEnabled = enabled;
    });

    try {
      await GenderUtil.setPersonalityStyleEnabled(enabled);
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
                ? 'Personality style enabled' 
                : 'Switched to Simple Modern English'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isPersonalityEnabled = !enabled;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectPersonalityStyle(PersonalityStyle style) async {
    // Check if this is a premium style and user doesn't have premium
    if (_isPremiumStyle(style) && !SubscriptionService.instance.isPremium) {
      // Show paywall
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(source: 'personality'),
        ),
      );

      // If user purchased premium, refresh subscription status
      if (result == true) {
        await SubscriptionService.instance.refreshSubscriptionStatus();
        // Continue with style selection
      } else {
        // User didn't purchase, don't change style
        return;
      }
    }

    setState(() {
      _selectedStyle = style;
    });

    try {
      await GenderUtil.setPersonalityStyle(style);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personality style changed to ${style.displayName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update style: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Check if a personality style requires premium subscription
  bool _isPremiumStyle(PersonalityStyle style) {
    return style != PersonalityStyle.simpleModern;
  }

  Future<void> _changeCompanionType(UserGender gender) async {
    setState(() {
      _userGender = gender;
      // Reset personality toggle to disabled when changing gender
      _isPersonalityEnabled = false;
    });

    try {
      await GenderUtil.setUserGender(gender);

      // Reset personality style to disabled (Simple Modern English)
      await GenderUtil.setPersonalityStyleEnabled(false);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Companion type changed to ${gender.displayName}. Personality style reset to Simple Modern English.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Revert state on error
      setState(() {
        _userGender = _userGender == UserGender.male ? UserGender.female : UserGender.male;
        _isPersonalityEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update companion type: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.psychology, color: Colors.white),
        title: Text('Personality Style', style: TextStyle(color: Colors.white)),
        trailing: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Companion type selection
        ListTile(
          leading: const Icon(Icons.person, color: Colors.white),
          title: const Text('Companion Type', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            _userGender.displayName,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          onTap: () => _showCompanionTypeDialog(),
        ),

        // Main toggle switch
        ListTile(
          leading: const Icon(Icons.psychology, color: Colors.white),
          title: const Text('Personality Style', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            _isPersonalityEnabled
                ? 'Using ${_selectedStyle.displayName}'
                : 'Using Simple Modern English',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Switch(
            value: _isPersonalityEnabled,
            onChanged: _togglePersonalityEnabled,
            activeColor: Colors.green,
          ),
        ),
        
        // Personality style selection (only shown when enabled)
        if (_isPersonalityEnabled) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Colors.white24),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Style:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Style options based on gender
                ...PersonalityStyle.getGenderSpecificStyles(_userGender == UserGender.male)
                    .map((style) => _buildStyleOption(style)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStyleOption(PersonalityStyle style) {
    final isSelected = _selectedStyle == style;
    final isPremium = _isPremiumStyle(style);
    final hasAccess = !isPremium || SubscriptionService.instance.isPremium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _selectPersonalityStyle(style),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          style.displayName,
                          style: TextStyle(
                            color: hasAccess
                                ? (isSelected ? Colors.white : Colors.white70)
                                : Colors.white54,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isPremium && !SubscriptionService.instance.isPremium) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium && !SubscriptionService.instance.isPremium
                          ? 'Premium required'
                          : _getStyleDescription(style),
                      style: TextStyle(
                        color: hasAccess
                            ? (isSelected ? Colors.white70 : Colors.white54)
                            : Colors.amber.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: isPremium && !SubscriptionService.instance.isPremium
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanionTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Choose Your Companion',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Who would you like to chat with?',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // Brother option
              _buildCompanionOption(
                gender: UserGender.male,
                title: 'Brother',
                description: 'A supportive older brother',
                icon: Icons.person,
              ),

              const SizedBox(height: 12),

              // Sister option
              _buildCompanionOption(
                gender: UserGender.female,
                title: 'Sister',
                description: 'A caring older sister',
                icon: Icons.person,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompanionOption({
    required UserGender gender,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _userGender == gender;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _changeCompanionType(gender);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _getStyleDescription(PersonalityStyle style) {
    switch (style) {
      case PersonalityStyle.simpleModern:
        return 'Clear, supportive modern English';
      case PersonalityStyle.bro:
        return 'Gen Z slang and modern expressions';
      case PersonalityStyle.brudda:
        return 'UK roadman/London street culture';
      case PersonalityStyle.akhi:
        return 'Muslim/Arabic with urban expressions';
      case PersonalityStyle.sis:
        return 'Gen Z slang with sisterly vibes';
      case PersonalityStyle.habibi:
        return 'UK roadman with caring sisterly tone';
      case PersonalityStyle.ukhti:
        return 'Muslim sisterhood with urban expressions';
    }
  }
}
