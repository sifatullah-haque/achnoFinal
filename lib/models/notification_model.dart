import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String? message;
  final String senderName;
  final String? senderAvatar;
  final String? senderId; // Added this field
  final DateTime time;
  final NotificationType type;
  final String? relatedItemId;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    this.message,
    required this.senderName,
    this.senderAvatar,
    this.senderId, // Added as optional parameter
    required this.time,
    required this.type,
    this.relatedItemId,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? senderName,
    String? senderAvatar,
    String? senderId, // Added to copyWith
    DateTime? time,
    NotificationType? type,
    String? relatedItemId,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderId: senderId ?? this.senderId, // Added to constructor
      time: time ?? this.time,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'senderId': senderId, // Added to map
      'time': time.toIso8601String(),
      'type': type.index,
      'relatedItemId': relatedItemId,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      senderId: json['senderId'], // Added to factory constructor
      time: DateTime.parse(json['time']),
      type: NotificationType.values[json['type']],
      relatedItemId: json['relatedItemId'],
      isRead: json['isRead'] ?? false,
    );
  }
}

enum NotificationType {
  message,
  like,
  comment,
  follow,
  mention,
  system,
}

extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment_outlined;
      case NotificationType.follow:
        return Icons.person_add_outlined;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.message:
        return 'Message';
      case NotificationType.like:
        return 'Like';
      case NotificationType.comment:
        return 'Comment';
      case NotificationType.follow:
        return 'Follow';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.system:
        return 'System';
    }
  }
}
