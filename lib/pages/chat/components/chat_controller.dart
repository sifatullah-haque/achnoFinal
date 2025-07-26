import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';

class ChatController extends ChangeNotifier {
  // Conversations data
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _isSearching = false;

  // Getters
  List<ChatConversation> get conversations => _conversations;
  List<ChatConversation> get filteredConversations => _filteredConversations;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  bool get isSearching => _isSearching;

  // Initialize controller
  Future<void> initialize(BuildContext context) async {
    await _getCurrentUser(context);
    if (_currentUserId != null) {
      await _loadConversations();
      _setupConversationsListener();
    } else {
      _setLoading(false);
    }
  }

  // Get current user
  Future<void> _getCurrentUser(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _currentUserId = authProvider.currentUser!.id;
      notifyListeners();
    }
  }

  // Load conversations from Firestore
  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      _setLoading(false);
      return;
    }

    _setLoading(true);

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
          final participants = List<String>.from(data['participants'] ?? []);

          // Get the other participant (not current user)
          final otherParticipantId =
              participants.where((id) => id != _currentUserId).firstOrNull;

          if (otherParticipantId != null) {
            // Get user data for the other participant
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherParticipantId)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final conversation = ChatConversation(
                id: doc.id,
                participantId: otherParticipantId,
                participantName: userData['name'] ?? 'Unknown User',
                participantAvatar: userData['avatar'],
                lastMessage: data['lastMessage'] ?? '',
                lastMessageType: data['lastMessageType'] ?? 'text',
                lastMessageTimestamp:
                    (data['lastMessageTimestamp'] as Timestamp?)?.toDate(),
                unreadCount:
                    (data['unreadCount']?[_currentUserId] as int?) ?? 0,
              );
              conversations.add(conversation);
            }
          }
        } catch (e) {
          debugPrint('Error processing conversation ${doc.id}: $e');
        }
      }

      _conversations = conversations;
      _filteredConversations = conversations;
      _setLoading(false);
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _setLoading(false);
    }
  }

  // Setup real-time listener for conversations
  void _setupConversationsListener() {
    if (_currentUserId == null) return;

    FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      _loadConversations();
    });
  }

  // Filter conversations based on search query
  void filterConversations(String query) {
    if (query.isEmpty) {
      _filteredConversations = _conversations;
    } else {
      _filteredConversations = _conversations
          .where((conversation) => conversation.participantName
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    _isSearching = query.isNotEmpty;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _filteredConversations = _conversations;
    _isSearching = false;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh conversations
  Future<void> refreshConversations() async {
    await _loadConversations();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Chat conversation model
class ChatConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageType,
    this.lastMessageTimestamp,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTimestamp': lastMessageTimestamp,
      'unreadCount': unreadCount,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'],
      participantId: map['participantId'],
      participantName: map['participantName'],
      participantAvatar: map['participantAvatar'],
      lastMessage: map['lastMessage'],
      lastMessageType: map['lastMessageType'],
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? (map['lastMessageTimestamp'] as Timestamp).toDate()
          : null,
      unreadCount: map['unreadCount'],
    );
  }
}
