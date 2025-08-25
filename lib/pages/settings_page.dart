import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:developer' as developer;
import '../utils/settings_util.dart';
import '../utils/gender_util.dart';
import '../services/hive_service.dart';
import '../services/settings_service.dart';
import '../widgets/personality_settings_widget.dart';
import '../widgets/modern_ui_components.dart';
import '../theme/app_theme.dart';
import 'terms_conditions_page.dart';


class SettingsPage extends StatefulWidget {
  final Color bgColor;

  const SettingsPage({super.key, this.bgColor = const Color(0xFFFCF8F1)});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _backToDashboard() {
    final nav = Navigator.of(context, rootNavigator: true);
    var reachedDashboard = false;
    nav.popUntil((route) {
      if (route.settings.name == '/dashboard') {
        reachedDashboard = true;
        return true;
      }
      return false;
    });
    if (!reachedDashboard) {
      nav.pushReplacementNamed('/dashboard');
    }
  }
  static const _secure = FlutterSecureStorage();
  final _hiveService = HiveService.instance;

  // Developer mode state
  bool _isDeveloperMode = false;
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _loadDeveloperMode();
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

  /// Handle secret gesture on Settings title
  void _handleSecretTap() async {
    final now = DateTime.now();

    // Reset tap count if more than 2 seconds have passed
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTap = now;

    // Check if we've reached 7 taps
    if (_tapCount >= 7) {
      _tapCount = 0;
      final newState = await SettingsService.toggleDeveloperMode();

      if (mounted) {
        setState(() {
          _isDeveloperMode = newState;
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'Developer mode enabled' : 'Developer mode disabled',
              style: const TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
            ),
            backgroundColor: newState ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ STANDARD APPBAR with simple back navigation
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5A3C)),
          onPressed: _backToDashboard,
        ),
        title: GestureDetector(
          onTap: _handleSecretTap,
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF8B5A3C),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        centerTitle: false,
      ),
      // ✨ MODERN BACKGROUND with original colors
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
          child: Column(
            children: [

              // ✨ ENHANCED CONTENT with generous spacing
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    const SizedBox(height: 8),

                    // ✨ PROFILE SECTION with modern card
                    _SectionHeader('Profile'),
                    _buildModernCard([
                      const PersonalitySettingsWidget(),
                    ]),

                    // ✨ CHAT PREFERENCES SECTION with modern card
                    _SectionHeader('Chat Preferences'),
                    _buildModernCard([
                      _SwitchTile('Streaming responses', 'streaming', defaultOn: true),
                      _SaveChatHistorySwitchTile(),
                      _SwitchTile('Encrypt saved chats', 'encryptChats', defaultOn: true),
                      _ChatHistoryTile(),
                    ]),

                    // ✨ SAFETY SECTION with modern card
                    _SectionHeader('Safety'),
                    _buildModernCard([
                      _SwitchTile('Show crisis info cards', 'crisis', defaultOn: true),
                    ]),

                    // ✨ APPEARANCE SECTION with modern card
                    _SectionHeader('Appearance'),
                    _buildModernCard([
                      _SwitchTile('Cream theme', 'creamTheme', defaultOn: true),
                    ]),

                    // ✨ ABOUT SECTION with modern card
                    _SectionHeader('About'),
                    _buildModernCard([
                      ListTile(
                        leading: const Icon(Icons.description_outlined, color: Color(0xFF8B5A3C)),
                        title: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFF8B5A3C))),
                        subtitle: const Text('View app terms and privacy policy', style: TextStyle(color: Color(0xFF666666))),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF8B5A3C), size: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/terms_conditions',
                            arguments: true, // isViewOnly = true
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('App Version', style: TextStyle(color: Color(0xFF8B5A3C))),
                        subtitle: FutureBuilder(
                          future: PackageInfo.fromPlatform(),
                          builder: (_, snap) => Text(
                            snap.hasData ? snap.data!.version : '...',
                            style: const TextStyle(color: Color(0xFF666666)),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    ]),

                    // ✨ DEVELOPER SECTION with modern card (only show when enabled)
                    if (_isDeveloperMode) ...[
                      _SectionHeader('Developer'),
                      _buildModernCard([
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline, color: Color(0xFF8B5A3C)),
                          title: const Text('Test Onboarding Flow', style: TextStyle(color: Color(0xFF8B5A3C))),
                          subtitle: const Text('Replay the onboarding experience', style: TextStyle(color: Color(0xFF666666))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          onTap: () async {
                            if (await SettingsService.canAccessDeveloperRoute('/onboard1')) {
                              Navigator.pushNamed(context, '/onboard1');
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.bug_report, color: Color(0xFF8B5A3C)),
                          title: const Text('API Diagnostics', style: TextStyle(color: Color(0xFF8B5A3C))),
                          subtitle: const Text('Test API connectivity and configuration', style: TextStyle(color: Color(0xFF666666))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          onTap: () async {
                            if (await SettingsService.canAccessDeveloperRoute('/diagnostics')) {
                              Navigator.pushNamed(context, '/diagnostics');
                            }
                          },
                        ),
                      ]),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ MODERN SECTION HEADER with enhanced typography
  Widget _SectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 32, 0, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8B5A3C),
          letterSpacing: -0.2,
        ),
      ),
    );
  }



  // ✨ MODERN SWITCH TILE with enhanced padding
  Widget _SwitchTile(String title, String key, {bool defaultOn = false}) {
    return FutureBuilder<bool>(
      future: getBool(key, defaultOn),
      builder: (context, snapshot) {
        final value = snapshot.data ?? defaultOn;
        return SwitchListTile(
          title: Text(title, style: const TextStyle(color: Color(0xFF8B5A3C))),
          value: value,
          onChanged: (newValue) {
            setBool(key, newValue);
            setState(() {});
          },
          activeColor: const Color(0xFF9C6644),
          inactiveThumbColor: const Color(0xFF8B5A3C).withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        );
      },
    );
  }

  Widget _SliderTile(String title, String key, double min, double max, {double defaultVal = 0}) {
    return FutureBuilder<double>(
      future: getDouble(key, defaultVal),
      builder: (context, snapshot) {
        final value = snapshot.data ?? defaultVal;
        return ListTile(
          title: Text(title, style: const TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${value.round()}', style: const TextStyle(color: Color(0xFF666666))),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                onChanged: (newValue) {
                  setDouble(key, newValue);
                  setState(() {});
                },
                activeColor: const Color(0xFF9C6644), // Changed to warm brown
                inactiveColor: const Color(0xFF8B5A3C).withValues(alpha: 0.5), // Changed to earthy brown
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _SecureKeyTile(String title, String key) {
    return FutureBuilder<String?>(
      future: getSecure(key),
      builder: (context, snapshot) {
        final hasKey = snapshot.data?.isNotEmpty == true;
        return ListTile(
          title: Text(title, style: const TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          subtitle: Text(
            hasKey ? '••••••••••••••••' : 'Not set',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF8B5A3C)), // Changed to earthy brown
                onPressed: () => _editSecureKey(title, key),
              ),
              if (hasKey)
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF8B5A3C)), // Changed to earthy brown
                  onPressed: () => _deleteSecureKey(key),
                ),
            ],
          ),
        );
      },
    );
  }

  void _editSecureKey(String title, String key) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.bgColor,
        title: Text('Edit $title', style: const TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
          decoration: InputDecoration(
            hintText: 'Enter API key',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF8B5A3C).withValues(alpha: 0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8B5A3C)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setSecure(key, controller.text);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          ),
        ],
      ),
    );
  }

  void _deleteSecureKey(String key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.bgColor,
        title: const Text('Delete API Key', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
        content: const Text(
          'Are you sure you want to delete this API key?',
          style: TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () {
              _secure.delete(key: key);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _SaveChatHistorySwitchTile() {
    return FutureBuilder<bool>(
      future: getBool('saveChatHistory', true),
      builder: (context, snapshot) {
        final value = snapshot.data ?? true;
        return SwitchListTile(
          title: const Text('Save chat history', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          value: value,
          onChanged: (newValue) async {
            await setBool('saveChatHistory', newValue);

            // If turning OFF, immediately clear all saved chat history
            if (!newValue) {
              try {
                await _hiveService.deleteAllChatHistories();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat history cleared and saving disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                developer.log('Failed to clear chat history: $e', name: 'SettingsPage');
              }
            }

            setState(() {});
          },
          activeColor: const Color(0xFF9C6644), // Changed to warm brown
          inactiveThumbColor: const Color(0xFF8B5A3C).withValues(alpha: 0.5), // Changed to earthy brown
        );
      },
    );
  }

  Widget _ChatHistoryTile() {
    return FutureBuilder<bool>(
      future: getBool('saveChatHistory', true),
      builder: (context, snapshot) {
        final savingEnabled = snapshot.data ?? false;

        if (!savingEnabled) {
          return const SizedBox.shrink(); // Hide if saving is disabled
        }

        return FutureBuilder<int>(
          future: _hiveService.getChatHistoriesCount(),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;

            return ExpansionTile(
              title: Text(
                'Chat History Management',
                style: const TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
              ),
              subtitle: Text(
                '$count saved conversations',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
              iconColor: const Color(0xFF8B5A3C), // Changed to earthy brown
              collapsedIconColor: const Color(0xFF8B5A3C), // Changed to earthy brown
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF8B5A3C)), // Changed to earthy brown
                  title: const Text('Export All Chats', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
                  subtitle: const Text('Export as JSON, TXT, or Markdown', style: TextStyle(color: Color(0xFF666666))),
                  onTap: () => _showExportDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete All Chats', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete all saved conversations', style: TextStyle(color: Color(0xFF666666))),
                  onTap: () => _showDeleteAllDialog(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.bgColor,
        title: const Text('Export Chat History', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
        content: const Text(
          'Choose export format:',
          style: TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('json');
            },
            child: const Text('JSON', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('txt');
            },
            child: const Text('Text', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('md');
            },
            child: const Text('Markdown', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
        ],
      ),
    );
  }

  Future<void> _exportChats(String format) async {
    try {
      final histories = await _hiveService.getAllChatHistories();

      if (histories.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No chat history to export')),
          );
        }
        return;
      }

      String content;
      String filename;

      switch (format) {
        case 'json':
          content = jsonEncode(histories.map((h) => h.toJson()).toList());
          filename = 'nafs_ai_chat_history_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'md':
          content = histories.map((h) => h.toMarkdown()).join('\n---\n\n');
          filename = 'nafs_ai_chat_history_${DateTime.now().millisecondsSinceEpoch}.md';
          break;
        default: // txt
          content = histories.map((h) => h.toPlainText()).join('\n${'=' * 80}\n\n');
          filename = 'nafs_ai_chat_history_${DateTime.now().millisecondsSinceEpoch}.txt';
      }

      await Share.shareXFiles(
        [XFile.fromData(
          Uint8List.fromList(utf8.encode(content)),
          name: filename,
          mimeType: format == 'json' ? 'application/json' : 'text/plain',
        )],
        subject: 'NafsAI Chat History Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat history exported as $format')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.bgColor,
        title: const Text('Delete All Chat History', style: TextStyle(color: Color(0xFF8B5A3C))), // Changed to earthy brown
        content: const Text(
          'This will permanently delete all saved conversations. This action cannot be undone.',
          style: TextStyle(color: Color(0xFF8B5A3C)), // Changed to earthy brown
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllChats();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllChats() async {
    try {
      await _hiveService.deleteAllChatHistories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chat history deleted'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  /// Gender selection tile for profile settings
  Widget _GenderSelectionTile() {
    return FutureBuilder<UserGender>(
      future: GenderUtil.getUserGender(),
      builder: (context, snapshot) {
        final currentGender = snapshot.data ?? UserGender.male;

        return ListTile(
          leading: Icon(
            Icons.person,
            color: const Color(0xFF8B5A3C).withValues(alpha: 0.8), // Changed to earthy brown
          ),
          title: const Text(
            'Companion Type',
            style: TextStyle(color: Color(0xFF8B5A3C), fontWeight: FontWeight.w500), // Changed to earthy brown
          ),
          subtitle: Text(
            currentGender.displayName,
            style: TextStyle(color: Color(0xFF666666).withValues(alpha: 0.7)),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: const Color(0xFF8B5A3C).withValues(alpha: 0.6), // Changed to earthy brown
            size: 16,
          ),
          onTap: () => _showGenderSelectionDialog(currentGender),
        );
      },
    );
  }

  /// Show gender selection dialog
  void _showGenderSelectionDialog(UserGender currentGender) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Choose Your Companion',
            style: TextStyle(color: Color(0xFF8B5A3C), fontWeight: FontWeight.w600), // Changed to earthy brown
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Who would you like to chat with?',
                style: TextStyle(color: Color(0xFF666666)),
              ),
              const SizedBox(height: 20),

              // Brother option
              _buildGenderOption(
                gender: UserGender.male,
                currentGender: currentGender,
                title: 'Brother',
                description: 'A supportive older brother',
                icon: Icons.person,
              ),

              const SizedBox(height: 12),

              // Sister option
              _buildGenderOption(
                gender: UserGender.female,
                currentGender: currentGender,
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
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build gender option widget for dialog
  Widget _buildGenderOption({
    required UserGender gender,
    required UserGender currentGender,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = gender == currentGender;

    return InkWell(
      onTap: () => _changeGender(gender),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFF9C6644).withValues(alpha: 0.3)
            : Colors.transparent,
          border: Border.all(
            color: isSelected
              ? const Color(0xFF9C6644)
              : const Color(0xFF8B5A3C).withValues(alpha: 0.2), // Changed to earthy brown
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF9C6644) : const Color(0xFF666666),
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
                      color: isSelected ? const Color(0xFF9C6644) : const Color(0xFF8B5A3C), // Changed to earthy brown
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF9C6644).withValues(alpha: 0.8) : const Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF9C6644),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Change user gender with confirmation
  void _changeGender(UserGender newGender) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      await GenderUtil.setUserGender(newGender);

      if (mounted) {
        setState(() {}); // Refresh the UI

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Companion changed to ${newGender.displayName}'),
            backgroundColor: const Color(0xFF9C6644),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change companion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // ✨ MODERN CARD BUILDER with glassmorphism
  Widget _buildModernCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedCard(
        borderRadius: 16,
        color: Colors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: EdgeInsets.zero,
        child: Column(
          children: children.map((child) {
            return Container(
              decoration: BoxDecoration(
                border: children.indexOf(child) != children.length - 1
                    ? const Border(
                        bottom: BorderSide(
                          color: Color(0xFFE8E0D8),
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: child,
            );
          }).toList(),
        ),
      ),
    );
  }
}
