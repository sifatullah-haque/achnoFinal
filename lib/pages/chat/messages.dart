import 'package:flutter/material.dart';
import 'package:achno/pages/chat/components/chat_controller.dart';
import 'package:achno/pages/chat/components/chat_view.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  late ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatView(
      controller: _controller,
      onRefresh: () {
        // Handle refresh if needed
      },
    );
  }
}
