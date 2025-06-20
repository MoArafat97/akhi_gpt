import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import '../utils/settings_util.dart';
import '../services/hive_service.dart';

class SettingsPage extends StatefulWidget {
  final Color bgColor;

  const SettingsPage({super.key, this.bgColor = const Color(0xFFB7AFA3)});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _secure = FlutterSecureStorage();
  final _hiveService = HiveService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor.withValues(alpha: 0.9),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
          _SectionHeader('Chat'),
          _SwitchTile('Streaming responses', 'streaming', defaultOn: true),
          _SaveChatHistorySwitchTile(),
          _SwitchTile('Encrypt saved chats', 'encryptChats', defaultOn: true),
          _ChatHistoryTile(),

          _SectionHeader('Journal'),
          _SwitchTile('Rich-text editor', 'richText', defaultOn: true),
          _DropdownTile('Autosave', 'autosave',
            ['Live', '30 s', 'On save'], defaultVal: 'Live'),

          _SectionHeader('Mood & Duʿāʾ'),
          _DropdownTile('Mood picker style', 'moodStyle',
            ['Emoji', 'Text', 'Both'], defaultVal: 'Emoji'),
          _SliderTile('Duʿāʾ suggestions /day', 'duaFreq', 0, 10, defaultVal: 3),

          _SectionHeader('Safety'),
          _SwitchTile('Show crisis info cards', 'crisis', defaultOn: true),

          _SectionHeader('Appearance'),
          _SwitchTile('Cream theme', 'creamTheme', defaultOn: true),

          _SectionHeader('About'),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            subtitle: const Text('All data stays on your device.', style: TextStyle(color: Colors.white70)),
          ),
          ListTile(
            title: const Text('App Version', style: TextStyle(color: Colors.white)),
            subtitle: FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                snap.hasData ? snap.data!.version : '...',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
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
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _SwitchTile(String title, String key, {bool defaultOn = false}) {
    return FutureBuilder<bool>(
      future: getBool(key, defaultOn),
      builder: (context, snapshot) {
        final value = snapshot.data ?? defaultOn;
        return SwitchListTile(
          title: Text(title, style: const TextStyle(color: Colors.white)),
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
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${value.round()}', style: const TextStyle(color: Colors.white70)),
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
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: DropdownButton<String>(
            value: options.contains(value) ? value : defaultVal,
            dropdownColor: widget.bgColor,
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: Colors.white54),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: const TextStyle(color: Colors.white)),
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
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            hasKey ? '••••••••••••••••' : 'Not set',
            style: const TextStyle(color: Colors.white70),
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
        title: Text('Edit $title', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter API key',
            hintStyle: const TextStyle(color: Colors.white54),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setSecure(key, controller.text);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
        title: const Text('Delete API Key', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this API key?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
          title: const Text('Save chat history', style: TextStyle(color: Colors.white)),
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
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '$count saved conversations',
                style: const TextStyle(color: Colors.white70),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: const Text('Export All Chats', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Export as JSON, TXT, or Markdown', style: TextStyle(color: Colors.white70)),
                  onTap: () => _showExportDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete All Chats', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete all saved conversations', style: TextStyle(color: Colors.white70)),
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
        title: const Text('Export Chat History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Choose export format:',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('json');
            },
            child: const Text('JSON', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('txt');
            },
            child: const Text('Text', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportChats('md');
            },
            child: const Text('Markdown', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
        title: const Text('Delete All Chat History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all saved conversations. This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
}
