import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatPage extends StatelessWidget {
  final Color bgColor;

  const ChatPage({super.key, this.bgColor = const Color(0xFF7B4F2F)});

  @override
  Widget build(BuildContext context) {
    // Redirect to existing ChatScreen with background color
    return ChatScreen(bgColor: bgColor);
  }
}
