import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../models/chat_history.dart';
import '../services/hive_service.dart';
import '../utils/settings_util.dart';
import 'chat_screen.dart';

class ChatHistoryPage extends StatefulWidget {
  final Color bgColor;
  final String? currentSessionId;
  final Function(ChatHistory)? onSwitchToSession;

  const ChatHistoryPage({
    super.key,
    this.bgColor = const Color(0xFFFCF8F1),
    this.currentSessionId,
    this.onSwitchToSession,
  });

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final HiveService _hiveService = HiveService.instance;
  List<ChatHistory> _chatHistories = [];
  bool _isLoading = true;
  bool _savingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    try {
      setState(() => _isLoading = true);
      
      // Check if chat history saving is enabled
      _savingEnabled = await getBool('saveChatHistory', true);
      
      if (_savingEnabled) {
        final histories = await _hiveService.getAllChatHistories();
        setState(() {
          _chatHistories = histories;
          _isLoading = false;
        });
        developer.log('Loaded ${histories.length} chat histories', name: 'ChatHistoryPage');
      } else {
        setState(() {
          _chatHistories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Failed to load chat histories: $e', name: 'ChatHistoryPage');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChatHistory(ChatHistory chatHistory) async {
    try {
      final confirmed = await _showDeleteConfirmation(chatHistory);
      if (!confirmed) return;

      await _hiveService.deleteChatHistory(chatHistory.key);
      await _loadChatHistories(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat history deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      developer.log('Failed to delete chat history: $e', name: 'ChatHistoryPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete chat history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(ChatHistory chatHistory) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFCF8F1),
        title: Text(
          'Delete Chat History',
          style: GoogleFonts.lexend(
            color: const Color(0xFF7B4F2F),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${chatHistory.title ?? 'Untitled Chat'}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            color: const Color(0xFF7B4F2F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF7B4F2F).withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _resumeChatHistory(ChatHistory chatHistory) {
    // If we have a session switching callback, use it
    if (widget.onSwitchToSession != null) {
      widget.onSwitchToSession!(chatHistory);
      Navigator.of(context).pop(); // Go back to chat screen
    } else {
      // Fallback to the original behavior
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            bgColor: widget.bgColor,
            resumeFromHistory: chatHistory,
          ),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B4F2F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat History',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7B4F2F),
          ),
        ),
        actions: [
          if (_chatHistories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF7B4F2F)),
              onPressed: _loadChatHistories,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_savingEnabled) {
      return _buildDisabledMessage();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B4F2F)),
        ),
      );
    }

    if (_chatHistories.isEmpty) {
      return _buildEmptyState();
    }

    return _buildHistoryList();
  }

  Widget _buildDisabledMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: const Color(0xFF7B4F2F).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat History Disabled',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B4F2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat history saving is currently disabled. Enable it in Settings to start saving your conversations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF7B4F2F).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: const Color(0xFF7B4F2F).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Chat History',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B4F2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your previous conversations will appear here once you start chatting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF7B4F2F).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistories.length,
      itemBuilder: (context, index) {
        final chatHistory = _chatHistories[index];
        return _buildHistoryCard(chatHistory);
      },
    );
  }

  Widget _buildHistoryCard(ChatHistory chatHistory) {
    final messageCount = chatHistory.messages.length;
    final lastMessage = chatHistory.messages.isNotEmpty
        ? chatHistory.messages.last.content
        : 'No messages';
    final isCurrentSession = widget.currentSessionId == chatHistory.sessionId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentSession
          ? const Color(0xFF7B4F2F).withOpacity(0.1)
          : const Color(0xFFB7AFA3).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentSession
            ? const BorderSide(color: Color(0xFF7B4F2F), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _resumeChatHistory(chatHistory),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Chat icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4F2F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF7B4F2F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Chat details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatHistory.title ?? 'Untitled Chat',
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7B4F2F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentSession) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B4F2F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7B4F2F).withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTimestamp(chatHistory.lastUpdated),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF7B4F2F).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$messageCount message${messageCount == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF7B4F2F).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _deleteChatHistory(chatHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
