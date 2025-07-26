import 'package:achno/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:achno/services/notification_service.dart';
import 'package:achno/models/notification_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  Future<List<Post>> fetchPosts() async {
    try {
      // Get current user's ID to check liked posts
      final userId = _auth.currentUser?.uid;

      // Get all posts, sorted by timestamp
      final postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      // Fetch current user's liked posts if user is logged in
      Set<String> likedPostIds = {};
      if (userId != null) {
        final likedPostsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('likedPosts')
            .get();

        likedPostIds = likedPostsSnapshot.docs.map((doc) => doc.id).toSet();
      }

      // Convert each document to a Post object
      final posts = await Future.wait(
        postsSnapshot.docs.map((doc) async {
          final data = doc.data();
          final posterId = data['userId'];

          // Get user information for each post
          String userName = 'Unknown User';
          String? userAvatar;

          try {
            final userDoc =
                await _firestore.collection('users').doc(posterId).get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              userName =
                  '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}';
              userAvatar = userData?['avatarUrl'];
            }
          } catch (e) {
            debugPrint('Error fetching user data: $e');
          }

          // Create post with user data
          return Post.fromMap(
            {
              ...data,
              'userName': userName,
              'userAvatar': userAvatar,
            },
            doc.id,
            isLiked: likedPostIds.contains(doc.id),
          );
        }),
      );

      return posts;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      throw Exception('Failed to load posts');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final postRef = _firestore.collection('posts').doc(postId);

      // Add post to user's liked posts
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedPosts')
          .doc(postId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment post's like counter
      await postRef.update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error liking post: $e');
      throw Exception('Failed to like post');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final postRef = _firestore.collection('posts').doc(postId);

      // Remove post from user's liked posts
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedPosts')
          .doc(postId)
          .delete();

      // Decrement post's like counter
      await postRef.update({
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error unliking post: $e');
      throw Exception('Failed to unlike post');
    }
  }

  Future<void> sharePost(String postId) async {
    try {
      // Update share count
      await _firestore.collection('posts').doc(postId).update({
        'shares': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sharing post: $e');
      throw Exception('Failed to share post');
    }
  }

  Future<void> createPost({
    required String message,
    required PostType type,
    String? audioUrl,
    String? imageUrl,
    String? city,
    String? activity,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore.collection('posts').add({
        'userId': userId,
        'message': message,
        'type': type == PostType.offer ? 'offer' : 'request',
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'city': city,
        'activity': activity,
        'likes': 0,
        'responses': 0,
        'shares': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post');
    }
  }

  Future<void> updatePostLike(String postId, bool isLiked) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get post data to verify it's not the user's own post
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postData = postDoc.data();

      if (postData == null) {
        throw Exception('Post not found');
      }

      // Check if the user is trying to like their own post
      if (postData['userId'] == _currentUserId) {
        throw Exception('You cannot like your own post');
      }

      final postRef = _firestore.collection('posts').doc(postId);
      final userLikesRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likes')
          .doc(postId);

      // Check if the user already liked this post (for the unlike action)
      final userLikeDoc = await userLikesRef.get();
      final hasLiked = userLikeDoc.exists;

      // If trying to like when already liked or unlike when already unliked, return
      if ((isLiked && hasLiked) || (!isLiked && !hasLiked)) {
        return;
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Update the likes count on the post
      if (isLiked) {
        batch.update(postRef, {'likes': FieldValue.increment(1)});
        batch.set(userLikesRef, {'likedAt': FieldValue.serverTimestamp()});
      } else {
        // Ensure likes never go below zero
        final currentLikes = postData['likes'] ?? 0;
        if (currentLikes > 0) {
          batch.update(postRef, {'likes': FieldValue.increment(-1)});
        } else {
          batch.update(postRef, {'likes': 0});
        }
        batch.delete(userLikesRef);
      }

      // Commit the batch
      await batch.commit();

      // If the user liked the post, create a notification for the post owner
      if (isLiked) {
        if (postData['userId'] != _currentUserId) {
          // Get current user data for the notification
          final currentUserDoc =
              await _firestore.collection('users').doc(_currentUserId).get();
          final currentUserData = currentUserDoc.data();

          if (currentUserData != null) {
            await _notificationService.sendNotificationToUser(
              userId: postData['userId'],
              title: 'New Like',
              message:
                  '${currentUserData['displayName'] ?? 'Someone'} liked your post',
              type: NotificationType.like,
              relatedItemId: postId,
              senderName: currentUserData['displayName'] ?? 'User',
              senderAvatar: currentUserData['photoURL'],
              senderId: _currentUserId!,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating post like: $e');
      }
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  // Rename the first getPosts method to fetchBasicPosts to avoid duplicate method name
  Future<List<Post>> fetchBasicPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      List<Post> posts = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get user profile information
        String userId = data['userId'] ?? '';
        if (userId.isNotEmpty) {
          try {
            DocumentSnapshot userDoc =
                await _firestore.collection('users').doc(userId).get();

            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;

              // Update the post data with user profile info
              data['userName'] =
                  userData['firstName'] != null && userData['lastName'] != null
                      ? '${userData['firstName']} ${userData['lastName']}'
                      : userData['name'] ?? 'User';
              data['profilePicture'] = userData['profilePicture'];

              debugPrint(
                  'Found profile picture for user $userId: ${userData['profilePicture']}');
            }
          } catch (e) {
            debugPrint('Error fetching user data for post: $e');
          }
        }

        // Fixed: Pass data map from the document to fromFirestore
        final post =
            Post.fromFirestore(data, doc.id, false // Default isLiked value
                );
        posts.add(post);
      }

      return posts;
    } catch (e) {
      debugPrint('Error getting posts: $e');
      throw Exception('Failed to load posts: $e');
    }
  }

  // Check if user has liked a post - helper method
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      if (_currentUserId == null) return false;

      final likeDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('likes')
          .doc(postId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if post is liked: $e');
      return false;
    }
  }

  // Improved method to get the current user's city with better logging
  Future<String?> getCurrentUserCity() async {
    try {
      if (_currentUserId == null) {
        debugPrint('Cannot get user city - user not authenticated');
        return null;
      }

      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final city = userData?['city'] as String?;
        debugPrint('Found user city in Firestore: $city');
        return city;
      } else {
        debugPrint('User document not found for ID: $_currentUserId');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user city: $e');
      return null;
    }
  }

  // Renamed this method to getFilteredPosts to avoid duplication
  Future<List<Post>> getFilteredPosts(
      {String? filterCity, String? filterActivity}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Get posts ordered by creation date
      var query =
          _firestore.collection('posts').orderBy('createdAt', descending: true);

      // Only include approved posts
      query = query.where('approvalStatus', isEqualTo: 'approved');

      // Apply filters if provided - ONLY if they are explicitly provided
      if (filterCity != null && filterCity.isNotEmpty) {
        query = query.where('city', isEqualTo: filterCity);
      }

      if (filterActivity != null && filterActivity.isNotEmpty) {
        query = query.where('activity', isEqualTo: filterActivity);
      }

      // Increase limit to show more posts initially
      final postsSnapshot = await query.limit(50).get();

      // Fetch user likes data
      final userLikesSnapshot = await _firestore
          .collection('userLikes')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Create a map of post IDs to liked status for quick lookup
      final Map<String, bool> userLikes = {};
      for (var doc in userLikesSnapshot.docs) {
        final data = doc.data();
        if (data['postId'] != null) {
          userLikes[data['postId'] as String] = true;
        }
      }

      // Process each post document and enhance with user data
      final postsWithUserData = await Future.wait(
        postsSnapshot.docs.map((doc) async {
          final data = doc.data();
          final userId = data['userId'] ?? '';

          // Check if this post is liked by the current user
          final isLiked = userLikes[doc.id] ?? false;

          // Fetch additional user information for this post
          Map<String, dynamic> userData = {};
          if (userId.isNotEmpty) {
            try {
              final userDoc =
                  await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                userData = userDoc.data() ?? {};
              }
            } catch (e) {
              debugPrint('Error fetching user data for post ${doc.id}: $e');
            }
          }

          // Get the user's profile picture
          final userAvatar = userData['profilePicture'];
          final isProfessional = userData['isProfessional'] ?? false;

          // Get the user's rating information
          double rating = 0.0;
          int reviewCount = 0;

          try {
            // Get reviews for this user to calculate accurate rating
            final reviewsQuery = await _firestore
                .collection('reviews')
                .where('targetUserId', isEqualTo: userId)
                .get();

            reviewCount = reviewsQuery.docs.length;

            if (reviewCount > 0) {
              double totalRating = 0;
              for (var review in reviewsQuery.docs) {
                final reviewRating = review.data()['rating'];
                if (reviewRating != null) {
                  totalRating += reviewRating;
                }
              }
              rating = totalRating / reviewCount;
            }
          } catch (e) {
            debugPrint('Error calculating rating for user $userId: $e');
          }

          // Create enhanced Post object with additional user data
          return Post.fromFirestore(
            data,
            doc.id,
            isLiked,
            userAvatar: userAvatar,
            isProfessional: isProfessional,
            rating: rating,
            reviewCount: reviewCount,
          );
        }),
      );

      return postsWithUserData;
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  // Keep this method as the main getPosts method that only returns approved posts
  Future<List<Post>> getPosts() async {
    try {
      // Modified query to only get approved posts
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('approvalStatus',
              isEqualTo: 'approved') // Only get approved posts
          .orderBy('createdAt', descending: true)
          .get();

      // Process each post document and enhance with user data
      final postsWithUserData = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>; // Fixed cast
          final userId = data['userId'] ?? '';

          // Check if this post is liked by the current user
          final isLiked = await hasUserLikedPost(doc.id);

          // Fetch additional user information for this post
          Map<String, dynamic> userData = {};
          if (userId.isNotEmpty) {
            try {
              final userDoc =
                  await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                userData = userDoc.data() ?? {};
              }
            } catch (e) {
              debugPrint('Error fetching user data for post ${doc.id}: $e');
            }
          }

          // Get the user's profile picture
          final userAvatar = userData['profilePicture'];
          final isProfessional = userData['isProfessional'] ?? false;

          // Get the user's rating information
          double rating = 0.0;
          int reviewCount = 0;

          try {
            // Get reviews for this user to calculate accurate rating
            final reviewsQuery = await _firestore
                .collection('reviews')
                .where('targetUserId', isEqualTo: userId)
                .get();

            reviewCount = reviewsQuery.docs.length;

            if (reviewCount > 0) {
              double totalRating = 0;
              for (var review in reviewsQuery.docs) {
                final reviewData = review.data();
                final reviewRating = reviewData['rating'];
                if (reviewRating != null) {
                  totalRating += (reviewRating as num).toDouble();
                }
              }
              rating = totalRating / reviewCount;
            }
          } catch (e) {
            debugPrint('Error calculating rating for user $userId: $e');
          }

          // Create enhanced Post object with additional user data
          return Post.fromFirestore(
            data,
            doc.id,
            isLiked,
            userAvatar: userAvatar,
            isProfessional: isProfessional,
            rating: rating,
            reviewCount: reviewCount,
          );
        }),
      );

      return postsWithUserData;
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  // Add method to handle post approval and send notifications
  static Future<void> handlePostApproval(String postId) async {
    try {
      // Get the post details
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;

        // Create an instance of NotificationService to call the instance method
        final notificationService = NotificationService();

        // Send notifications to relevant professionals - TEMPORARILY DISABLED
        // await notificationService.notifyProfessionalsForNewPost(
        //   postId: postId,
        //   postCity: postData['city'] ?? '',
        //   postActivity: postData['activity'] ?? '',
        //   clientName: postData['userName'] ?? 'Someone',
        //   postType: postData['type'] ?? 'request',
        // );

        debugPrint('Notifications sent for approved post: $postId');
      }
    } catch (e) {
      debugPrint('Error handling post approval: $e');
    }
  }
}
