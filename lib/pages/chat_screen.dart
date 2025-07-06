import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../services/openrouter_service.dart';
import '../services/hive_service.dart';
import '../utils/settings_util.dart';
import '../utils/gender_util.dart';
import '../services/subscription_service.dart';
import '../services/message_counter_service.dart';
import 'paywall_screen.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final Color bgColor;

  const ChatScreen({super.key, this.bgColor = const Color(0xFF7B4F2F)});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenRouterService _openRouterService = OpenRouterService();
  final HiveService _hiveService = HiveService.instance;
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  String _currentModel = 'Akhi Assistant';
  String? _sessionId;
  UserGender _userGender = UserGender.male; // Default, will be loaded from preferences

  // Aggression tracking variables
  int _violationCount = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();

    // Defer initialization until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
      // Load user gender preference
      _loadUserGender();
      // Load lockout state with error handling
      _loadLockoutState().catchError((error) {
        developer.log('Failed to load lockout state in initState: $error', name: 'ChatScreen');
      });
      // Test connection on startup
      _testConnection();
      // Load chat history if enabled
      _loadChatHistoryIfEnabled();
    });
  }

  /// Test OpenRouter connection on startup
  void _testConnection() async {
    try {
      developer.log('Testing OpenRouter connection...', name: 'ChatScreen');
      final isConnected = await _openRouterService.testConnection();
      developer.log('Connection test result: $isConnected', name: 'ChatScreen');

      if (!isConnected) {
        developer.log('❌ OpenRouter connection failed', name: 'ChatScreen');
      } else {
        developer.log('✅ OpenRouter connection successful', name: 'ChatScreen');
      }
    } catch (e) {
      developer.log('❌ Connection test error: $e', name: 'ChatScreen');
    }
  }

  /// Load user preferences (gender, display name, personality)
  void _loadUserGender() async {
    try {
      final gender = await GenderUtil.getUserGender();
      final displayName = await GenderUtil.getDisplayName();
      final companionName = await GenderUtil.getCompanionName();

      setState(() {
        _userGender = gender;
        // Use dynamic model display name based on personality settings
        _currentModel = '$companionName Assistant';
      });

      developer.log('Loaded user preferences - Gender: ${gender.displayName}, Name: ${displayName ?? "not set"}, Companion: $companionName', name: 'ChatScreen');
    } catch (e) {
      developer.log('Failed to load user preferences: $e', name: 'ChatScreen');
      // Keep default gender (male) on error
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeService() async {
    // Get dynamic model display name
    final modelDisplayName = await _openRouterService.getModelDisplayName();
    setState(() {
      _currentModel = modelDisplayName;
    });

    // Check service configuration
    final isConfigured = await _openRouterService.isConfigured;
    print('🔥 CHAT: Service configured: $isConfigured');

    if (!isConfigured) {
      print('🔥 CHAT: ❌ Service not configured - user needs to set API key');
    } else {
      print('🔥 CHAT: ✅ Service is properly configured');
    }
  }

  /// Load lockout state from SharedPreferences
  Future<void> _loadLockoutState() async {
    try {
      final lockedUntilString = await getString('chatLockedUntil', '');
      final violationCount = await getString('violationCount', '0');

      if (lockedUntilString.isNotEmpty) {
        _lockedUntil = DateTime.tryParse(lockedUntilString);
        // Clear lockout if time has passed
        if (_lockedUntil != null && DateTime.now().isAfter(_lockedUntil!)) {
          _lockedUntil = null;
          _violationCount = 0;
          await setString('chatLockedUntil', '');
          await setString('violationCount', '0');
        } else {
          _violationCount = int.tryParse(violationCount) ?? 0;
        }
      }

      setState(() {});
    } catch (e) {
      developer.log('Error loading lockout state: $e', name: 'ChatScreen');
    }
  }

  /// Check if chat is currently locked
  bool get _isChatLocked {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      // Lockout expired, clear it
      _clearLockout();
      return false;
    }
    return true;
  }

  /// Clear lockout state
  Future<void> _clearLockout() async {
    try {
      _lockedUntil = null;
      _violationCount = 0;
      await setString('chatLockedUntil', '');
      await setString('violationCount', '0');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      developer.log('Error clearing lockout state: $e', name: 'ChatScreen');
    }
  }

  /// Apply 10-minute lockout
  Future<void> _applyLockout() async {
    try {
      _lockedUntil = DateTime.now().add(const Duration(minutes: 10));
      await setString('chatLockedUntil', _lockedUntil!.toIso8601String());
      await setString('violationCount', _violationCount.toString());

      if (mounted) {
        setState(() {});

        // Show lockout message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat locked for 10 min.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      developer.log('Error applying lockout: $e', name: 'ChatScreen');
    }
  }

  // Cache compiled regex patterns for better performance
  static final List<RegExp> _offensivePatterns = [
    // Profanity and insults (most common, check first)
    RegExp(r'\b(fuck|shit|damn|bitch|asshole|bastard|cunt|piss)\b', caseSensitive: false),
    RegExp(r'\b(stupid|idiot|moron|dumb)\b', caseSensitive: false),

    // Aggressive language
    RegExp(r'\b(hate|kill|die|murder|destroy)\b', caseSensitive: false),
    RegExp(r'\b(shut up|fuck off|go to hell)\b', caseSensitive: false),

    // Religious disrespect (more specific to avoid false positives)
    RegExp(r'\b(allah|islam|muslim).*(fake|stupid|wrong|bad)\b', caseSensitive: false),
    RegExp(r'\breligion.*(bullshit|stupid|fake)\b', caseSensitive: false),

    // Threats and hostility (simplified patterns)
    RegExp(r'\b(gonna|going to).*(kill|hurt|destroy|beat)\b', caseSensitive: false),
    RegExp(r'\byou.*(useless|worthless|pathetic)\b', caseSensitive: false),
  ];

  /// Detect if message contains offensive content (optimized for performance)
  bool _isOffensiveContent(String message) {
    // Quick length check - very short messages are unlikely to be offensive
    if (message.length < 3) return false;

    final lowerMessage = message.toLowerCase();

    // Use pre-compiled regex patterns for better performance
    for (final pattern in _offensivePatterns) {
      if (pattern.hasMatch(lowerMessage)) {
        return true;
      }
    }

    return false;
  }

  /// Handle violation and return appropriate warning message
  Future<String?> _handleViolation() async {
    try {
      _violationCount++;
      await setString('violationCount', _violationCount.toString());

      switch (_violationCount) {
        case 1:
          return "Let's keep things respectful, bro. 🤝";
        case 2:
          return "Bro, I'm here to help, but we have to stay civil.";
        case 3:
          return "Final reminder: no offensive language, or I'll pause our chat.";
        default:
          // Apply lockout after 3rd violation
          await _applyLockout();
          return "Chat paused for 10 minutes due to repeated offensive language. Let's try again later.";
      }
    } catch (e) {
      developer.log('Error handling violation: $e', name: 'ChatScreen');
      return "Let's keep things respectful, bro. 🤝"; // Fallback to first warning
    }
  }

  void _showConfigurationError() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Configuration Error',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4F372D),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'The app is not properly configured. Please contact support.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF4F372D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C6644),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Check if service is configured
    if (!(await _openRouterService.isConfigured)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App not configured. Please check your API key.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Check if chat is locked
    if (_isChatLocked) {
      final remainingTime = _lockedUntil!.difference(DateTime.now());
      final minutes = remainingTime.inMinutes;
      final seconds = remainingTime.inSeconds % 60;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat locked for ${minutes}m ${seconds}s',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Check message limits for free users
    final canSend = await MessageCounterService.instance.canSendMessage();
    if (!canSend) {
      // Show paywall for message limit reached
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(source: 'messages'),
        ),
      );

      // If user purchased premium, refresh subscription status and allow message
      if (result == true) {
        await SubscriptionService.instance.refreshSubscriptionStatus();
        // Continue with sending message
      } else {
        // User didn't purchase, don't send message
        return;
      }
    }

    // Increment message count (this will succeed since we checked canSend above)
    await MessageCounterService.instance.incrementMessageCount();

    // Check for offensive content
    if (_isOffensiveContent(text)) {
      final warningMessage = await _handleViolation();

      if (warningMessage != null) {
        // Add both user message and warning in single setState for better performance
        final userMessage = ChatMessage(role: 'user', content: text);
        final warningChatMessage = ChatMessage(
          role: 'assistant',
          content: warningMessage,
        );

        setState(() {
          _messages.add(userMessage);
          _messages.add(warningChatMessage);
        });

        _messageController.clear();
        _scrollToBottom();

        // Save chat history if enabled
        await _saveChatHistoryIfEnabled();
        return;
      }
    }

    // Add user message
    final userMessage = ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Save immediately after user message
    await _saveChatHistoryIfEnabled();

    try {
      // Create assistant message placeholder
      final assistantMessage = ChatMessage(
        role: 'assistant', 
        content: '', 
        isStreaming: true,
      );
      setState(() {
        _messages.add(assistantMessage);
      });

      // Get streaming response
      developer.log('Starting chat stream for message: $text', name: 'ChatScreen');
      final stream = _openRouterService.chatStream(text, _messages.sublist(0, _messages.length - 1));
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        developer.log('Received chunk: $chunk', name: 'ChatScreen');
        buffer.write(chunk);
        setState(() {
          _messages[_messages.length - 1] = assistantMessage.copyWith(
            content: buffer.toString(),
          );
        });
        _scrollToBottom();
      }

      developer.log('Stream completed, final content: ${buffer.toString()}', name: 'ChatScreen');

      // Mark streaming as complete
      setState(() {
        _messages[_messages.length - 1] = assistantMessage.copyWith(
          content: buffer.toString(),
          isStreaming: false,
        );
      });

      // Save chat history if enabled
      await _saveChatHistoryIfEnabled();

    } catch (e) {
      // Handle error gracefully - the OpenRouterService now handles fallbacks internally
      developer.log('Chat error: $e', name: 'ChatScreen');

      // Remove the streaming placeholder message if it exists
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        setState(() {
          _messages.removeLast();
        });
      }

      String errorMessage;
      bool showSetupButton = false;

      // Check if it's a configuration error
      if (e.toString().contains('Service not configured') ||
          e.toString().contains('missing API key')) {
        errorMessage = 'Please set up your OpenRouter API key in Settings to start chatting. 🔑';
        showSetupButton = true;
      } else {
        errorMessage = 'I\'m having some technical difficulties right now, ${_userGender.casualAddress}. Please try again in a moment. 🤲';
      }

      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: errorMessage,
        ));
      });

      // Show setup button if needed
      if (showSetupButton && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API key required for chat'),
            action: SnackBarAction(
              label: 'Setup',
              onPressed: () {
                Navigator.pushNamed(context, '/openrouter_setup');
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Save the fallback message
      await _saveChatHistoryIfEnabled();
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Background color inherited from card
      backgroundColor: widget.bgColor,
      body: SafeArea(
        child: Column(
            children: [
              // ✨ HEADER: Chat title and model info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.bgColor.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFFCF8F1)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your safe space',
                            style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFCF8F1),
                            ),
                          ),
                          FutureBuilder<String>(
                            future: GenderUtil.getCompanionName(),
                            builder: (context, snapshot) {
                              final companionName = snapshot.data ?? 'Akhi';
                              return Text(
                                'Model: $companionName',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFFCF8F1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Clear chat button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFCF8F1)),
                      onPressed: _showClearChatDialog,
                      tooltip: 'Clear chat',
                    ),
                  ],
                ),
              ),
              
              // ✨ MESSAGES: Chat messages list
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: FutureBuilder<String?>(
                          future: GenderUtil.getDisplayName(),
                          builder: (context, snapshot) {
                            final displayName = snapshot.data ?? 'friend';
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: const Color(0xFFFCF8F1).withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hey $displayName! 👋',
                                  style: GoogleFonts.lexend(
                                    fontSize: 18,
                                    color: const Color(0xFFFCF8F1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'What\'s on your mind today?',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFFFCF8F1).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              
              // ✨ INPUT: Modern chat input field
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF9C6644).withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            enabled: !_isLoading && !_isChatLocked,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF4F372D),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: _isChatLocked ? 'Chat is locked...' : 'Type your message...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF4F372D).withValues(alpha: 0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            cursorColor: const Color(0xFF9C6644),
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Send button
                      Material(
                        color: (_isLoading || _isChatLocked)
                            ? const Color(0xFF9C6644).withValues(alpha: 0.6)
                            : const Color(0xFF9C6644),
                        borderRadius: BorderRadius.circular(24),
                        elevation: _isLoading ? 0 : 2,
                        shadowColor: const Color(0xFF9C6644).withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: (!_isLoading && !_isChatLocked) ? _sendMessage : null,
                          borderRadius: BorderRadius.circular(24),
                          splashColor: const Color(0xFFFCF8F1).withValues(alpha: 0.3),
                          highlightColor: const Color(0xFFFCF8F1).withValues(alpha: 0.1),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFFFCF8F1),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Color(0xFFFCF8F1),
                                    size: 22,
                                  ),
                          ),
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF9C6644),
              child: Text(
                'A',
                style: GoogleFonts.lexend(
                  color: const Color(0xFFFCF8F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFCF8F1) : Colors.white, // Cream color for user messages
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isUser ? const Color(0xFF4F372D) : const Color(0xFF4F372D), // Dark brown text for both user and AI messages
                    ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isUser ? const Color(0xFF9C6644) : const Color(0xFF9C6644), // Brown loading indicator for both
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4F372D),
              child: Text(
                'U',
                style: GoogleFonts.lexend(
                  color: const Color(0xFFFCF8F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Load chat history from persistent storage if enabled
  Future<void> _loadChatHistoryIfEnabled() async {
    try {
      // Check if chat history saving is enabled
      final savingEnabled = await getBool('saveChatHistory', true);
      if (!savingEnabled) {
        return;
      }

      // Try to load the most recent chat session
      final recentHistory = await _hiveService.getMostRecentChatHistory();
      if (recentHistory != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(recentHistory.messages);
          _sessionId = recentHistory.sessionId;
        });
        developer.log('Loaded chat history: $_sessionId with ${_messages.length} messages', name: 'ChatScreen');
        _scrollToBottom();
      }
    } catch (e) {
      developer.log('Failed to load chat history: $e', name: 'ChatScreen');
      // Don't show error to user - loading is optional
    }
  }

  /// Save chat history immediately after each message if enabled
  Future<void> _saveChatHistoryIfEnabled() async {
    try {
      // Check if chat history saving is enabled
      final savingEnabled = await getBool('saveChatHistory', true);
      if (!savingEnabled || _messages.isEmpty) {
        return;
      }

      // Generate session ID if not exists
      _sessionId ??= 'chat_${DateTime.now().millisecondsSinceEpoch}';

      // Check if we already have this session saved
      final existingHistory = await _hiveService.getChatHistoryBySessionId(_sessionId!);

      if (existingHistory != null) {
        // Update existing history
        existingHistory.updateMessages(_messages);
        await _hiveService.updateChatHistory(existingHistory.key, existingHistory);
        developer.log('Updated existing chat history: $_sessionId', name: 'ChatScreen');
      } else {
        // Create new history
        final chatHistory = ChatHistory(
          sessionId: _sessionId!,
          messages: _messages,
          title: _generateChatTitle(),
        );
        await _hiveService.addChatHistory(chatHistory);
        developer.log('Saved new chat history: $_sessionId', name: 'ChatScreen');
      }
    } catch (e) {
      developer.log('Failed to save chat history: $e', name: 'ChatScreen');
      // Don't show error to user - saving is optional
    }
  }

  /// Show dialog to confirm clearing chat history
  void _showClearChatDialog() async {
    final savingEnabled = await getBool('saveChatHistory', true);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.bgColor,
        title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
        content: Text(
          savingEnabled
              ? 'This chat history is saved and encrypted on your device. Clear it permanently?'
              : 'Chat history isn\'t saved. Clear the current conversation?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat(savingEnabled);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Clear chat messages and optionally delete from storage
  Future<void> _clearChat(bool savingEnabled) async {
    try {
      developer.log('=== VERBOSE: _clearChat started ===', name: 'ChatScreen');
      developer.log('VERBOSE: savingEnabled = $savingEnabled, sessionId = $_sessionId', name: 'ChatScreen');
      
      // Clear in-memory messages
      setState(() {
        _messages.clear();
      });
      developer.log('VERBOSE: In-memory messages cleared', name: 'ChatScreen');

      // If saving is enabled, also delete from storage
      if (savingEnabled && _sessionId != null) {
        developer.log('VERBOSE: Attempting to delete from storage for session: $_sessionId', name: 'ChatScreen');
        
        final existingHistory = await _hiveService.getChatHistoryBySessionId(_sessionId!);
        developer.log('VERBOSE: getChatHistoryBySessionId returned: ${existingHistory != null ? "found history with key ${existingHistory.key}" : "null"}', name: 'ChatScreen');
        
        if (existingHistory != null) {
          try {
            developer.log('VERBOSE: Calling deleteChatHistory with key: ${existingHistory.key}', name: 'ChatScreen');
            final deleteResult = await _hiveService.deleteChatHistory(existingHistory.key);
            developer.log('VERBOSE: deleteChatHistory returned: $deleteResult', name: 'ChatScreen');
            
            if (deleteResult) {
              developer.log('VERBOSE: Delete successful - chat history removed from storage', name: 'ChatScreen');
            } else {
              developer.log('VERBOSE: Delete failed - deleteChatHistory returned false', name: 'ChatScreen');
            }
            
            developer.log('Deleted chat history from storage: $_sessionId', name: 'ChatScreen');
          } catch (deleteError) {
            developer.log('VERBOSE: Exception during deleteChatHistory: $deleteError', name: 'ChatScreen');
            rethrow;
          }
        } else {
          developer.log('VERBOSE: No existing history found to delete', name: 'ChatScreen');
        }
      } else {
        developer.log('VERBOSE: Skipping storage deletion - savingEnabled: $savingEnabled, sessionId: $_sessionId', name: 'ChatScreen');
      }

      // Reset session ID to start fresh
      _sessionId = null;
      developer.log('VERBOSE: Session ID reset to null', name: 'ChatScreen');

      developer.log('VERBOSE: Chat cleared successfully', name: 'ChatScreen');
      developer.log('=== VERBOSE: _clearChat completed ===', name: 'ChatScreen');
    } catch (e) {
      developer.log('VERBOSE: Exception in _clearChat: $e', name: 'ChatScreen');
      developer.log('Failed to clear chat: $e', name: 'ChatScreen');
      // Show error to user since this is a user-initiated action
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateChatTitle() {
    // Find first user message for title
    for (final message in _messages) {
      if (message.role == 'user' && message.content.isNotEmpty) {
        final content = message.content.trim();
        if (content.length > 30) {
          return '${content.substring(0, 30)}...';
        }
        return content;
      }
    }
    return 'Chat ${DateTime.now().toString().substring(0, 16)}';
  }
}

