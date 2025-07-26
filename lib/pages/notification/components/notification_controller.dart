import 'package:flutter/material.dart';
import 'package:achno/models/notification_model.dart';
import 'package:achno/services/notification_service.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'dart:async';

class NotificationController extends ChangeNotifier {
  // State variables
  bool _isLoading = true;
  final List<NotificationModel> _allNotifications = [];
  String _errorMessage = '';

  // Stream subscription for real-time updates
  Stream<List<NotificationModel>>? _notificationsStream;
  StreamSubscription<List<NotificationModel>>? _streamSubscription;

  // Animation state
  bool _isAnimating = false;

  // Notification service
  final NotificationService _notificationService = NotificationService();

  // Getters
  bool get isLoading => _isLoading;
  List<NotificationModel> get allNotifications => _allNotifications;
  String get errorMessage => _errorMessage;
  bool get isAnimating => _isAnimating;
  Stream<List<NotificationModel>>? get notificationsStream =>
      _notificationsStream;
  String? get currentUserId => _notificationService.currentUserId;

  // Initialize controller
  Future<void> initialize() async {
    await _setupNotificationsStream();
    await _fetchInitialNotifications();
  }

  // Setup notifications stream
  Future<void> _setupNotificationsStream() async {
    try {
      _notificationsStream = _notificationService.getNotificationsStream();
      _streamSubscription = _notificationsStream!.listen(
        (notifications) {
          _allNotifications.clear();
          _allNotifications.addAll(notifications);
          _isLoading = false;
          _errorMessage = '';
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Notification stream error: $error');
          _errorMessage =
              'Failed to load notifications. This might be due to Firestore permissions. Please check your Firebase configuration.';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error setting up notification stream: $e');
      _errorMessage = 'Failed to setup notifications stream: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch initial notifications
  Future<void> _fetchInitialNotifications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Check if user is authenticated
      if (currentUserId == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final notifications =
          await _notificationService.getNotificationsStream().first;
      _allNotifications.clear();
      _allNotifications.addAll(notifications);
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _errorMessage =
          'Failed to load notifications. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    return _fetchInitialNotifications();
  }

  // Send test notification
  Future<void> sendTestNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    try {
      // Show loading indicator
      _showSnackBar(context, l10n.sendingTestNotification,
          duration: const Duration(seconds: 1));

      // Create a test notification in Firestore
      if (currentUserId != null) {
        await _notificationService.sendNotificationToUser(
          userId: currentUserId!,
          title: 'Test Notification',
          message:
              'This is a test notification to verify the system is working.',
          type: NotificationType.system,
          senderName: 'System',
          senderId: 'system',
        );
      }

      // Show success message
      if (context.mounted) {
        _showSnackBar(context, l10n.testNotificationSent,
            backgroundColor: Colors.green);
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      if (context.mounted) {
        _showSnackBar(context, '${l10n.failedToSendTestNotification}: $e',
            backgroundColor: Colors.red);
      }
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      final index = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _allNotifications[index] =
            _allNotifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to mark notification as read: $e';
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();

      for (int i = 0; i < _allNotifications.length; i++) {
        if (!_allNotifications[i].isRead) {
          _allNotifications[i] = _allNotifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark all notifications as read: $e';
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _allNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete notification: $e';
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      // _notificationService.deleteAllNotifications(); // TEMPORARILY DISABLED
      _allNotifications.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear all notifications: $e';
      notifyListeners();
    }
  }

  // Handle notification tap
  void handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Mark as read
    markNotificationAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat with this sender
        // if (notification.relatedItemId != null) {
        //   GoRouter.of(context).push(
        //     '/chat/${notification.relatedItemId}',
        //     extra: {
        //       'contactName': notification.senderName,
        //       'contactAvatar': notification.senderAvatar,
        //       'contactId': notification.senderId,
        //     },
        //   );
        // }
        break;
      case NotificationType.like:
      case NotificationType.comment:
        // Navigate to the post that was liked/commented on
        // if (notification.relatedItemId != null) {
        //   GoRouter.of(context).push('/post/${notification.relatedItemId}');
        // }
        break;
      case NotificationType.follow:
        // Navigate to follower's profile
        // if (notification.senderId != null) {
        //   GoRouter.of(context).push('/profile/${notification.senderId}');
        // }
        break;
      case NotificationType.mention:
        // Navigate to the comment where user was mentioned
        // if (notification.relatedItemId != null) {
        //   GoRouter.of(context).push('/post/${notification.relatedItemId}');
        // }
        break;
      case NotificationType.system:
        // Show full system message
        _showSystemNotificationDetails(context, notification);
        break;
    }
  }

  // Show system notification details
  void _showSystemNotificationDetails(
      BuildContext context, NotificationModel notification) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  // Show snackbar
  void _showSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    Color? backgroundColor,
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: duration ?? const Duration(seconds: 4),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  // Set error message
  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error message
  void clearErrorMessage() {
    _errorMessage = '';
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set animation state
  void setAnimating(bool animating) {
    _isAnimating = animating;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
