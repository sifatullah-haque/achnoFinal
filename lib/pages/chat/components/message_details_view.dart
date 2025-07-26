import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:achno/config/theme.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/pages/chat/components/message_details_controller.dart';
import 'package:achno/pages/chat/components/message_details_widgets.dart';
import 'package:achno/pages/profile/viewProfile.dart';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';

class MessageDetailsView extends StatefulWidget {
  final MessageDetailsController controller;
  final String conversationId;
  final String contactName;
  final String? contactAvatar;
  final String? contactId;

  const MessageDetailsView({
    super.key,
    required this.controller,
    required this.conversationId,
    required this.contactName,
    this.contactAvatar,
    this.contactId,
  });

  @override
  State<MessageDetailsView> createState() => _MessageDetailsViewState();
}

class _MessageDetailsViewState extends State<MessageDetailsView>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _micAnimationController;
  late AnimationController _sendButtonAnimationController;
  late Animation<double> _micAnimation;
  late AnimationController _audioVisualizationController;

  // Fixed random seed for consistent avatar color
  final int _avatarColorSeed = 42;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupMessageController();
  }

  void _initializeAnimations() {
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _audioVisualizationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _setupMessageController() {
    _messageController.addListener(_handleTextFieldChange);
  }

  void _handleTextFieldChange() {
    if (_messageController.text.isNotEmpty) {
      if (!_sendButtonAnimationController.isCompleted) {
        _sendButtonAnimationController.forward();
      }
    } else {
      if (_sendButtonAnimationController.isCompleted) {
        _sendButtonAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    _audioVisualizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              iconTheme: IconThemeData(
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
              title: GestureDetector(
                onTap: _navigateToContactProfile,
                child: Row(
                  children: [
                    _buildContactAvatar(),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contactName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.controller.contactCity.isNotEmpty
                                ? widget.controller.contactCity
                                : (l10n.user ?? 'User'),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showChatOptions();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background patterns
            Positioned(
              top: -50.h,
              left: -50.w,
              child: Container(
                height: 200.h,
                width: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100.h,
              right: -60.w,
              child: Container(
                height: 250.h,
                width: 250.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withOpacity(0.05),
                ),
              ),
            ),

            // Chat content
            Column(
              children: [
                // Post reference bar
                if (widget.controller.relatedPost != null)
                  MessageDetailsWidgets.buildPostReferenceBar(
                    context,
                    widget.controller.relatedPost!,
                    isDarkMode,
                    () => _showPostDetailsBottomSheet(),
                  ),

                // Messages list
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, child) {
                      if (widget.controller.isLoading) {
                        return MessageDetailsWidgets.buildLoadingState(context);
                      }

                      return _buildMessagesList(context);
                    },
                  ),
                ),

                // Input field and actions
                _buildMessageInput(isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar() {
    if (widget.contactAvatar != null) {
      return GestureDetector(
        onTap: _navigateToContactProfile,
        child: CircleAvatar(
          radius: 18.r,
          backgroundImage: NetworkImage(widget.contactAvatar!),
        ),
      );
    }

    // Fallback avatar with first letter - use fixed color seed
    return GestureDetector(
      onTap: _navigateToContactProfile,
      child: CircleAvatar(
        radius: 18.r,
        backgroundColor: Color(
                (math.Random(_avatarColorSeed).nextDouble() * 0xFFFFFF).toInt())
            .withOpacity(1.0),
        child: Text(
          widget.contactName.isNotEmpty
              ? widget.contactName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Debug logging
    debugPrint('Messages count: ${widget.controller.messages.length}');
    debugPrint('Current user ID: ${widget.controller.currentUserId}');
    debugPrint('Conversation ID: ${widget.conversationId}');

    if (widget.controller.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.sp,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noMessages ?? 'No messages yet',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start a conversation with ${widget.contactName}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: widget.controller.messages.length,
      itemBuilder: (context, index) {
        final message = widget.controller.messages[index];
        final isMe = message.senderId == widget.controller.currentUserId;
        final showTimestamp = index == 0 ||
            _shouldShowTimestamp(
                widget.controller.messages[index - 1].timestamp,
                message.timestamp);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTimestamp)
              MessageDetailsWidgets.buildDateDivider(
                  context, message.timestamp),
            MessageDetailsWidgets.buildMessageBubble(
              message,
              isMe,
              widget.controller,
              _audioVisualizationController,
              context,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowTimestamp(DateTime previous, DateTime current) {
    // Show timestamp if messages are at least 30 minutes apart
    return current.difference(previous).inMinutes >= 30;
  }

  Widget _buildMessageInput(bool isDarkMode) {
    final l10n = AppLocalizations.of(context);
    final hasTextToSend = _messageController.text.trim().isNotEmpty;
    final hasAudioToSend = widget.controller.recordingStopped &&
        widget.controller.recordedAudioPath != null;
    final canSend = (hasTextToSend || hasAudioToSend) &&
        !widget.controller.isSendingMessage &&
        !widget.controller.isSendingAudio &&
        !widget.controller.isSendingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Expanded text field or recording view
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: widget.controller.isRecording ||
                      widget.controller.recordingStopped
                  ? MessageDetailsWidgets.buildRecordingView(
                      context,
                      widget.controller,
                      _audioVisualizationController,
                      () => widget.controller.deleteAudioRecording(),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText:
                                  l10n.typeAMessage ?? 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryColor
                                    .withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                            ),
                            onChanged: (_) => setState(() {}),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: widget.controller.isSendingImage
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : const Icon(
                                  Icons.attach_file,
                                  color: AppTheme.textSecondaryColor,
                                ),
                          onPressed: widget.controller.isSendingImage
                              ? null
                              : () => widget.controller.pickAndSendImage(
                                  widget.conversationId, widget.contactId),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(width: 8.w),

          // Audio button - only show when not in stopped recording state
          if (!widget.controller.recordingStopped)
            GestureDetector(
              onTap: widget.controller.isRecording
                  ? () => widget.controller.stopRecording()
                  : (widget.controller.micPermissionStatus ==
                          PermissionStatus.granted
                      ? () => widget.controller.startRecording()
                      : () => widget.controller.requestMicrophonePermission()),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.controller.isRecording
                      ? Colors.red
                      : isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey[200],
                ),
                child: Icon(
                  widget.controller.isRecording
                      ? Icons.stop
                      : (widget.controller.micPermissionStatus ==
                              PermissionStatus.granted
                          ? Icons.mic
                          : Icons.mic_off),
                  color: widget.controller.isRecording
                      ? Colors.white
                      : AppTheme.textSecondaryColor,
                  size: 20.w,
                ),
              ),
            ),

          SizedBox(width: 8.w),

          // Send button - always show
          GestureDetector(
            onTap: canSend ? () => _sendMessage() : null,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canSend
                    ? AppTheme.primaryColor
                    : isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[200],
              ),
              child: (widget.controller.isSendingMessage ||
                      widget.controller.isSendingAudio)
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color:
                          canSend ? Colors.white : AppTheme.textSecondaryColor,
                      size: 20.w,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    widget.controller.sendTextMessage(
      widget.conversationId,
      text,
      widget.contactId,
    );
    _messageController.clear();
    _scrollToBottom();
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

  void _navigateToContactProfile() {
    if (widget.contactId != null && widget.contactId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ViewProfile(userId: widget.contactId!),
        ),
      );
    }
  }

  void _showChatOptions() {
    // Implementation for chat options menu
    // This would show options like view profile, clear chat, etc.
  }

  void _showPostDetailsBottomSheet() {
    // Implementation for showing post details
    // This would show the related post in a bottom sheet
  }
}
