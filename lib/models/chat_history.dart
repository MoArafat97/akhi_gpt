import 'package:hive/hive.dart';
import 'chat_message.dart';

part 'chat_history.g.dart';

@HiveType(typeId: 3)
class ChatHistory extends HiveObject {
  @HiveField(0)
  late String sessionId;

  @HiveField(1)
  late DateTime createdAt;

  @HiveField(2)
  late DateTime lastUpdated;

  @HiveField(3)
  late List<String> messageRoles;

  @HiveField(4)
  late List<String> messageContents;

  @HiveField(5)
  late List<DateTime> messageTimestamps;

  @HiveField(6)
  String? title; // Optional title for the conversation

  // Constructor
  ChatHistory({
    required this.sessionId,
    List<ChatMessage>? messages,
    this.title,
  }) {
    createdAt = DateTime.now();
    lastUpdated = DateTime.now();
    _setMessages(messages ?? []);
  }

  // Named constructor with custom dates
  ChatHistory.withDates({
    required this.sessionId,
    List<ChatMessage>? messages,
    required DateTime customCreatedAt,
    required DateTime customLastUpdated,
    this.title,
  }) {
    createdAt = customCreatedAt;
    lastUpdated = customLastUpdated;
    _setMessages(messages ?? []);
  }

  // Helper method to set messages from ChatMessage list
  void _setMessages(List<ChatMessage> messages) {
    messageRoles = messages.map((m) => m.role).toList();
    messageContents = messages.map((m) => m.content).toList();
    messageTimestamps = messages.map((m) => m.timestamp).toList();
  }

  // Convert back to ChatMessage list
  List<ChatMessage> get messages {
    final result = <ChatMessage>[];
    for (int i = 0; i < messageRoles.length; i++) {
      result.add(ChatMessage(
        role: messageRoles[i],
        content: messageContents[i],
        timestamp: messageTimestamps[i],
      ));
    }
    return result;
  }

  // Update messages and timestamp
  void updateMessages(List<ChatMessage> messages) {
    _setMessages(messages);
    lastUpdated = DateTime.now();
  }

  // Get conversation preview (first user message or title)
  String get preview {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    
    // Find first user message
    for (int i = 0; i < messageRoles.length; i++) {
      if (messageRoles[i] == 'user' && messageContents[i].isNotEmpty) {
        final content = messageContents[i];
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      }
    }
    
    return 'Empty conversation';
  }

  // Get message count
  int get messageCount => messageRoles.length;

  // Get duration of conversation
  Duration get duration {
    if (messageTimestamps.isEmpty) return Duration.zero;
    final first = messageTimestamps.first;
    final last = messageTimestamps.last;
    return last.difference(first);
  }

  // Check if conversation is from today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
           createdAt.month == now.month &&
           createdAt.day == now.day;
  }

  // Check if conversation is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return createdAt.isAfter(weekStart);
  }

  // Export to different formats
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'messageCount': messageCount,
      'messages': messages.map((m) => {
        'role': m.role,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
    };
  }

  // Export as plain text
  String toPlainText() {
    final buffer = StringBuffer();
    buffer.writeln('Chat Session: ${title ?? sessionId}');
    buffer.writeln('Created: ${createdAt.toString()}');
    buffer.writeln('Messages: $messageCount');
    buffer.writeln('${'=' * 50}');
    buffer.writeln();

    for (final message in messages) {
      final role = message.role == 'user' ? 'You' : 'Akhi';
      buffer.writeln('[$role] ${message.timestamp.toString()}');
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Export as markdown
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Chat Session: ${title ?? sessionId}');
    buffer.writeln();
    buffer.writeln('**Created:** ${createdAt.toString()}');
    buffer.writeln('**Messages:** $messageCount');
    buffer.writeln();

    for (final message in messages) {
      final role = message.role == 'user' ? 'You' : 'Akhi';
      buffer.writeln('## $role');
      buffer.writeln('*${message.timestamp.toString()}*');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
