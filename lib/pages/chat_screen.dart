import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../services/openrouter_service.dart';
import '../services/hive_service.dart';
import '../utils/settings_util.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeService() {
    setState(() {
      _currentModel = _openRouterService.modelDisplayName;
    });

    // Check if service is configured and show error if not
    developer.log('Service configured: ${_openRouterService.isConfigured}', name: 'ChatScreen');
    if (!_openRouterService.isConfigured) {
      _showConfigurationError();
    }
  }

  void _showConfigurationError() {
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

    // Add user message
    final userMessage = ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

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

      // The service should have already provided a fallback response through the stream
      // If we reach here, it means the stream failed completely, so we provide a minimal fallback
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'I\'m having some technical difficulties right now, akhi. Please try again in a moment. 🤲',
        ));
      });
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
      body: Container(
        child: SafeArea(
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
                            'Chat with Akhi',
                            style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFCF8F1),
                            ),
                          ),
                          Text(
                            'Model: $_currentModel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFFCF8F1),
                            ),
                          ),
                        ],
                      ),
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
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: const Color(0xFFFCF8F1).withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                color: const Color(0xFFFCF8F1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type a message below to begin',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFFFCF8F1).withValues(alpha: 0.7),
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
                            enabled: !_isLoading,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF4F372D),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
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
                        color: _isLoading
                            ? const Color(0xFF9C6644).withValues(alpha: 0.6)
                            : const Color(0xFF9C6644),
                        borderRadius: BorderRadius.circular(24),
                        elevation: _isLoading ? 0 : 2,
                        shadowColor: const Color(0xFF9C6644).withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: !_isLoading ? _sendMessage : null,
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

  Future<void> _saveChatHistoryIfEnabled() async {
    try {
      // Check if chat history saving is enabled
      final savingEnabled = await getBool('saveChatHistory', false);
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

