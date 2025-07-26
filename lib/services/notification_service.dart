import 'package:achno/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Temporarily commented out
import 'dart:convert';
import 'package:achno/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Add this import
import 'package:achno/providers/notification_provider.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin(); // Temporarily commented out

  // Streams for real-time notifications
  Stream<List<NotificationModel>>? _notificationsStream;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Get notifications stream
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_notificationsStream == null && currentUserId != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .orderBy('time', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return NotificationModel(
            id: doc.id,
            title: data['title'] ?? '',
            message: data['message'],
            senderName: data['senderName'] ?? '',
            senderAvatar: data['senderAvatar'],
            senderId: data['senderId'],
            time: (data['time'] as Timestamp).toDate(),
            type: NotificationType.values[data['type'] ?? 0],
            relatedItemId: data['relatedItemId'],
            isRead: data['isRead'] ?? false,
          );
        }).toList();
      });
    }
    return _notificationsStream ?? Stream.value([]);
  }

  Future<void> init() async {
    try {
      // Ensure navigator key is initialized
      if (navigatorKey.currentState == null) {
        navigatorKey = GlobalKey<NavigatorState>();
      }

      // Configure Firebase Messaging
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token and save it to the user profile in your backend
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Initialize local notifications - TEMPORARILY DISABLED
      // const AndroidInitializationSettings androidInitializationSettings =
      //     AndroidInitializationSettings('@mipmap/ic_launcher');

      // const DarwinInitializationSettings iosInitializationSettings =
      //     DarwinInitializationSettings(
      //   requestAlertPermission: true,
      //   requestBadgePermission: true,
      //   requestSoundPermission: true,
      // );

      // const InitializationSettings initializationSettings =
      //     InitializationSettings(
      //   android: androidInitializationSettings,
      //   iOS: iosInitializationSettings,
      // );

      // await _flutterLocalNotificationsPlugin.initialize(
      //   initializationSettings,
      //   onDidReceiveNotificationResponse: _onNotificationTapped,
      // );

      // Set up foreground handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up background handlers
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Check if app was opened from a terminated state via notification
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage);
      }

      // Setup notification channels for Android - TEMPORARILY DISABLED
      // await _setupNotificationChannels();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }

  // Future<void> _setupNotificationChannels() async {
  //   // For Android 8.0+ - TEMPORARILY DISABLED
  //   // const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //   //   'high_importance_channel',
  //   //   'High Importance Notifications',
  //   //   description: 'This channel is used for important notifications.',
  //   //   importance: Importance.high,
  //   // );

  //   // await _flutterLocalNotificationsPlugin
  //   //     .resolvePlatformSpecificImplementation<
  //   //         AndroidFlutterLocalNotificationsPlugin>()
  //   //     ?.createNotificationChannel(channel);

  //   // You can create additional channels here for different notification types
  // }

  // void _onNotificationTapped(NotificationResponse response) {
  //   try {
  //     // Handle notification tap - TEMPORARILY DISABLED
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error handling notification tap: $e');
  //     }
  //   }
  // }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    }

    // Show a simple debug message instead of local notification
    if (kDebugMode) {
      print(
          'Foreground notification: ${message.notification?.title} - ${message.notification?.body}');
    }

    // You can add a simple in-app notification here if needed
  }

  void _handleNotificationOpen(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification opened: ${message.data}');
    }

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      final itemId = data['itemId'];

      if (navigatorKey.currentState != null) {
        switch (type) {
          case 'post':
            if (itemId != null) {
              navigatorKey.currentState!.pushNamed('/post/$itemId');
            }
            break;
          case 'profile':
            if (itemId != null) {
              navigatorKey.currentState!.pushNamed('/profile/$itemId');
            }
            break;
          case 'chat':
            if (itemId != null) {
              navigatorKey.currentState!.pushNamed('/chat/$itemId');
            }
            break;
          default:
            // Navigate to notifications page
            navigatorKey.currentState!.pushNamed('/notifications');
            break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification navigation: $e');
      }
    }
  }

  // Static method to initialize FCM
  static Future<void> initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get token
      final token = await messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Save token to user profile if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  // Method to send notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedItemId,
    String? senderName,
    String? senderAvatar,
    String? senderId,
  }) async {
    try {
      final notification = {
        'title': title,
        'message': message,
        'type': type.index,
        'relatedItemId': relatedItemId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'senderId': senderId,
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      if (kDebugMode) {
        print('Notification sent to user $userId: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  // Method to mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = currentUserId;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Method to mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final userId = currentUserId;
      if (userId != null) {
        final batch = FirebaseFirestore.instance.batch();
        final notifications = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();

        for (final doc in notifications.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  // Method to delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = currentUserId;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Method to get unread notification count
  Stream<int> getUnreadNotificationCount() {
    final userId = currentUserId;
    if (userId != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    }
    return Stream.value(0);
  }
}

// Global navigator key for notification navigation
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
