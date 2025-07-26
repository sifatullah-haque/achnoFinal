import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/scheduler.dart';

class ProfileController extends ChangeNotifier {
  bool _isLoading = true;
  bool _isCurrentUser = false;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReviews = [];
  bool _isFollowing = false;
  double _userRating = 0;
  int _currentTabIndex = 0;

  // Audio player variables
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String _currentlyPlayingId = '';
  bool _isPlaying = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCurrentUser => _isCurrentUser;
  Map<String, dynamic> get userData => _userData;
  List<Map<String, dynamic>> get userPosts => _userPosts;
  List<Map<String, dynamic>> get userReviews => _userReviews;
  bool get isFollowing => _isFollowing;
  double get userRating => _userRating;
  int get currentTabIndex => _currentTabIndex;
  bool get isPlaying => _isPlaying;
  String get currentlyPlayingId => _currentlyPlayingId;

  @override
  void dispose() {
    _stopAudio();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> initialize(String? userId, BuildContext context) async {
    await _initAudioPlayer();
    await loadUserData(userId, context);
    await loadUserReviews(userId, context);
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.openPlayer();
      await _audioPlayer
          .setSubscriptionDuration(const Duration(milliseconds: 100));

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
      ));
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> loadUserData(String? userId, BuildContext context) async {
    _setLoading(true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      final targetUserId = userId ?? currentUserId;

      if (targetUserId == null) {
        throw Exception('No user logged in and no userId provided');
      }

      _isCurrentUser = targetUserId == currentUserId;

      // Get user data with explicit field retrieval
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Count reviews directly from Firestore for accurate count
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: targetUserId)
          .get();

      final reviewsCount = reviewsQuery.docs.length;

      // Count posts directly from Firestore for accurate count
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: targetUserId)
          .get();

      final actualPostsCount = postsQuery.docs.length;

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviewsQuery.docs) {
        final rating = doc.data()['rating'];
        if (rating != null) {
          totalRating += rating;
        }
      }

      final averageRating = reviewsCount > 0 ? totalRating / reviewsCount : 0.0;

      // Extract all necessary fields with proper type checking
      final data = userDoc.data() as Map<String, dynamic>;
      _userData = {
        'id': targetUserId,
        'name': data['firstName'] != null && data['lastName'] != null
            ? '${data['firstName']} ${data['lastName']}'
            : data['name'] ?? 'User',
        'username': data['username'] ?? '@username',
        'bio': data['bio'] ?? '',
        'activity': data['activity'] ?? '',
        'location': data['city'] ?? '',
        'profilePicture': data['profilePicture'],
        'postsCount': actualPostsCount,
        'followersCount': data['followersCount'] ?? 0,
        'followingCount': data['followingCount'] ?? 0,
        'isProfessional': data['isProfessional'] ?? false,
        'audioBioUrl': data['audioBioUrl'],
        'rating': averageRating,
        'reviewsCount': reviewsCount,
        'isAdmin': data['isAdmin'] ?? false,
      };

      // Update the user's postsCount in Firestore if it's different
      if (data['postsCount'] != actualPostsCount) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
          'postsCount': actualPostsCount,
        });
      }

      _userRating = averageRating;

      // Debug the profile picture URL
      debugPrint('Profile Picture URL: ${_userData['profilePicture']}');
      debugPrint('Audio Bio URL: ${_userData['audioBioUrl']}');
      debugPrint('Posts Count: $actualPostsCount');

      // Check if current user is following this user
      if (!_isCurrentUser && currentUserId != null) {
        final followDoc = await FirebaseFirestore.instance
            .collection('follows')
            .doc('${currentUserId}_$targetUserId')
            .get();

        _isFollowing = followDoc.exists;
      }

      // Load user posts
      final postsQueryForDisplay = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _userPosts = postsQueryForDisplay.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _showError(context, 'Error loading profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserReviews(String? userId, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      final targetUserId = userId ?? currentUserId;

      if (targetUserId == null) return;

      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _userReviews = reviewsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      _showError(context, 'Error loading reviews: ${e.toString()}');
    }
  }

  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> toggleFollow(BuildContext context) async {
    if (_isCurrentUser) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      final targetUserId = _userData['id'];

      if (currentUserId == null || targetUserId == null) return;

      final followDocRef = FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUserId}_$targetUserId');

      if (_isFollowing) {
        // Unfollow
        await followDocRef.delete();

        // Update follower count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
          'followersCount': FieldValue.increment(-1),
        });

        // Update following count for current user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'followingCount': FieldValue.increment(-1),
        });

        _isFollowing = false;
        _userData['followersCount'] = (_userData['followersCount'] ?? 0) - 1;
      } else {
        // Follow
        await followDocRef.set({
          'followerId': currentUserId,
          'followingId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update follower count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
          'followersCount': FieldValue.increment(1),
        });

        // Update following count for current user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'followingCount': FieldValue.increment(1),
        });

        _isFollowing = true;
        _userData['followersCount'] = (_userData['followersCount'] ?? 0) + 1;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      _showError(context, 'Error updating follow status: ${e.toString()}');
    }
  }

  Future<void> playAudioBio(String audioUrl) async {
    if (_isPlaying) {
      await _stopAudio();
      if (_currentlyPlayingId == 'audio_bio') {
        return;
      }
    }

    try {
      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isPlaying = false;
          _currentlyPlayingId = '';
          notifyListeners();
        },
      );

      _isPlaying = true;
      _currentlyPlayingId = 'audio_bio';
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio bio: $e');
    }
  }

  Future<void> playAudio(String audioUrl, String postId) async {
    if (_currentlyPlayingId == postId && _isPlaying) {
      await _stopAudio();
      return;
    }

    if (_isPlaying) {
      await _stopAudio();
    }

    try {
      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isPlaying = false;
          _currentlyPlayingId = '';
          notifyListeners();
        },
      );

      _isPlaying = true;
      _currentlyPlayingId = postId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stopPlayer();
      _isPlaying = false;
      _currentlyPlayingId = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _showError(BuildContext context, String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1d ago' : '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1h ago' : '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1m ago'
          : '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
