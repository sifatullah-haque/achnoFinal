import 'package:flutter/foundation.dart';
import 'package:achno/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadNotificationCount = 0;
  int _unreadMessageCount = 0;

  final NotificationService _notificationService = NotificationService();

  int get unreadNotificationCount => _unreadNotificationCount;
  int get unreadMessageCount => _unreadMessageCount;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  void initializeListeners() {
    if (currentUserId == null) return;

    // Listen to notifications
    _notificationService.getNotificationsStream().listen((notifications) {
      final unreadCount = notifications.where((n) => !n.isRead).length;
      if (_unreadNotificationCount != unreadCount) {
        _unreadNotificationCount = unreadCount;
        notifyListeners();
      }
    });

    // Listen to unread messages
    FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      int totalUnreadMessages = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts =
            data['unreadCounts'] as Map<String, dynamic>? ?? {};
        final myUnreadCount = unreadCounts[currentUserId] as int? ?? 0;
        totalUnreadMessages += myUnreadCount;
      }

      if (_unreadMessageCount != totalUnreadMessages) {
        _unreadMessageCount = totalUnreadMessages;
        notifyListeners();
      }
    });
  }

  void markNotificationsAsRead() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void markMessagesAsRead() {
    _unreadMessageCount = 0;
    notifyListeners();
  }
}
