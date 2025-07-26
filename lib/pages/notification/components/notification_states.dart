import 'package:flutter/material.dart';
import 'package:achno/models/notification_model.dart';

// Base state class
abstract class NotificationState {
  const NotificationState();
}

// Initial state
class NotificationInitialState extends NotificationState {
  const NotificationInitialState();
}

// Loading state
class NotificationLoadingState extends NotificationState {
  const NotificationLoadingState();
}

// Loaded state with notifications
class NotificationLoadedState extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasUnreadNotifications;

  const NotificationLoadedState({
    required this.notifications,
    required this.hasUnreadNotifications,
  });
}

// Empty state
class NotificationEmptyState extends NotificationState {
  const NotificationEmptyState();
}

// Error state
class NotificationErrorState extends NotificationState {
  final String message;
  final VoidCallback? onRetry;

  const NotificationErrorState({
    required this.message,
    this.onRetry,
  });
}

// Refreshing state
class NotificationRefreshingState extends NotificationState {
  final List<NotificationModel> currentNotifications;

  const NotificationRefreshingState({
    required this.currentNotifications,
  });
}

// Action states
class NotificationMarkingAsReadState extends NotificationState {
  final String notificationId;
  final List<NotificationModel> notifications;

  const NotificationMarkingAsReadState({
    required this.notificationId,
    required this.notifications,
  });
}

class NotificationMarkingAllAsReadState extends NotificationState {
  final List<NotificationModel> notifications;

  const NotificationMarkingAllAsReadState({
    required this.notifications,
  });
}

class NotificationDeletingState extends NotificationState {
  final String notificationId;
  final List<NotificationModel> notifications;

  const NotificationDeletingState({
    required this.notificationId,
    required this.notifications,
  });
}

class NotificationClearingAllState extends NotificationState {
  final List<NotificationModel> notifications;

  const NotificationClearingAllState({
    required this.notifications,
  });
}

// Test notification states
class NotificationSendingTestState extends NotificationState {
  const NotificationSendingTestState();
}

class NotificationTestSentState extends NotificationState {
  const NotificationTestSentState();
}

class NotificationTestErrorState extends NotificationState {
  final String error;

  const NotificationTestErrorState({
    required this.error,
  });
}
