class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to Map for API calls
  Map<String, String> toMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  // Create a copy with updated content (useful for streaming)
  ChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(role: $role, content: $content, timestamp: $timestamp, isStreaming: $isStreaming)';
  }
}
