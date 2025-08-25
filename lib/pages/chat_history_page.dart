import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_history.dart';
import '../services/hive_service.dart';
import 'chat_screen.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final HiveService _hiveService = HiveService.instance;
  List<ChatHistory> _chatHistories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final histories = await _hiveService.getAllChatHistories();
      setState(() {
        _chatHistories = histories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteChatHistory(ChatHistory chatHistory) async {
    try {
      await _hiveService.deleteChatHistory(chatHistory.key);
      await _loadChatHistories(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openChatHistory(ChatHistory chatHistory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          resumeFromHistory: chatHistory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F1), // Cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5A3C),
        title: Text(
          'Chat History',
          style: GoogleFonts.lexend(
            color: const Color(0xFFFCF8F1),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFCF8F1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5A3C),
              ),
            )
          : _chatHistories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: const Color(0xFF8B5A3C).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No chat history found',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          color: const Color(0xFF8B5A3C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation to see your chat history here',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF8B5A3C).withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatHistories.length,
                  itemBuilder: (context, index) {
                    final chatHistory = _chatHistories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5A3C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF8B5A3C),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          chatHistory.title ?? 'Chat ${index + 1}',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B5A3C),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${chatHistory.messageCount} messages',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8B5A3C).withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last updated: ${_formatDate(chatHistory.lastUpdated)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8B5A3C).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF8B5A3C)),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(chatHistory);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.inter(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openChatHistory(chatHistory),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation(ChatHistory chatHistory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFCF8F1),
        title: Text(
          'Delete Chat',
          style: GoogleFonts.lexend(color: const Color(0xFF8B5A3C)),
        ),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: GoogleFonts.inter(color: const Color(0xFF8B5A3C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF8B5A3C)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChatHistory(chatHistory);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
