import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/config/theme.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:achno/widgets/directionality_text.dart';
import 'package:achno/utils/activity_icon_helper.dart';
import 'dart:ui';
import 'package:achno/l10n/app_localizations.dart';
import 'package:flutter/scheduler.dart'; // Import this for SchedulerBinding

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingPosts = [];
  List<Map<String, dynamic>> _approvedPosts = [];
  List<Map<String, dynamic>> _rejectedPosts = [];

  // Audio player variables
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String _currentlyPlayingId = '';
  bool _isPlaying = false;

  int get _totalPosts =>
      _pendingPosts.length + _approvedPosts.length + _rejectedPosts.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize audio player without any context dependencies
    _initAudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is the safe place to access context-dependent APIs
    _loadPosts();
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
          usage: AndroidAudioUsage.media,
        ),
      ));
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopAudio();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Modified approach for pending posts: use two separate queries and combine results
      // First get posts with 'pending' status
      final pendingStatusQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      // Then get posts without any approvalStatus field or where approvalStatus is null
      final nullStatusQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('approvalStatus',
              isNull: true) // Use isNull instead of whereIn with null
          .orderBy('createdAt', descending: true)
          .get();

      // Load approved posts - no changes needed
      final approvedQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      // Load rejected posts - no changes needed
      final rejectedQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('approvalStatus', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .get();

      // Combine pending and null status posts
      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
          combinedPendingDocs = [
        ...pendingStatusQuery.docs,
        ...nullStatusQuery.docs
      ];

      // Process the query results and load user data for each post
      final List<Map<String, dynamic>> pendingPosts = [];
      for (var doc in combinedPendingDocs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Fetch user information for this post
        final userId = data['userId'];
        if (userId != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              data['userName'] =
                  userData['firstName'] != null && userData['lastName'] != null
                      ? '${userData['firstName']} ${userData['lastName']}'
                      : userData['name'] ?? 'Unknown User';
              data['userAvatar'] = userData['profilePicture'];
            }
          } catch (e) {
            debugPrint('Error loading user data for post: $e');
          }
        }
        pendingPosts.add(data);
      }

      final List<Map<String, dynamic>> approvedPosts = [];
      for (var doc in approvedQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Fetch user information for this post
        final userId = data['userId'];
        if (userId != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              data['userName'] =
                  userData['firstName'] != null && userData['lastName'] != null
                      ? '${userData['firstName']} ${userData['lastName']}'
                      : userData['name'] ?? 'Unknown User';
              data['userAvatar'] = userData['profilePicture'];
            }
          } catch (e) {
            debugPrint('Error loading user data for post: $e');
          }
        }
        approvedPosts.add(data);
      }

      final List<Map<String, dynamic>> rejectedPosts = [];
      for (var doc in rejectedQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Fetch user information for this post
        final userId = data['userId'];
        if (userId != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              data['userName'] =
                  userData['firstName'] != null && userData['lastName'] != null
                      ? '${userData['firstName']} ${userData['lastName']}'
                      : userData['name'] ?? 'Unknown User';
              data['userAvatar'] = userData['profilePicture'];
            }
          } catch (e) {
            debugPrint('Error loading user data for post: $e');
          }
        }
        rejectedPosts.add(data);
      }

      if (mounted) {
        setState(() {
          _pendingPosts = pendingPosts;
          _approvedPosts = approvedPosts;
          _rejectedPosts = rejectedPosts;
          _isLoading = false;
        });
      }

      debugPrint(
          'Loaded posts - Pending: ${_pendingPosts.length}, Approved: ${_approvedPosts.length}, Rejected: ${_rejectedPosts.length}');
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Use a post-frame callback to show error messages
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading posts: ${e.toString()}')),
          );
        });
      }
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
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingId = '';
            });
          }
        },
      );

      setState(() {
        _isPlaying = true;
        _currentlyPlayingId = postId;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        // Use a post-frame callback to show error messages
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing audio: ${e.toString()}')),
          );
        });
      }
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

  Future<void> _approvePost(String postId) async {
    final l10n = AppLocalizations.of(context);

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Get the current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.currentUser?.id;

      // Add admin ID who approved
      if (adminId != null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'approvedBy': adminId,
        });
      }

      // Refresh posts
      await _loadPosts();

      // Use a post-frame callback to show success messages
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Post approved and now visible on homepage')), // Temporary fallback
          );
        }
      });
    } catch (e) {
      debugPrint('Error approving post: $e');
      // Use a post-frame callback to show error messages
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error approving post: ${e.toString()}')), // Temporary fallback
          );
        }
      });
    }
  }

  Future<void> _rejectPost(String postId) async {
    final l10n = AppLocalizations.of(context);

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Get the current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.currentUser?.id;

      // Add admin ID and rejection reason (optional enhancement)
      if (adminId != null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'rejectedBy': adminId,
        });
      }

      // Refresh posts
      await _loadPosts();

      // Use a post-frame callback to show success messages
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Post rejected and removed from homepage')), // Temporary fallback
          );
        }
      });
    } catch (e) {
      debugPrint('Error rejecting post: $e');
      // Use a post-frame callback to show error messages
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error rejecting post: ${e.toString()}')), // Temporary fallback
          );
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24.r),
            bottomRight: Radius.circular(24.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              title: Text(
                l10n.adminDashboard ?? 'Admin Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: _loadPosts,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
          ),

          // Background pattern
          Positioned(
            top: -100.h,
            right: -60.w,
            child: Container(
              height: 200.h,
              width: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),

          Positioned(
            bottom: -80.h,
            left: -40.w,
            child: Container(
              height: 180.h,
              width: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Stats overview row
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          l10n.pending ?? 'Pending',
                          _pendingPosts.length,
                          Colors.orange,
                          Icons.pending_actions,
                        ),
                        _buildStatCard(
                          l10n.approved ?? 'Approved',
                          _approvedPosts.length,
                          Colors.green,
                          Icons.check_circle_outline,
                        ),
                        _buildStatCard(
                          l10n.rejected ?? 'Rejected',
                          _rejectedPosts.length,
                          Colors.red,
                          Icons.cancel_outlined,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 3.0,
                    tabs: [
                      Tab(
                        text: l10n.pending ?? 'Pending',
                        icon: Badge(
                          label: Text(_pendingPosts.length.toString()),
                          isLabelVisible: _pendingPosts.isNotEmpty,
                          child: Icon(Icons.pending_actions, size: 20.r),
                        ),
                      ),
                      Tab(
                        text: l10n.approved ?? 'Approved',
                        icon: Icon(Icons.check_circle_outline, size: 20.r),
                      ),
                      Tab(
                        text: l10n.rejected ?? 'Rejected',
                        icon: Icon(Icons.cancel_outlined, size: 20.r),
                      ),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending posts tab
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _pendingPosts.isEmpty
                              ? _buildEmptyState(l10n.noPendingPostsToReview ??
                                  'No pending posts to review')
                              : _buildPostsList(_pendingPosts, true),

                      // Approved posts tab
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _approvedPosts.isEmpty
                              ? _buildEmptyState(
                                  l10n.noApprovedPosts ?? 'No approved posts')
                              : _buildPostsList(_approvedPosts, false,
                                  canReject: true),

                      // Rejected posts tab
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _rejectedPosts.isEmpty
                              ? _buildEmptyState(
                                  l10n.noRejectedPosts ?? 'No rejected posts')
                              : _buildPostsList(_rejectedPosts, false,
                                  canApprove: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.r,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64.r,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadPosts,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(l10n.refresh ?? 'Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<Map<String, dynamic>> posts, bool showActions,
      {bool canApprove = false, bool canReject = false}) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index], showActions,
            canApprove: canApprove, canReject: canReject);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool showActions,
      {bool canApprove = false, bool canReject = false}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final timestamp = post['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Unknown date'; // Temporary fallback
    final postId = post['id'] as String;
    final audioUrl = post['audioUrl'] as String?;
    final isCurrentlyPlaying = _isPlaying && _currentlyPlayingId == postId;
    final userName = post['userName'] ?? 'Unknown User'; // Temporary fallback
    final userAvatar = post['userAvatar'];
    final message = post['message'] ?? '';
    final activity = post['activity'] ?? '';
    final city = post['city'] ?? '';

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
          // Post header with user info
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage:
                      userAvatar != null ? NetworkImage(userAvatar) : null,
                  child: userAvatar == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
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

                // Post ID badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'ID: ${postId.substring(0, 4)}...',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Post content
          if (message.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: DirectionalityText(
                message,
                style: TextStyle(fontSize: 14.sp),
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
          if (activity.isNotEmpty || city.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  if (activity.isNotEmpty) ...[
                    Icon(
                      ActivityIconHelper.getIconForActivity(activity),
                      size: 16.w,
                      color: ActivityIconHelper.getColorForActivity(activity),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      activity,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: ActivityIconHelper.getColorForActivity(activity),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],
                  if (city.isNotEmpty) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.w,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Action buttons for pending posts
          if (showActions)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectPost(postId),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.reject ?? 'Reject'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePost(postId),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.approve ?? 'Approve'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action button for rejected posts (can approve)
          if (canApprove)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _approvePost(postId),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.moveToApproved ?? 'Move to Approved'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ),

          // Action button for approved posts (can reject)
          if (canReject)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _rejectPost(postId),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.moveToRejected ?? 'Move to Rejected'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
