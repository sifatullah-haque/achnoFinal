import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:achno/config/theme.dart';
import 'dart:math' as math;
import 'package:timeago/timeago.dart' as timeago;
import 'package:achno/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:achno/pages/chat/messageDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  // Replace mock data with real data from Firestore
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  final bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<ChatConversation> _filteredConversations = [];

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _searchController.addListener(_filterConversations);

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

  // Get current user and load conversations
  Future<void> _getCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      setState(() {
        _currentUserId = authProvider.currentUser!.id;
      });
      _loadConversations();
      _setupConversationsListener();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load conversations from Firestore
  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Query conversations where current user is a participant
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();

      final List<ChatConversation> conversations = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();

          // Get the other participant's ID
          final List<String> participants =
              List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != _currentUserId!,
            orElse: () => '',
          );

          if (otherUserId.isEmpty) continue;

          // Get the other participant's user data
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

          if (!userDoc.exists) continue;

          final userData = userDoc.data()!;

          // Calculate unread count for current user
          final unreadCount = data['unreadCount']?[_currentUserId] ?? 0;

          conversations.add(ChatConversation(
            id: doc.id,
            contactId: otherUserId,
            contactName: '${userData['firstName']} ${userData['lastName']}',
            contactAvatar: userData['profilePicture'],
            lastMessage: data['lastMessage'] ?? '',
            timestamp: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            unreadCount: unreadCount,
          ));
        } catch (e) {
          debugPrint('Error processing conversation ${doc.id}: $e');
          // Continue to next conversation if one fails
          continue;
        }
      }

      setState(() {
        _conversations = conversations;
        _filteredConversations = List.from(_conversations);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingConversations ??
                'Error loading conversations. Please try again.'),
            action: SnackBarAction(
              label: l10n.retry ?? 'Retry',
              onPressed: _loadConversations,
            ),
          ),
        );
      }
    }
  }

  // Setup listener for new conversations or updates
  void _setupConversationsListener() {
    if (_currentUserId == null) return;

    FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterConversations() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredConversations = List.from(_conversations);
      });
    } else {
      setState(() {
        _filteredConversations = _conversations
            .where((conversation) => conversation.contactName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  // Navigate to message details
  void _navigateToMessageDetails(ChatConversation conversation) async {
    try {
      // Fix: Use proper navigation with conversation ID and contact details
      context.push('/chat/${conversation.id}', extra: {
        'contactName': conversation.contactName,
        'contactAvatar': conversation.contactAvatar,
        'contactId': conversation.contactId,
      });

      // Refresh conversations after returning from message details
      if (mounted) {
        _loadConversations();
      }
    } catch (e) {
      // Log the error to console for debugging
      debugPrint('Error navigating to message details: $e');

      // Show error to user
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotOpenConversation ??
              'Could not open conversation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Use translatable strings as a fallback
    final messagesTitle = l10n.messages;
    final searchHint = l10n.search;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(24.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
              title: Text(
                messagesTitle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Stack(
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

          // Content
          SafeArea(
            child: Column(
              children: [
                // Search bar
                Container(
                  margin: EdgeInsets.all(16.w),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),

                // Messages list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredConversations.isEmpty
                          ? _buildEmptyState(context)
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: _filteredConversations.length,
                                itemBuilder: (context, index) {
                                  return _buildConversationItem(
                                      _filteredConversations[index]);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Fallback text if translations are missing
    final noMessagesText = l10n.noMessages ?? 'No messages yet';
    final startConversationText =
        l10n.startConversation ?? 'Start a conversation with someone';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            noMessagesText,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              startConversationText,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation conversation) {
    final l10n = AppLocalizations.of(context);
    const textColor = AppTheme.textPrimaryColor;
    const subtitleColor = AppTheme.textSecondaryColor;
    const accentColor = AppTheme.primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          leading: Stack(
            children: [
              _buildAvatar(conversation, accentColor),
              if (conversation.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.contactName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Text(
                timeago.format(conversation.timestamp),
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          subtitle: Text(
            conversation.lastMessage.isEmpty
                ? l10n.noMessages ?? 'No messages yet'
                : conversation.lastMessage,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _navigateToMessageDetails(conversation),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatConversation conversation, Color accentColor) {
    if (conversation.contactAvatar != null) {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: conversation.unreadCount > 0
                ? accentColor
                : Colors.grey.withOpacity(0.3),
            width: conversation.unreadCount > 0 ? 2 : 1,
          ),
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(conversation.contactAvatar!),
        ),
      );
    }

    // Fallback avatar with first letter of contact name
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: conversation.unreadCount > 0
              ? accentColor
              : Colors.grey.withOpacity(0.3),
          width: conversation.unreadCount > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 23.r,
        backgroundColor: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
            .withOpacity(1.0),
        child: Text(
          conversation.contactName.isNotEmpty
              ? conversation.contactName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Update data model for chat conversations
class ChatConversation {
  final String id;
  final String contactId; // Add contact ID
  final String contactName;
  final String? contactAvatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.contactId, // Add this field
    required this.contactName,
    this.contactAvatar,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
  });
}
