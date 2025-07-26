import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:achno/config/theme.dart';
import 'dart:math' as math;
import 'package:timeago/timeago.dart' as timeago;
import 'package:achno/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:achno/pages/chat/messageDetails.dart';
import 'package:achno/pages/chat/components/chat_controller.dart';
import 'package:achno/pages/chat/components/chat_states.dart';
import 'package:achno/pages/chat/components/chat_search.dart';

class ChatView extends StatefulWidget {
  final ChatController controller;
  final VoidCallback? onRefresh;

  const ChatView({
    super.key,
    required this.controller,
    this.onRefresh,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              title: Text(
                l10n.messages ?? 'Messages',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _showSearchDialog();
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

            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return ChatStates.buildLoadingState(context);
        }

        if (widget.controller.filteredConversations.isEmpty) {
          if (widget.controller.isSearching) {
            return ChatStates.buildNoSearchResultsState(context);
          } else {
            return ChatStates.buildEmptyState(context);
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await widget.controller.refreshConversations();
            widget.onRefresh?.call();
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: widget.controller.filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation =
                  widget.controller.filteredConversations[index];
              return _buildConversationTile(conversation, isDarkMode);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationTile(
      ChatConversation conversation, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]!.withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            _navigateToMessageDetails(conversation);
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildAvatar(conversation),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.participantName,
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
                          ),
                          if (conversation.lastMessageTimestamp != null)
                            Text(
                              timeago
                                  .format(conversation.lastMessageTimestamp!),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getLastMessageText(conversation),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatConversation conversation) {
    if (conversation.participantAvatar != null) {
      return CircleAvatar(
        radius: 24.r,
        backgroundImage: NetworkImage(conversation.participantAvatar!),
      );
    }

    // Fallback avatar with first letter
    return CircleAvatar(
      radius: 24.r,
      backgroundColor: Color(
              (math.Random(conversation.participantName.hashCode).nextDouble() *
                      0xFFFFFF)
                  .toInt())
          .withOpacity(1.0),
      child: Text(
        conversation.participantName.isNotEmpty
            ? conversation.participantName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getLastMessageText(ChatConversation conversation) {
    final l10n = AppLocalizations.of(context);

    switch (conversation.lastMessageType) {
      case 'audio':
        return l10n.audioMessage ?? 'Audio message';
      case 'image':
        return l10n.image ?? 'Image';
      default:
        return conversation.lastMessage;
    }
  }

  void _navigateToMessageDetails(ChatConversation conversation) {
    context.push('/chat/${conversation.id}', extra: {
      'contactName': conversation.participantName,
      'contactAvatar': conversation.participantAvatar,
      'contactId': conversation.participantId,
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => ChatSearch(
        controller: widget.controller,
      ),
    );
  }
}
