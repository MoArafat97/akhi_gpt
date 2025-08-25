import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../services/openrouter_service.dart';
import '../services/hive_service.dart';
import '../services/islamic_reminder_service.dart';
import '../services/terms_acceptance_service.dart';
import '../utils/settings_util.dart';
import '../utils/gender_util.dart';
import '../utils/error_handler.dart';
// TESTING MODE: Subscription, message counter, and paywall imports temporarily disabled
// import '../services/subscription_service.dart';
// import '../services/message_counter_service.dart';
// import 'paywall_screen.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Analysis result for message content and emotional context
class MessageAnalysis {
  final bool isHarmful;
  final bool isDistressed;
  final bool needsSupport;

  MessageAnalysis({
    required this.isHarmful,
    required this.isDistressed,
    required this.needsSupport,
  });
}

class ChatScreen extends StatefulWidget {
  final Color bgColor;
  final ChatHistory? resumeFromHistory;

  const ChatScreen({
    super.key,
    this.bgColor = const Color(0xFFFCF8F1),
    this.resumeFromHistory,
  });

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

  // Connection status tracking
  bool _isConnected = false;
  bool _isCheckingConnection = false;

  // Aggression tracking variables
  int _violationCount = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();

    // Defer initialization until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Validate Terms acceptance before allowing chat access
      await _validateTermsAcceptance();

      await _initializeService();
      // Load user gender preference
      _loadUserGender();
      // Load lockout state with error handling
      _loadLockoutState().catchError((error) {
        developer.log('Failed to load lockout state in initState: $error', name: 'ChatScreen');
      });
      // Reset Islamic reminder counter for fresh chat session
      IslamicReminderService.resetCounter();
      // Test connection on startup after service is initialized
      _testConnection();

      // Load chat history - either from resume parameter or most recent
      if (widget.resumeFromHistory != null) {
        _resumeFromChatHistory(widget.resumeFromHistory!);
      } else {
        _loadChatHistoryIfEnabled();
      }
    });
  }

  /// Test OpenRouter connection on startup
  void _testConnection() async {
    print('🔍 CHAT: _testConnection() method called!');
    developer.log('🔍 CHAT: Starting connection test...', name: 'ChatScreen');

    if (mounted) {
      setState(() {
        _isCheckingConnection = true;
      });
    }

    try {
      developer.log('🔍 CHAT: Testing OpenRouter connection...', name: 'ChatScreen');
      final isConnected = await _openRouterService.testConnection();
      developer.log('🔍 CHAT: Connection test result: $isConnected', name: 'ChatScreen');

      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _isCheckingConnection = false;
        });
      }

      if (!isConnected) {
        developer.log('❌ CHAT: OpenRouter connection failed', name: 'ChatScreen');
      } else {
        developer.log('✅ CHAT: OpenRouter connection successful', name: 'ChatScreen');
      }
    } catch (e) {
      developer.log('❌ CHAT: Connection test error: $e', name: 'ChatScreen');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnection = false;
        });
      }
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

  /// Validate Terms and Conditions acceptance before allowing chat access
  /// This is a legal compliance requirement
  Future<void> _validateTermsAcceptance() async {
    try {
      final hasAcceptedTerms = await TermsAcceptanceService.hasAcceptedTerms();

      if (!hasAcceptedTerms && mounted) {
        // User has not accepted terms, redirect to Terms page
        Navigator.pushReplacementNamed(context, '/terms_conditions');
        return;
      }
    } catch (e) {
      // On error, assume terms not accepted for safety
      developer.log('Failed to validate terms acceptance: $e', name: 'ChatScreen');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/terms_conditions');
        return;
      }
    }
  }

  Future<void> _initializeService() async {
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
        ErrorHandler.showWarningSnackBar(
          context,
          'Chat locked for 10 minutes due to inappropriate content. Please use respectful language.',
        );
      }
    } catch (e) {
      developer.log('Error applying lockout: $e', name: 'ChatScreen');
    }
  }

  // Patterns for genuinely harmful content (threats, harassment, etc.)
  static final List<RegExp> _harmfulPatterns = [
    // Direct threats and violence
    RegExp(r'\b(gonna|going to|will|want to).*(kill|hurt|destroy|beat|harm).*(you|myself|someone)\b', caseSensitive: false),
    RegExp(r'\b(kill yourself|kys|end your life)\b', caseSensitive: false),

    // Targeted harassment and personal attacks
    RegExp(r'\byou.*(useless|worthless|pathetic|should die)\b', caseSensitive: false),
    RegExp(r'\b(shut up|fuck off).*(forever|and die|you piece of)\b', caseSensitive: false),

    // Religious/cultural hatred (specific targeting)
    RegExp(r'\b(allah|islam|muslim|religion).*(should die|is evil|deserves to burn)\b', caseSensitive: false),
    RegExp(r'\b(all|every).*(muslims|christians|jews).*(should die|are evil)\b', caseSensitive: false),
  ];

  // Patterns for emotional distress indicators (these should trigger supportive responses)
  static final List<RegExp> _distressPatterns = [
    // Expressions of feeling overwhelmed or mistreated
    RegExp(r'\b(world|life|everything).*(treating me|feels like).*(shit|crap|hell)\b', caseSensitive: false),
    RegExp(r'\b(feel|feeling).*(like shit|terrible|awful|hopeless)\b', caseSensitive: false),
    RegExp(r'\b(everything|life).*(sucks|is shit|is fucked)\b', caseSensitive: false),

    // Frustration with situations
    RegExp(r'\b(this|that).*(is bullshit|is shit|fucking sucks)\b', caseSensitive: false),
    RegExp(r'\b(so|really|fucking).*(frustrated|angry|pissed off)\b', caseSensitive: false),

    // Casual profanity in context of seeking help
    RegExp(r'\b(what the (fuck|hell)|wtf).*(is wrong|should i do|can i do)\b', caseSensitive: false),
  ];

  /// Analyze message content for emotional context and harmful intent
  MessageAnalysis _analyzeMessage(String message) {
    if (message.length < 3) {
      return MessageAnalysis(isHarmful: false, isDistressed: false, needsSupport: false);
    }

    final lowerMessage = message.toLowerCase();

    // Check for genuinely harmful content first
    bool isHarmful = false;
    for (final pattern in _harmfulPatterns) {
      if (pattern.hasMatch(lowerMessage)) {
        isHarmful = true;
        break;
      }
    }

    // Check for emotional distress indicators
    bool isDistressed = false;
    for (final pattern in _distressPatterns) {
      if (pattern.hasMatch(lowerMessage)) {
        isDistressed = true;
        break;
      }
    }

    // Check for help-seeking context (questions, requests for advice)
    bool needsSupport = _isSeekingHelp(lowerMessage) || isDistressed;

    return MessageAnalysis(
      isHarmful: isHarmful,
      isDistressed: isDistressed,
      needsSupport: needsSupport,
    );
  }

  /// Check if message indicates user is seeking help or support
  bool _isSeekingHelp(String message) {
    final helpPatterns = [
      RegExp(r'\b(what should i|what can i|how do i|help me|need advice)\b', caseSensitive: false),
      RegExp(r"\b(i don't know|not sure|confused|lost|stuck)\b", caseSensitive: false),
      RegExp(r'\b(feeling|feel).*(lost|confused|overwhelmed|stuck)\b', caseSensitive: false),
      RegExp(r'\?(.*)(do|help|advice|think|suggest)\b', caseSensitive: false),
    ];

    for (final pattern in helpPatterns) {
      if (pattern.hasMatch(message)) {
        return true;
      }
    }

    return false;
  }

  /// Handle harmful content and return appropriate response
  Future<String?> _handleHarmfulContent() async {
    try {
      _violationCount++;
      await setString('violationCount', _violationCount.toString());

      switch (_violationCount) {
        case 1:
          return "I understand you might be frustrated, but I can't engage with threats or harmful language. I'm here to support you in a positive way. 🤝";
        case 2:
          return "I really want to help you, but I need us to keep our conversation supportive and safe. Can we talk about what's really bothering you?";
        case 3:
          return "I care about your wellbeing, but I have to pause our chat if harmful language continues. Let's try again in a bit when we can focus on helping you.";
        default:
          // Apply lockout after 3rd violation
          await _applyLockout();
          return "Chat paused for 10 minutes. I'm here when you're ready to talk in a way that's helpful for both of us.";
      }
    } catch (e) {
      developer.log('Error handling harmful content: $e', name: 'ChatScreen');
      return "I understand you might be frustrated, but I can't engage with threats or harmful language. I'm here to support you in a positive way. 🤝";
    }
  }

  /// Generate supportive response for distressed users
  Future<String> _generateSupportiveResponse(String message) async {
    final gender = await GenderUtil.getUserGender();
    final companionName = await GenderUtil.getCompanionName();

    // Get personality-appropriate supportive language
    if (gender == UserGender.male) {
      return "I hear you, bro. Sounds like you're going through some tough stuff right now. That really sucks when life feels like it's working against you. Want to talk about what's been weighing on you? I'm here to listen and help however I can. 💪";
    } else {
      return "I hear you, sis. It sounds like you're dealing with some really difficult things right now. It's completely understandable to feel frustrated when everything seems to be going wrong. I'm here for you - want to share what's been on your mind? 💕";
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
        ErrorHandler.showApiConfigurationError(
          context,
          ErrorAnalysis(
            category: ErrorCategory.configuration,
            severity: ErrorSeverity.high,
            userMessage: 'API not configured',
            technicalDetails: 'OpenRouter service not configured',
            shouldRetry: false,
            shouldFallback: false,
            requiresConfiguration: true,
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

    // TESTING MODE: Message limit checks and paywall navigation disabled
    /*
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
    */

    print('🧪 TESTING MODE: Skipping message limit checks and paywall navigation');

    // TESTING MODE: Message count increment disabled
    // await MessageCounterService.instance.incrementMessageCount();
    print('🧪 TESTING MODE: Skipping message count increment');

    // Analyze message for emotional context and harmful content
    final analysis = _analyzeMessage(text);

    // Handle genuinely harmful content
    if (analysis.isHarmful) {
      final warningMessage = await _handleHarmfulContent();

      if (warningMessage != null) {
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
        await _saveChatHistoryIfEnabled();
        return;
      }
    }

    // Handle distressed users with immediate supportive response
    if (analysis.isDistressed && !analysis.isHarmful) {
      final userMessage = ChatMessage(role: 'user', content: text);
      final supportiveResponse = await _generateSupportiveResponse(text);
      final supportMessage = ChatMessage(
        role: 'assistant',
        content: supportiveResponse,
      );

      setState(() {
        _messages.add(userMessage);
        _messages.add(supportMessage);
      });

      _messageController.clear();
      _scrollToBottom();
      await _saveChatHistoryIfEnabled();
      return;
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

      // Check for specific error types and provide helpful messages
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('service not configured') ||
          errorString.contains('missing api key')) {
        errorMessage = 'Please set up your OpenRouter API key in Settings to start chatting. 🔑';
        showSetupButton = true;
      } else if (errorString.contains('rate limit') || errorString.contains('429')) {
        errorMessage = 'The AI service is experiencing high demand right now, ${_userGender.casualAddress}. I\'m trying alternative models, but please be patient. 🤲';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Having trouble connecting to the AI service, ${_userGender.casualAddress}. Please check your internet connection and try again. 📶';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'The request is taking longer than expected, ${_userGender.casualAddress}. Please try again with a shorter message. ⏱️';
      } else if (errorString.contains('401') || errorString.contains('unauthorized')) {
        errorMessage = 'There\'s an issue with the API authentication, ${_userGender.casualAddress}. Please contact support if this continues. 🔐';
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
        ErrorHandler.showErrorSnackBar(
          context,
          'API key required for chat',
          actionLabel: 'Setup',
          onAction: () {
            Navigator.pushNamed(context, '/openrouter_setup');
          },
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

  /// Build connection status indicator
  Widget _buildConnectionStatus() {
    if (_isCheckingConnection) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi,
            size: 12,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 4),
          Text(
            'Checking...',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final statusColor = _isConnected ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final statusIcon = _isConnected ? Icons.wifi : Icons.wifi_off;
    final statusText = _isConnected ? 'Connected' : 'Offline';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusIcon,
          size: 12,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build session indicator
  Widget _buildSessionIndicator() {
    if (_sessionId == null || _messages.isEmpty) {
      return Text(
        'New conversation',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: const Color(0xFF7B4F2F).withOpacity(0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.chat_bubble,
          size: 10,
          color: const Color(0xFF7B4F2F).withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          'Session: ${_sessionId!.substring(_sessionId!.length - 8)}',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF7B4F2F).withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ FEATURE: Cream background
      backgroundColor: const Color(0xFFFCF8F1), // Always cream background
      body: SafeArea(
        child: Column(
            children: [
              // ✨ HEADER: Simple header like the image
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5A3C)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your safe space',
                            style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5A3C),
                            ),
                          ),
                          FutureBuilder<String>(
                            future: GenderUtil.getCompanionName(),
                            builder: (context, snapshot) {
                              final companionName = snapshot.data ?? 'Bro';
                              return Text(
                                'Model: $companionName',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF8B5A3C).withValues(alpha: 0.8),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          // Connection status indicator
                          _buildConnectionStatus(),
                          Text(
                            'New conversation',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF8B5A3C).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action icons like in the image
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined, color: Color(0xFF8B5A3C)),
                      onPressed: _startNewChat,
                      tooltip: 'New chat',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Color(0xFF8B5A3C)),
                      onPressed: () {}, // Save functionality
                      tooltip: 'Save',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF8B5A3C)),
                      onPressed: () {}, // Refresh functionality
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFF8B5A3C)),
                      onPressed: () {}, // Delete functionality
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Color(0xFF7B4F2F), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Clear Chat',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF7B4F2F),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ✨ MESSAGES: Chat messages list
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Brown chat bubble icon like in the image
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5A3C),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 32,
                                color: Color(0xFFFCF8F1),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Hey friend! 👋',
                              style: GoogleFonts.lexend(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8B5A3C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'What\'s on your mind today?',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: const Color(0xFF8B5A3C).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
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
              backgroundColor: const Color(0xFF8B5A3C), // Earthy brown
              child: Text(
                'A',
                style: GoogleFonts.lexend(
                  color: const Color(0xFFFCF8F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5A3C), // Earthy brown for message boxes
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
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
                      fontSize: 15,
                      color: const Color(0xFFFCF8F1), // Cream text
                      height: 1.4,
                    ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFFFCF8F1), // Cream loading indicator
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B4226), // Darker brown for user
              child: Text(
                'U',
                style: GoogleFonts.lexend(
                  color: const Color(0xFFFCF8F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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

  /// Resume from a specific chat history
  void _resumeFromChatHistory(ChatHistory chatHistory) {
    try {
      setState(() {
        _messages.clear();
        _messages.addAll(chatHistory.messages);
        _sessionId = chatHistory.sessionId;
      });
      developer.log('Resumed chat history: $_sessionId with ${_messages.length} messages', name: 'ChatScreen');
      _scrollToBottom();
    } catch (e) {
      developer.log('Failed to resume chat history: $e', name: 'ChatScreen');
      // Don't show error to user - fallback to empty chat
    }
  }

  /// Navigate to chat history page - Feature removed for minimal app structure
  void _navigateToChatHistory() {
    // Chat history page removed - show simple message instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat history feature is not available in this version'),
        duration: Duration(seconds: 2),
      ),
    );
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
        await _hiveService.updateChatHistory(existingHistory.key as int, existingHistory);
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

  /// Manually save the current chat session
  Future<void> _saveCurrentChatManually() async {
    try {
      // Check if chat history saving is enabled
      final savingEnabled = await getBool('saveChatHistory', true);
      if (!savingEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat history saving is disabled in settings'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (_messages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No messages to save'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate session ID if not exists
      _sessionId ??= 'chat_${DateTime.now().millisecondsSinceEpoch}';

      // Check if we already have this session saved
      final existingHistory = await _hiveService.getChatHistoryBySessionId(_sessionId!);

      if (existingHistory != null) {
        // Update existing history
        existingHistory.updateMessages(_messages);
        await _hiveService.updateChatHistory(existingHistory.key as int, existingHistory);
        developer.log('Manually updated existing chat history: $_sessionId', name: 'ChatScreen');
      } else {
        // Create new history
        final chatHistory = ChatHistory(
          sessionId: _sessionId!,
          messages: _messages,
          title: _generateChatTitle(),
        );
        await _hiveService.addChatHistory(chatHistory);
        developer.log('Manually saved new chat history: $_sessionId', name: 'ChatScreen');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Failed to manually save chat history: $e', name: 'ChatScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start a new chat session while preserving the current one
  Future<void> _startNewChat() async {
    try {
      // Save current chat if it has messages
      if (_messages.isNotEmpty) {
        await _saveCurrentChatManually();
      }

      // Clear current chat interface
      setState(() {
        _messages.clear();
        _sessionId = null; // This will generate a new session ID when needed
      });

      // Reset Islamic reminder counter for new chat session
      IslamicReminderService.resetCounter();

      developer.log('Started new chat session', name: 'ChatScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Started new chat'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      developer.log('Failed to start new chat: $e', name: 'ChatScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start new chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Switch to a different chat session, saving current one first
  Future<void> _switchToChatSession(ChatHistory chatHistory) async {
    try {
      // Save current chat if it has messages and is different from the target
      if (_messages.isNotEmpty && _sessionId != chatHistory.sessionId) {
        await _saveCurrentChatManually();
      }

      // Load the target chat session
      setState(() {
        _messages.clear();
        _messages.addAll(chatHistory.messages);
        _sessionId = chatHistory.sessionId;
      });

      developer.log('Switched to chat session: ${chatHistory.sessionId}', name: 'ChatScreen');
      _scrollToBottom();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to: ${chatHistory.title ?? 'Chat'}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      developer.log('Failed to switch chat session: $e', name: 'ChatScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Clear Chat', style: TextStyle(color: Color(0xFF4F372D))),
        content: Text(
          savingEnabled
              ? 'This chat history is saved and encrypted on your device. Clear it permanently?'
              : 'Chat history isn\'t saved. Clear the current conversation?',
          style: const TextStyle(color: Color(0xFF4F372D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Color(0xFF4F372D))),
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

