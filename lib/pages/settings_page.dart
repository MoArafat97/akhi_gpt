import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import '../utils/settings_util.dart';
import '../utils/gender_util.dart';
import '../services/hive_service.dart';
import '../services/settings_service.dart';
import '../widgets/personality_settings_widget.dart';
import '../widgets/subscription_status_widget.dart';
import '../widgets/api_key_settings_widget.dart';
import '../widgets/model_selection_widget.dart';

class SettingsPage extends StatefulWidget {
  final Color bgColor;

  const SettingsPage({super.key, this.bgColor = const Color(0xFFB7AFA3)});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              style: const TextStyle(color: Colors.white),
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
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor.withValues(alpha: 0.9),
        title: GestureDetector(
          onTap: _handleSecretTap,
          child: const Text(
            'Settings',
            style: TextStyle(
              color: Color(0xFF424242), // Dark gray for consistency
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Essential Setup Section - Prioritized at top
          _SectionHeader('Essential Setup'),
          _OpenRouterConfigurationCard(),
          const ApiKeySettingsWidget(),
          const SizedBox(height: 8),
          ModelSelectionWidget(key: modelSelectionWidgetKey),

          // Profile Section
          _SectionHeader('Profile'),
          const PersonalitySettingsWidget(),

          // Chat Preferences Section
          _SectionHeader('Chat Preferences'),
          _SwitchTile('Streaming responses', 'streaming', defaultOn: true),
          _SaveChatHistorySwitchTile(),
          _SwitchTile('Encrypt saved chats', 'encryptChats', defaultOn: true),
          _ChatHistoryTile(),

          // Subscription Section - Moved down as it's not essential for basic functionality
          _SectionHeader('Subscription'),
          const SubscriptionStatusWidget(),

          // Other Settings
          _SectionHeader('Journal'),
          _DropdownTile('Autosave', 'autosave',
            ['Live', '30 s', 'On save'], defaultVal: 'Live'),

          _SectionHeader('Safety'),
          _SwitchTile('Show crisis info cards', 'crisis', defaultOn: true),

          _SectionHeader('Appearance'),
          _SwitchTile('Cream theme', 'creamTheme', defaultOn: true),

          _SectionHeader('About'),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF424242))),
            subtitle: const Text('All data stays on your device.', style: TextStyle(color: Color(0xFF666666))),
          ),
          ListTile(
            title: const Text('App Version', style: TextStyle(color: Color(0xFF424242))),
            subtitle: FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                snap.hasData ? snap.data!.version : '...',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ),
          ),

          // Developer section - only show when developer mode is enabled
          if (_isDeveloperMode) ...[
            _SectionHeader('Developer'),
            ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Color(0xFF424242)),
              title: const Text('Test Onboarding Flow', style: TextStyle(color: Color(0xFF424242))),
              subtitle: const Text('Replay the onboarding experience', style: TextStyle(color: Color(0xFF666666))),
              onTap: () async {
                if (await SettingsService.canAccessDeveloperRoute('/onboard1')) {
                  Navigator.pushNamed(context, '/onboard1');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Color(0xFF424242)),
              title: const Text('API Diagnostics', style: TextStyle(color: Color(0xFF424242))),
              subtitle: const Text('Test API connectivity and configuration', style: TextStyle(color: Color(0xFF666666))),
              onTap: () async {
                if (await SettingsService.canAccessDeveloperRoute('/diagnostics')) {
                  Navigator.pushNamed(context, '/diagnostics');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _SectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF424242), // Dark gray for better contrast
        ),
      ),
    );
  }

  Widget _OpenRouterConfigurationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_input_component,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'OpenRouter Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Remove the "REQUIRED" container
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Configure your OpenRouter API key and select an AI model to start chatting.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _SwitchTile(String title, String key, {bool defaultOn = false}) {
    return FutureBuilder<bool>(
      future: getBool(key, defaultOn),
      builder: (context, snapshot) {
        final value = snapshot.data ?? defaultOn;
        return SwitchListTile(
          title: Text(title, style: const TextStyle(color: Color(0xFF424242))),
          value: value,
          onChanged: (newValue) {
            setBool(key, newValue);
            setState(() {});
          },
          activeColor: Colors.white,
          inactiveThumbColor: Colors.white54,
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
          title: Text(title, style: const TextStyle(color: Color(0xFF424242))),
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
                activeColor: Colors.white,
                inactiveColor: Colors.white54,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _DropdownTile(String title, String key, List<String> options, {String defaultVal = ''}) {
    return FutureBuilder<String>(
      future: getString(key, defaultVal),
      builder: (context, snapshot) {
        final value = snapshot.data ?? defaultVal;
        return ListTile(
          title: Text(title, style: const TextStyle(color: Color(0xFF424242))),
          subtitle: DropdownButton<String>(
            value: options.contains(value) ? value : defaultVal,
            dropdownColor: widget.bgColor,
            style: const TextStyle(color: Color(0xFF424242)),
            underline: Container(height: 1, color: Colors.white54),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: const TextStyle(color: Color(0xFF424242))),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setString(key, newValue);
                setState(() {});
              }
            },
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
          title: Text(title, style: const TextStyle(color: Color(0xFF424242))),
          subtitle: Text(
            hasKey ? '••••••••••••••••' : 'Not set',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _editSecureKey(title, key),
              ),
              if (hasKey)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
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
        title: Text('Edit $title', style: const TextStyle(color: Color(0xFF424242))),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Color(0xFF424242)),
          decoration: InputDecoration(
            hintText: 'Enter API key',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
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
            child: const Text('Save', style: TextStyle(color: Color(0xFF424242))),
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
        title: const Text('Delete API Key', style: TextStyle(color: Color(0xFF424242))),
        content: const Text(
          'Are you sure you want to delete this API key?',
          style: TextStyle(color: Color(0xFF424242)),
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
          title: const Text('Save chat history', style: TextStyle(color: Color(0xFF424242))),
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
          activeColor: Colors.white,
          inactiveThumbColor: Colors.white54,
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
                style: const TextStyle(color: Color(0xFF424242)),
              ),
              subtitle: Text(
                '$count saved conversations',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
              iconColor: Color(0xFF424242),
              collapsedIconColor: Color(0xFF424242),
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF424242)),
                  title: const Text('Export All Chats', style: TextStyle(color: Color(0xFF424242))),
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
        title: const Text('Export Chat History', style: TextStyle(color: Color(0xFF424242))),
        content: const Text(
          'Choose export format:',
          style: TextStyle(color: Color(0xFF424242)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('json');
            },
            child: const Text('JSON', style: TextStyle(color: Color(0xFF424242))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('txt');
            },
            child: const Text('Text', style: TextStyle(color: Color(0xFF424242))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('md');
            },
            child: const Text('Markdown', style: TextStyle(color: Color(0xFF424242))),
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
          filename = 'akhi_chat_history_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'md':
          content = histories.map((h) => h.toMarkdown()).join('\n---\n\n');
          filename = 'akhi_chat_history_${DateTime.now().millisecondsSinceEpoch}.md';
          break;
        default: // txt
          content = histories.map((h) => h.toPlainText()).join('\n${'=' * 80}\n\n');
          filename = 'akhi_chat_history_${DateTime.now().millisecondsSinceEpoch}.txt';
      }

      await Share.shareXFiles(
        [XFile.fromData(
          Uint8List.fromList(utf8.encode(content)),
          name: filename,
          mimeType: format == 'json' ? 'application/json' : 'text/plain',
        )],
        subject: 'Akhi GPT Chat History Export',
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
        title: const Text('Delete All Chat History', style: TextStyle(color: Color(0xFF424242))),
        content: const Text(
          'This will permanently delete all saved conversations. This action cannot be undone.',
          style: TextStyle(color: Color(0xFF424242)),
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
            color: Color(0xFF424242).withValues(alpha: 0.8),
          ),
          title: const Text(
            'Companion Type',
            style: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            currentGender.displayName,
            style: TextStyle(color: Color(0xFF666666).withValues(alpha: 0.7)),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.6),
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
            style: TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w600),
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
              : Colors.white24,
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
                      color: isSelected ? const Color(0xFF9C6644) : const Color(0xFF424242),
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
}
