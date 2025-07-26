import 'package:flutter/material.dart';
import 'package:achno/pages/chat/components/message_details_controller.dart';
import 'package:achno/pages/chat/components/message_details_view.dart';
import 'package:achno/models/post_model.dart';

class MessageDetails extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String? contactAvatar;
  final String? contactId;
  final Post? relatedPost;

  const MessageDetails({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.contactAvatar,
    this.contactId,
    this.relatedPost,
  });

  @override
  _MessageDetailsState createState() => _MessageDetailsState();
}

class _MessageDetailsState extends State<MessageDetails> {
  late MessageDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MessageDetailsController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize(
      context,
      widget.conversationId,
      widget.contactId,
      widget.relatedPost,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MessageDetailsView(
      controller: _controller,
      conversationId: widget.conversationId,
      contactName: widget.contactName,
      contactAvatar: widget.contactAvatar,
      contactId: widget.contactId,
    );
  }
}
