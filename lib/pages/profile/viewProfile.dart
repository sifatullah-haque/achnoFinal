import 'package:achno/config/theme.dart';
import 'package:achno/widgets/directionality_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:flutter/scheduler.dart';
import '../../providers/auth_provider.dart';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
// Added imports for recording functionality
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:achno/utils/activity_icon_helper.dart'; // Add this import

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverAppBarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class ViewProfile extends StatefulWidget {
  final String userId;

  const ViewProfile({super.key, required this.userId});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isLoadingAction = false;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReviews = [];
  double _userRating = 0;

  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Audio player variables
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String _currentlyPlayingId = '';
  bool _isPlaying = false;

  // Review input variables
  final TextEditingController _reviewController = TextEditingController();
  double _reviewRating = 5.0;
  bool _isSubmittingReview = false;

  // Review audio recording variables
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _recorderInitialized = false;
  String? _recordedReviewPath;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  bool _isPlayingReview = false;
  final List<double> _reviewAudioWaveform = [];
  final int _maxWaveformPoints = 30;
  PermissionStatus _micPermissionStatus = PermissionStatus.denied;
  bool _isReviewTypeAudio =
      true; // To track if the current review is audio or text

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isScrolledUnderAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initAudioPlayer();
    _initAudioRecorder();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadUserData();
    _loadUserReviews();
  }

  // Initialize audio recorder for reviews
  Future<void> _initAudioRecorder() async {
    try {
      final status = await Permission.microphone.request();
      setState(() {
        _micPermissionStatus = status;
      });

      if (status != PermissionStatus.granted) {
        return;
      }

      await _audioRecorder.openRecorder();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
      ));

      setState(() {
        _recorderInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  // Start recording a review
  Future<void> _startRecordingReview() async {
    if (!_recorderInitialized) {
      await _requestMicrophonePermission();
      if (!_recorderInitialized) return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/review_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Set up audio level subscription for visualization
      _reviewAudioWaveform.clear();
      _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      _audioRecorder.onProgress!.listen((event) {
        double level = event.decibels ?? -160.0;
        level = (level + 160) / 160; // Normalize between 0 and 1

        setState(() {
          if (_reviewAudioWaveform.length >= _maxWaveformPoints) {
            _reviewAudioWaveform.removeAt(0);
          }
          _reviewAudioWaveform.add(level.clamp(0.05, 1.0));
        });
      });

      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _recordedReviewPath = filePath;
        _isReviewTypeAudio = true;
      });

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;

          // Auto-stop after 60 seconds
          if (_recordingDuration >= 60) {
            _stopRecordingReview();
          }
        });
      });
    } catch (e) {
      debugPrint('Error starting review recording: $e');
    }
  }

  // Stop recording a review
  Future<void> _stopRecordingReview() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stopRecorder();

      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping review recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Play recorded review audio
  Future<void> _playRecordedReview() async {
    if (_recordedReviewPath == null || _isPlayingReview) return;

    try {
      await _audioPlayer.stopPlayer();

      await _audioPlayer.startPlayer(
        fromURI: _recordedReviewPath!,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlayingReview = false;
          });
        },
      );

      setState(() {
        _isPlayingReview = true;
        _currentlyPlayingId = 'review_recording';
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error playing review recording: $e');
      setState(() {
        _isPlayingReview = false;
      });
    }
  }

  // Stop playing recorded review
  Future<void> _stopPlayingReview() async {
    if (!_isPlayingReview) return;

    try {
      await _audioPlayer.stopPlayer();

      setState(() {
        _isPlayingReview = false;
        _isPlaying = false;
        _currentlyPlayingId = '';
      });
    } catch (e) {
      debugPrint('Error stopping review playback: $e');
    }
  }

  // Delete recorded review
  void _deleteRecordedReview() {
    if (_recordedReviewPath != null) {
      try {
        final file = File(_recordedReviewPath!);
        file.delete();
      } catch (e) {
        debugPrint('Error deleting recorded review: $e');
      }

      setState(() {
        _recordedReviewPath = null;
        _recordingDuration = 0;
        _isReviewTypeAudio = false;
      });
    }
  }

  // Request microphone permission
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _micPermissionStatus = status;
    });

    if (status.isGranted) {
      await _initAudioRecorder();
    }
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

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _scrollOffset = offset;
      _isScrolledUnderAppBar = offset > 180.h;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stopAudio();
    _audioPlayer.closePlayer();
    _reviewController.dispose();

    // Clean up recorder resources
    _recordingTimer?.cancel();
    if (_isRecording) {
      _stopRecordingReview();
    }
    _audioRecorder.closeRecorder();

    super.dispose();
  }

  Future<void> _playAudioBio(String audioUrl) async {
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
          setState(() {
            _isPlaying = false;
            _currentlyPlayingId = '';
          });
        },
      );

      setState(() {
        _isPlaying = true;
        _currentlyPlayingId = 'audio_bio';
      });
    } catch (e) {
      debugPrint('Error playing audio bio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio bio: ${e.toString()}')),
      );
    }
  }

  Future<void> _playAudio(String audioUrl, String postId) async {
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
          setState(() {
            _isPlaying = false;
            _currentlyPlayingId = '';
          });
        },
      );

      setState(() {
        _isPlaying = true;
        _currentlyPlayingId = postId;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: ${e.toString()}')),
      );
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = '';
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      final targetUserId = widget.userId;

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

      // ADDED: Count posts directly from Firestore for accurate count
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
        'id': targetUserId, // Ensure ID is always set
        'name': data['firstName'] != null && data['lastName'] != null
            ? '${data['firstName']} ${data['lastName']}'
            : data['name'] ?? 'User',
        'username': data['username'] ?? '@username',
        'bio': data['bio'] ?? '',
        'activity': data['activity'] ?? '',
        'location': data['city'] ?? '',
        'profilePicture': data['profilePicture'],
        'postsCount': actualPostsCount, // CHANGED: Use actual count from query
        'followersCount': data['followersCount'] ?? 0,
        'followingCount': data['followingCount'] ?? 0,
        'isProfessional': data['isProfessional'] ?? false,
        'audioBioUrl': data['audioBioUrl'],
        'rating': averageRating,
        'reviewsCount': reviewsCount,
      };

      // ADDED: Update the user's postsCount in Firestore if it's different
      if (data['postsCount'] != actualPostsCount) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
          'postsCount': actualPostsCount,
        });
      }

      setState(() {
        _userRating = averageRating;
      });

      debugPrint('Current User ID: $currentUserId');
      debugPrint('Target User ID: $targetUserId');
      debugPrint('Profile Picture URL: ${_userData['profilePicture']}');
      debugPrint('Audio Bio URL: ${_userData['audioBioUrl']}');
      debugPrint('Posts Count: $actualPostsCount'); // ADDED: Debug posts count

      if (currentUserId != null && currentUserId != targetUserId) {
        final followDoc = await FirebaseFirestore.instance
            .collection('follows')
            .doc('${currentUserId}_$targetUserId')
            .get();

        setState(() {
          _isFollowing = followDoc.exists;
        });
      }

      // Fetch posts - use the same query for display
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
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: ${e.toString()}')),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserReviews() async {
    try {
      debugPrint('Loading reviews for user: ${widget.userId}');
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${reviewsQuery.docs.length} reviews');

      final reviews = await Future.wait(
        reviewsQuery.docs.map((doc) async {
          final data = doc.data();
          data['id'] = doc.id;

          // Get reviewer information
          if (data['reviewerId'] != null) {
            try {
              final reviewerDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['reviewerId'])
                  .get();

              if (reviewerDoc.exists) {
                final reviewerData = reviewerDoc.data() as Map<String, dynamic>;
                data['reviewerName'] = reviewerData['firstName'] != null &&
                        reviewerData['lastName'] != null
                    ? '${reviewerData['firstName']} ${reviewerData['lastName']}'
                    : reviewerData['name'] ?? 'Anonymous';
                data['reviewerProfilePicture'] = reviewerData['profilePicture'];
              }
            } catch (e) {
              debugPrint('Error loading reviewer data: $e');
              data['reviewerName'] = 'Unknown User';
            }
          } else {
            data['reviewerName'] = 'Anonymous';
          }

          return data;
        }),
      );

      setState(() {
        _userReviews = reviews.toList();
      });

      debugPrint('Reviews loaded: ${_userReviews.length}');
      for (var review in _userReviews) {
        debugPrint(
            'Review: ${review['comment'] ?? "Audio review"} by ${review['reviewerName']}');
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final targetUserId = widget.userId; // Use widget.userId directly

    debugPrint(
        'Toggle follow - Current User: $currentUserId, Target User: $targetUserId');

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to follow users')),
      );
      return;
    }

    if (currentUserId == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot follow yourself')),
      );
      return;
    }

    setState(() {
      _isLoadingAction = true;
    });

    final followId = '${currentUserId}_$targetUserId';
    final followsCollection = FirebaseFirestore.instance.collection('follows');

    // Define wasFollowing outside the try block so it's accessible in catch
    final bool wasFollowing = _isFollowing;

    try {
      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (_isFollowing) {
        // Create follow relationship
        await followsCollection.doc(followId).set({
          'followerId': currentUserId,
          'followingId': targetUserId,
          'timestamp': FieldValue.serverTimestamp(),
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
      } else {
        // Remove follow relationship
        await followsCollection.doc(followId).delete();

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
      }

      // Refresh user data to get updated counts
      _loadUserData();
    } catch (e) {
      debugPrint('Error in _toggleFollow: $e');
      // Revert state if operation failed - now wasFollowing is accessible
      setState(() {
        _isFollowing = wasFollowing;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error updating follow status: ${e.toString()}')),
          );
        }
      });
    } finally {
      setState(() {
        _isLoadingAction = false;
      });
    }
  }

  Future<void> _submitReview() async {
    // Check if we have text or audio
    if (_reviewController.text.trim().isEmpty && _recordedReviewPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a review comment or record audio')),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('You must be logged in to leave a review');
      }

      // Upload audio if recorded
      String? audioUrl;
      if (_recordedReviewPath != null) {
        final file = File(_recordedReviewPath!);
        final fileName =
            'review_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('review_audio')
            .child(fileName);

        await storageRef.putFile(file);
        audioUrl = await storageRef.getDownloadURL();
      }

      // Create a new review
      await FirebaseFirestore.instance.collection('reviews').add({
        'reviewerId': currentUserId,
        'targetUserId': widget.userId,
        'rating': _reviewRating,
        'comment': _reviewController.text.trim(),
        'audioUrl': audioUrl,
        'audioDuration':
            _recordedReviewPath != null ? _recordingDuration : null,
        'isAudioReview': _recordedReviewPath != null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment the review count for the user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'reviewsCount': FieldValue.increment(1),
      });

      // Recalculate the average rating
      final allReviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: widget.userId)
          .get();

      double totalRating = 0;
      int validRatings = 0;

      for (var doc in allReviews.docs) {
        final rating = doc.data()['rating'];
        if (rating != null) {
          totalRating += rating;
          validRatings++;
        }
      }

      final newAverageRating =
          validRatings > 0 ? totalRating / validRatings : 0;

      // Update user's average rating
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'rating': newAverageRating,
      });

      // Reset the review form
      _reviewController.clear();
      _deleteRecordedReview();
      setState(() {
        _reviewRating = 4.0;
        _isReviewTypeAudio = false;
      });

      // Switch to reviews tab
      _tabController.animateTo(1); // Switch to the reviews tab after submission

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the reviews
      _loadUserReviews();
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  Future<void> _startConversation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final targetUserId = widget.userId;

    debugPrint(
        'Start conversation - Current User: $currentUserId, Target User: $targetUserId');

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send messages')),
      );
      return;
    }

    if (currentUserId == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check if conversation already exists or create new one
      String conversationId =
          await _findOrCreateConversation(currentUserId, targetUserId);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to message details
      if (mounted) {
        context.push('/chat/$conversationId', extra: {
          'contactName': _userData['name'] ?? 'User',
          'contactAvatar': _userData['profilePicture'],
          'contactId': targetUserId,
        });
      }
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show more specific error message
      String errorMessage = 'Error starting conversation';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your account settings.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Helper method to find existing conversation or create new one
  Future<String> _findOrCreateConversation(
      String currentUserId, String targetUserId) async {
    try {
      // Query conversations where current user is a participant
      final existingConversations = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Check if any conversation includes both users
      for (var doc in existingConversations.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        if (participants.contains(targetUserId)) {
          return doc.id;
        }
      }

      // No existing conversation found, create a new one
      final participants = [currentUserId, targetUserId]..sort();
      final conversationId = '${participants[0]}_${participants[1]}';

      // Create new conversation
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'unreadCount': {
          currentUserId: 0,
          targetUserId: 0,
        },
        'isActive': true,
      });

      return conversationId;
    } catch (e) {
      debugPrint('Error in _findOrCreateConversation: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: AnimatedOpacity(
          opacity: _isScrolledUnderAppBar ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.white.withOpacity(0.8),
                elevation: 0,
                title: Text(
                  _isLoading ? 'Loading...' : _userData['name'] ?? 'Profile',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: _showProfileOptions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[100]!,
              ],
            ),
          ),
        ),

        // Background pattern at the bottom of the screen
        Positioned(
          bottom: -100.h,
          right: -60.w,
          child: Container(
            height: 250.h,
            width: 250.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // Main content with proper scrolling
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Profile header as sliver
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),

            // Add review section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: _buildAddReviewSection(),
              ),
            ),

            // Tab bar as persistent header
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 50.h,
                maxHeight: 50.h,
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 3.0,
                    tabs: [
                      Tab(
                        text: 'Posts',
                        icon: Icon(Icons.post_add, size: 20.r),
                      ),
                      Tab(
                        text: 'Reviews',
                        icon: Icon(Icons.reviews, size: 20.r),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dynamic content based on selected tab
            if (_currentTabIndex == 0)
              // Posts content
              _userPosts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        child: _buildEmptyPostsView(),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: _buildPostListItem(_userPosts[index]),
                          );
                        },
                        childCount: _userPosts.length,
                      ),
                    )
            else
              // Reviews content
              _userReviews.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        child: _buildEmptyReviewsView(),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 6.h,
                            ),
                            child: _buildReviewItem(_userReviews[index]),
                          );
                        },
                        childCount: _userReviews.length,
                      ),
                    ),

            // Bottom padding
            SliverToBoxAdapter(
              child: SizedBox(height: 20.h),
            ),
          ],
        ),
      ],
    );
  }

  // Remove the separate tab building methods since they're no longer needed
  // Widget _buildPostsTab() and Widget _buildReviewsTab() can be removed

  // Add empty reviews view method
  Widget _buildEmptyReviewsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 30.h),
          Icon(
            Icons.rate_review_outlined,
            size: 64.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This user hasn\'t received any reviews yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    // Get user data with proper null checks and defaults
    final name = _userData['name'] ?? 'User';
    final username = _userData['username'] ?? '@username';
    final bio = _userData['bio'] ?? '';
    final activity = _userData['activity'] ?? '';
    final location = _userData['location'] ?? '';
    final profilePicture = _userData['profilePicture'];
    final audioBioUrl = _userData['audioBioUrl'];
    final followersCount = _userData['followersCount'] ?? 0;
    final followingCount = _userData['followingCount'] ?? 0;
    final postsCount = _userData['postsCount'] ?? 0;
    final isProfessional = _userData['isProfessional'] ?? false;

    // Use a key based on the profilePicture to force refresh when image changes
    final imageKey = profilePicture ?? DateTime.now().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background pattern at the top
        Stack(
          children: [
            // Top left circular pattern
            Positioned(
              top: -50.h,
              left: -50.w,
              child: Container(
                height: 200.h,
                width: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // Cover Image
            Container(
              height: 150.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ],
        ),

        Transform.translate(
          offset: Offset(0, -40.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and action buttons row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Profile picture
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        key: ValueKey(imageKey),
                        radius: 48.r,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profilePicture != null
                            ? NetworkImage(profilePicture)
                            : null,
                        child: profilePicture == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 40.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const Spacer(),

                    // Action buttons - Follow/Message
                    Row(
                      children: [
                        _buildActionButton(
                          icon: _isFollowing
                              ? Icons.person_remove
                              : Icons.person_add,
                          label: _isFollowing ? 'Following' : 'Follow',
                          onTap: _isLoadingAction ? null : _toggleFollow,
                          isPrimary: !_isFollowing,
                          isLoading: _isLoadingAction,
                        ),
                        SizedBox(width: 8.w),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message',
                          onTap: _startConversation,
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Name, username and professional badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isProfessional)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color:
                              ActivityIconHelper.getColorForActivity(activity)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color:
                                ActivityIconHelper.getColorForActivity(activity)
                                    .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ActivityIconHelper.getIconForActivity(activity),
                              size: 16.w,
                              color: ActivityIconHelper.getColorForActivity(
                                  activity),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Professional',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: ActivityIconHelper.getColorForActivity(
                                    activity),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 5.h),

                // Professional activity if available
                if (activity.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        ActivityIconHelper.getIconForActivity(activity),
                        size: 16.w,
                        color: ActivityIconHelper.getColorForActivity(activity),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        activity,
                        style: TextStyle(
                          color:
                              ActivityIconHelper.getColorForActivity(activity),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],

                // Location if available
                if (location.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16.w,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],

                // Bio
                if (bio.isNotEmpty || audioBioUrl != null) ...[
                  // Text Bio
                  if (bio.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        bio,
                        style: TextStyle(
                          fontSize: 14.sp,
                        ),
                      ),
                    ),

                  // Audio Bio player if available
                  if (audioBioUrl != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _playAudioBio(audioBioUrl),
                              icon: Icon(
                                _isPlaying && _currentlyPlayingId == 'audio_bio'
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 18.w,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(6.w),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          const Expanded(
                            child: Text(
                              'Voice Bio',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                SizedBox(height: 12.h),

                // Rating stars
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: _userRating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${_userRating.toStringAsFixed(1)} (${_userData['reviewsCount']})',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Stats row - followers, following, posts
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Posts', postsCount),
                      _buildDivider(),
                      _buildStatItem('Followers', followersCount),
                      _buildDivider(),
                      _buildStatItem('Following', followingCount),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Professional activity if available
                if (activity.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 16.w,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        activity,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24.h,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color:
                isPrimary ? Colors.transparent : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : primaryColor,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 16.w,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReviewSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    // Don't allow users to review themselves
    if (currentUserId == widget.userId) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave a review',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Rating bar
            Row(
              children: [
                Text(
                  'Rating: ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                RatingBar.builder(
                  initialRating: _reviewRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 24.r,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _reviewRating = rating;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Toggle between text and audio review
            Row(
              children: [
                Expanded(
                  child:
                      _buildReviewTypeToggle('Text', !_isReviewTypeAudio, () {
                    if (_isReviewTypeAudio) {
                      setState(() {
                        _isReviewTypeAudio = false;
                      });
                    }
                  }),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child:
                      _buildReviewTypeToggle('Voice', _isReviewTypeAudio, () {
                    if (!_isReviewTypeAudio) {
                      setState(() {
                        _isReviewTypeAudio = true;
                      });
                    }
                  }),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Show either text input or audio recorder based on selection
            if (_isReviewTypeAudio)
              _buildAudioReviewRecorder()
            else
              // Review text field
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                maxLines: 3,
              ),

            SizedBox(height: 16.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSubmittingReview
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the text/audio toggle buttons
  Widget _buildReviewTypeToggle(
      String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Text' ? Icons.text_fields : Icons.mic,
              size: 18.w,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Audio review recorder widget
  Widget _buildAudioReviewRecorder() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Permission request if not granted
          if (_micPermissionStatus != PermissionStatus.granted)
            Column(
              children: [
                Text(
                  'Microphone permission is required for voice reviews',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 8.h),
                ElevatedButton.icon(
                  onPressed: _requestMicrophonePermission,
                  icon: const Icon(Icons.mic),
                  label: const Text('Grant Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            )

          // Audio waveform when recording
          else if (_isRecording && _reviewAudioWaveform.isNotEmpty)
            Column(
              children: [
                // Recording indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Recording: ${_formatDuration(_recordingDuration)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Waveform visualization
                Container(
                  height: 40.h,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      _reviewAudioWaveform.length,
                      (index) => _buildWaveformBar(_reviewAudioWaveform[index]),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Stop button
                ElevatedButton.icon(
                  onPressed: _stopRecordingReview,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )

          // Already recorded audio player
          else if (_recordedReviewPath != null)
            Column(
              children: [
                // Audio player card
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isPlayingReview
                              ? _stopPlayingReview
                              : _playRecordedReview,
                          icon: Icon(
                            _isPlayingReview ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.all(8.w),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              'Duration: ${_formatDuration(_recordingDuration)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteRecordedReview,
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            )

          // Record button when no recording exists
          else
            Column(
              children: [
                Text(
                  'Tap to record your voice review',
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: _startRecordingReview,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40.w,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Maximum 60 seconds',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Helper method to build waveform bars for audio visualization
  Widget _buildWaveformBar(double amplitude) {
    final minHeight = 3.h;
    final maxHeight = 25.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return Container(
      width: 3.w,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(1.5.r),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final timestamp = review['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Unknown date';
    final rating = (review['rating'] ?? 0.0).toDouble();
    final comment = review['comment'] ?? '';
    final reviewerName = review['reviewerName'] ?? 'Anonymous';
    final reviewerProfilePicture = review['reviewerProfilePicture'];
    final audioUrl = review['audioUrl'] as String?;
    final audioDuration = review['audioDuration'] as int?;
    final isAudioReview = review['isAudioReview'] == true || audioUrl != null;
    final reviewId = review['id'] as String;
    final isCurrentlyPlaying = _isPlaying && _currentlyPlayingId == reviewId;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer info and rating
            Row(
              children: [
                // Reviewer avatar
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: reviewerProfilePicture != null
                      ? NetworkImage(reviewerProfilePicture)
                      : null,
                  child: reviewerProfilePicture == null
                      ? Text(
                          reviewerName.isNotEmpty
                              ? reviewerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12.w),

                // Reviewer name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateString,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Rating display
            Row(
              children: [
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  rating.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Review content - either text or audio
            if (isAudioReview && audioUrl != null)
              // Audio review player
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (isCurrentlyPlaying) {
                            _stopAudio();
                          } else {
                            _playAudio(audioUrl, reviewId);
                          }
                        },
                        icon: Icon(
                          isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                          size: 18.w,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(6.w),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Voice Review',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (audioDuration != null)
                            Text(
                              'Duration: ${_formatDuration(audioDuration)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (isCurrentlyPlaying)
                            const LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (comment.isNotEmpty)
              // Text review
              Text(
                comment,
                style: TextStyle(fontSize: 14.sp),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Missing method for showing profile options
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block user'),
              onTap: () {
                Navigator.pop(context);
                // Block user functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.amber),
              title: const Text('Report user'),
              onTap: () {
                Navigator.pop(context);
                // Report user functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryColor),
              title: const Text('Share profile'),
              onTap: () {
                Navigator.pop(context);
                // Share profile functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  // Missing method for empty posts view
  Widget _buildEmptyPostsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 30.h),
          Icon(
            Icons.post_add,
            size: 64.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'This user hasn\'t posted anything yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // Missing method for post list item
  Widget _buildPostListItem(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final timestamp = post['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Unknown date';
    final postId = post['id'] as String;
    final audioUrl = post['audioUrl'] as String?;
    final isCurrentlyPlaying = _isPlaying && _currentlyPlayingId == postId;
    final bool isLiked = post['isLiked'] ?? false;
    final int likesCount = post['likes'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage: _userData['profilePicture'] != null
                      ? NetworkImage(_userData['profilePicture'])
                      : null,
                  child: _userData['profilePicture'] == null
                      ? Text(
                          _userData['name'] != null &&
                                  _userData['name'].isNotEmpty
                              ? _userData['name'][0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['name'] ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      dateString,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show post options
                  },
                ),
              ],
            ),
          ),

          // Post content
          if (post['message'] != null && post['message'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: DirectionalityText(
                post['message'],
                style: TextStyle(fontSize: 14.sp),
              ),
            ),

          // Post image if available
          if (post['imageUrl'] != null)
            Container(
              width: double.infinity,
              height: 200.h,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              child: Image.network(
                post['imageUrl'],
                fit: BoxFit.cover,
              ),
            ),

          // Audio player if available
          if (audioUrl != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice message',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                          if (isCurrentlyPlaying)
                            LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                      ),
                      onPressed: () => audioUrl != null
                          ? _playAudio(audioUrl, postId)
                          : null,
                    ),
                  ],
                ),
              ),
            ),

          // Activity and location
          if (post['activity'] != null || post['city'] != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  if (post['activity'] != null) ...[
                    Icon(
                      Icons.work_outline,
                      size: 16.w,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      post['activity'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],
                  if (post['city'] != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.w,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      post['city'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Post actions (like, comment, share)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button with count
                InkWell(
                  onTap: () {
                    // Like functionality would go here
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Row(
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: isLiked ? Colors.red : Colors.black54,
                          size: 18.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          likesCount.toString(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPostAction(Icons.comment_outlined, 'Comment', () {}),
                _buildPostAction(Icons.share_outlined, 'Share', () {}),
              ],
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // Missing method for post action
  Widget _buildPostAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.w,
            color: Colors.black54,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Missing method for formatting timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
