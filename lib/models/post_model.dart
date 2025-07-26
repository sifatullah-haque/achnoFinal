import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { request, offer }

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime createdAt;
  final PostType type;
  final String city;
  final double? latitude;
  final double? longitude;
  final String activity;
  final String? audioUrl;
  final int? audioDuration;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String? duration;
  final int likes;
  final bool isLiked;
  final bool isProfessional;
  final double? rating;
  final int? reviewCount;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.city,
    this.latitude,
    this.longitude,
    required this.activity,
    this.audioUrl,
    this.audioDuration,
    this.imageUrl,
    this.expiryDate,
    this.duration,
    required this.likes,
    required this.isLiked,
    this.isProfessional = false,
    this.rating,
    this.reviewCount,
  });

  // Factory method to create a Post from a Map (for Firestore integration)
  factory Post.fromMap(Map<String, dynamic> data, String id, {bool isLiked = false}) {
    return Post(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? data['profilePicture'],  // Try both userAvatar and profilePicture fields
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 (data['timestamp'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      type: data['type'] == 'request' ? PostType.request : PostType.offer,
      city: data['city'] ?? '',
      latitude: data['latitude'],
      longitude: data['longitude'],
      activity: data['activity'] ?? '',
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      imageUrl: data['imageUrl'],
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      duration: data['duration'],
      likes: data['likes'] ?? 0,
      isLiked: isLiked,
      isProfessional: data['isProfessional'] ?? false,
      rating: (data['rating'] is int) ? (data['rating'] as int).toDouble() : data['rating'],
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  // Factory method to create a Post from Firestore data
  factory Post.fromFirestore(
    Map<String, dynamic> data, 
    String id, 
    bool isLiked, 
    {String? userAvatar, 
    bool isProfessional = false,
    double? rating,
    int? reviewCount}
  ) {
    return Post(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: userAvatar ?? data['userAvatar'] ?? data['profilePicture'], // Try all possible fields
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 (data['timestamp'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      type: data['type'] == 'request' ? PostType.request : PostType.offer,
      city: data['city'] ?? '',
      latitude: data['latitude'],
      longitude: data['longitude'],
      activity: data['activity'] ?? '',
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      imageUrl: data['imageUrl'],
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      duration: data['duration'],
      likes: data['likes'] ?? 0,
      isLiked: isLiked,
      isProfessional: isProfessional,
      rating: rating ?? ((data['rating'] is int) ? (data['rating'] as int).toDouble() : (data['rating'] as double?)),
      reviewCount: reviewCount ?? data['reviewCount'],
    );
  }

  // Create a copy of this post with some fields changed
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? message,
    DateTime? createdAt,
    PostType? type,
    String? city,
    double? latitude,
    double? longitude,
    String? activity,
    String? audioUrl,
    int? audioDuration,
    String? imageUrl,
    DateTime? expiryDate,
    String? duration,
    int? likes,
    bool? isLiked,
    bool? isProfessional,
    double? rating,
    int? reviewCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      activity: activity ?? this.activity,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      duration: duration ?? this.duration,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isProfessional: isProfessional ?? this.isProfessional,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
