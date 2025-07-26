import 'package:achno/config/theme.dart';
import 'package:achno/pages/main_screen.dart';
import 'package:achno/pages/profile/admin/admin.dart';
import 'package:achno/pages/profile/editProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:flutter/scheduler.dart';
import '../../providers/auth_provider.dart';
import 'dart:ui';
import '../profile/settings_page.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:achno/widgets/directionality_text.dart';
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

class Profile extends StatefulWidget {
  final String? userId;

  const Profile({super.key, this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCurrentUser = false;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReviews = [];
  bool _isFollowing = false;
  double _userRating = 0;

  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Audio player variables
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String _currentlyPlayingId = '';
  bool _isPlaying = false;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isScrolledUnderAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initAudioPlayer();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  // Override didUpdateWidget to handle potential changes
  @override
  void didUpdateWidget(Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the userId has changed, reload the data
    if (oldWidget.userId != widget.userId) {
      _loadUserData();
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

  // Add a method to play the audio bio
  Future<void> _playAudioBio(String audioUrl) async {
    if (_isPlaying) {
      await _stopAudio();
      if (_currentlyPlayingId == 'audio_bio') {
        // If we're stopping the audio bio, just return
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
    _loadUserReviews();
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
    _tabController.dispose();
    super.dispose();
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
      final targetUserId = widget.userId ?? currentUserId;

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
        'id': targetUserId,
        'name': data['firstName'] != null && data['lastName'] != null
            ? '${data['firstName']} ${data['lastName']}'
            : data['name'] ?? 'User',
        'username': data['username'] ?? '@username',
        'bio': data['bio'] ?? '',
        'activity': data['activity'] ?? '',
        'location': data['city'] ?? '',
        'profilePicture':
            data['profilePicture'], // Make sure this field matches exactly
        'postsCount': actualPostsCount, // CHANGED: Use actual count from query
        'followersCount': data['followersCount'] ?? 0,
        'followingCount': data['followingCount'] ?? 0,
        'isProfessional': data['isProfessional'] ?? false,
        'audioBioUrl': data['audioBioUrl'], // Add this line to load audioBioUrl
        'rating': averageRating, // Use calculated rating
        'reviewsCount': reviewsCount, // Use actual count from query
        'isAdmin': data['isAdmin'] ?? false, // ADDED: Load isAdmin status
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

      // Debug the profile picture URL
      debugPrint('Profile Picture URL: ${_userData['profilePicture']}');
      debugPrint('Audio Bio URL: ${_userData['audioBioUrl']}');
      debugPrint('Posts Count: $actualPostsCount');

      // Continue with the rest of the existing code...
      if (!_isCurrentUser && currentUserId != null) {
        final followDoc = await FirebaseFirestore.instance
            .collection('follows')
            .doc('${currentUserId}_$targetUserId')
            .get();

        setState(() {
          _isFollowing = followDoc.exists;
        });
      }

      // Modify the posts query to be simpler
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

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final l10n = AppLocalizations.of(context);
    final timestamp = review['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Unknown date'; // Temporary fallback
    final rating = (review['rating'] ?? 0.0).toDouble();
    final comment = review['comment'] ?? '';
    final reviewerName =
        review['reviewerName'] ?? 'Anonymous'; // Temporary fallback
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
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
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
                              'Voice Review', // Temporary fallback
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
                DirectionalityText(
                  comment,
                  style: TextStyle(fontSize: 14.sp),
                ),
            ],
          ),
        ));
  }

  // Add helper method to format duration
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadUserReviews() async {
    try {
      final targetUserId = widget.userId ??
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

      if (targetUserId == null) return;

      debugPrint('Loading reviews for user: $targetUserId');
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('targetUserId', isEqualTo: targetUserId)
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
    if (_isCurrentUser) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final targetUserId = _userData['id'];

    if (currentUserId == null || targetUserId == null) return;

    final followId = '${currentUserId}_$targetUserId';
    final followsCollection = FirebaseFirestore.instance.collection('follows');

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
      // Revert state if operation failed
      setState(() {
        _isFollowing = !_isFollowing;
      });

      // Make sure to show SnackBar using post-frame callback
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error updating follow status: ${e.toString()}')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Use translatable strings or fallbacks
    final settingsText = l10n.settings ?? 'Settings';
    final followText = l10n.follow ?? 'Follow';
    final messagesText = l10n.messages ?? 'Messages';

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
    final l10n = AppLocalizations.of(context); // Add this line

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
                        text: l10n.posts ?? 'Posts',
                        icon: Icon(Icons.post_add, size: 20.r),
                      ),
                      Tab(
                        text: l10n.reviews ?? 'Reviews',
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

  // Remove the helper method _buildNonScrollableContent as it's no longer needed
  // ...existing code...

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
    final isAdmin = _userData['isAdmin'] ?? false; // Extract isAdmin status

    // Use a key based on the profilePicture to force refresh when image changes
    final imageKey = profilePicture ?? DateTime.now().toString();

    // Debug the rendering of profile image
    debugPrint('Rendering profile image with URL: $profilePicture');

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

                    // Action buttons
                    if (_isCurrentUser)
                      Row(
                        children: [
                          // Admin dashboard button - only for admins
                          if (isAdmin)
                            IconButton(
                              icon: Icon(
                                Icons.admin_panel_settings,
                                color: Colors.purple[400],
                                size: 20.r,
                              ),
                              onPressed: () {
                                // Navigate to admin page
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const Admin(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutCubic;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);
                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.purple[50],
                                padding: EdgeInsets.all(12.r),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.r),
                                  side: BorderSide(
                                    color: Colors.purple.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              tooltip: 'Admin Dashboard',
                            ),
                          if (isAdmin) SizedBox(width: 10.w),

                          // Logout button
                          IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: Colors.red[400],
                              size: 15.r,
                            ),
                            onPressed: _showLogoutConfirmation,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.05),
                              padding: EdgeInsets.all(12.r),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.r),
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),

                          //edit profile button
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: primaryColor,
                              size:
                                  20.r, // Increased size for better visibility
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const EditProfile(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOutCubic;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    var offsetAnimation =
                                        animation.drive(tween);
                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                  reverseTransitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              )
                                  .then((_) {
                                // Force reload profile data when returning from edit page
                                _loadUserData();
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.all(12.r),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.r),
                                side: BorderSide(
                                  color: primaryColor.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              elevation: 2,
                              shadowColor: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildActionButton(
                            icon: _isFollowing
                                ? Icons.person_remove
                                : Icons.person_add,
                            label: _isFollowing ? 'Following' : 'Follow',
                            onTap: _toggleFollow,
                            isPrimary: !_isFollowing,
                          ),
                          SizedBox(width: 8.w),
                          _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: 'Message',
                            onTap: () {
                              // Navigate to messages with this user
                            },
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
                              l10n.professional ?? 'Professional',
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

                // Bio section - Audio Bio player if available
                if (bio.isNotEmpty || audioBioUrl != null) ...[
                  // Bio section header
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                    child: Text(
                      l10n.bio ?? 'Bio',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Text Bio
                  if (bio.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        bio,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
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
                          Expanded(
                            child: Text(
                              l10n.voiceBio ?? 'Voice Bio',
                              style: const TextStyle(
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
                      _userRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      ' (${(_userData['reviewsCount'] ?? 0)} ${l10n.reviews.toLowerCase() ?? 'reviews'})',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(l10n.posts ?? 'Posts', postsCount),
                      _buildDivider(),
                      _buildStatItem(
                          l10n.followers ?? 'Followers', followersCount),
                      _buildDivider(),
                      _buildStatItem(
                          l10n.following ?? 'Following', followingCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add a method for empty reviews view for consistency
  Widget _buildEmptyReviewsView() {
    final l10n = AppLocalizations.of(context);
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
            l10n.noReviewsYet ?? 'No reviews yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              _isCurrentUser
                  ? (l10n.noReviewsReceived ??
                      "You haven't received any reviews yet")
                  : (l10n.userHasNoReviews ??
                      "This user hasn't received any reviews yet"),
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

  Widget _buildEmptyPostsView() {
    final l10n = AppLocalizations.of(context);
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
            l10n.noPostsYet ?? 'No posts yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              _isCurrentUser
                  ? (l10n.shareFirstPost ??
                      'Share your first post with the community')
                  : (l10n.userHasNoPosts ??
                      'This user hasn\'t posted anything yet'),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isCurrentUser) ...[
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                _navigateToAddPostPage(context);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.createPost ?? 'Create Post'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ],
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // Add helper methods used in the profile header
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
    required VoidCallback onTap,
    bool isPrimary = true,
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

  void _navigateToAddPostPage(BuildContext context) {
    // Find ancestor MainScreen and update its state to show AddPost tab
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(initialIndex: 2),
        ));
  }

  // Method for post item display
  Widget _buildPostListItem(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                    Row(
                      children: [
                        Text(
                          _userData['name'] ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        if (_isCurrentUser) ...[
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'You', // Temporary fallback
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                            'Voice message', // Temporary fallback
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

          // Post actions (heart/like, comment, share)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Heart/Like button with count
                InkWell(
                  onTap: () {
                    // Toggle like functionality would be added here
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
                _buildPostAction(Icons.comment_outlined, 'Comment',
                    () {}), // Temporary fallback
                _buildPostAction(
                    Icons.share_outlined, 'Share', () {}), // Temporary fallback
              ],
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

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

  // Update the timestamp formatter
  String _formatTimestamp(DateTime timestamp) {
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
      return 'Just now'; // Temporary fallback
    }
  }

  // Update the logout confirmation dialog
  void _showLogoutConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.logout ?? 'Logout'),
          content:
              Text(l10n.areYouSureLogout ?? 'Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel ?? 'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: _logout,
              child: Text(
                l10n.logout ?? 'Logout',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update the profile options
  void _showProfileOptions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.blockUser ?? 'Block user'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(l10n.reportUser ?? 'Report user'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.shareProfile ?? 'Share profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Update this method to navigate to login page after logout
  Future<void> _logout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Navigate to login page using GoRouter instead of Navigator
      if (mounted) {
        // Close the dialog first
        Navigator.of(context).pop();
        // Navigate to the login page
        context.go('/is-login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
