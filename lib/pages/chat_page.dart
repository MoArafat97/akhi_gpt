import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatPage extends StatelessWidget {
  final Color bgColor;

  const ChatPage({super.key, this.bgColor = const Color(0xFFFCF8F1)});

  @override
  Widget build(BuildContext context) {
    // Redirect to existing ChatScreen with background color
    return ChatScreen(bgColor: bgColor);
  }
}
