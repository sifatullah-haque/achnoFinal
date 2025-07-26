import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:achno/models/post_model.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;
import 'package:achno/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/widgets/response_dialog.dart';
import 'package:achno/widgets/directionality_text.dart';
import 'package:achno/pages/profile/viewProfile/viewProfile.dart';
import 'package:achno/utils/activity_icon_helper.dart'; // Import from new location

class PostCard extends StatefulWidget {
  final Post post;
  final bool isPlayingAudio;
  final Function(String) onPlayAudio;
  final VoidCallback onStopAudio;
  final Function(bool, int)? onLikeUpdated;
  final Position? currentPosition;
  final Duration? audioDuration;
  final Duration? audioProgress;
  final Function(String, String)? onNeedDuration;
  // Add new properties for city-based distance
  final double? distanceFromUserCity;
  final String? userHomeCity;

  const PostCard({
    super.key,
    required this.post,
    required this.isPlayingAudio,
    required this.onPlayAudio,
    required this.onStopAudio,
    this.onLikeUpdated,
    this.currentPosition,
    this.audioDuration,
    this.audioProgress,
    this.onNeedDuration,
    this.distanceFromUserCity, // New parameter
    this.userHomeCity, // New parameter
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeInProgress = false;
  final PostService _postService = PostService();
  String? _distanceText;
  bool _isCurrentUserPost = false;

  // New field for audio duration from Firebase if available
  Duration? _totalAudioDuration;

  // Add animation controller for audio visualization
  late AnimationController _audioVisualizationController;

  // Generate random visualization spikes data
  final List<double> _visualizationData = [];
  final int _spikeCount = 27; // Number of spikes to show

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _calculateDistance();
    _checkIfCurrentUserPost();
    _loadAudioDuration();
    _debugProfilePicture(); // Add this line

    // Initialize the visualization
    _initializeAudioVisualization();

    // Setup animation controller for waveform animation
    _audioVisualizationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  // Initialize audio visualization with random spikes
  void _initializeAudioVisualization() {
    final random = math.Random();
    _visualizationData.clear();

    // Generate random but somewhat realistic looking waveform data
    for (int i = 0; i < _spikeCount; i++) {
      // Create a pattern that looks like audio waveform
      double height;
      if (i < 5 || i > _spikeCount - 5) {
        // Lower at the edges
        height = 0.1 + random.nextDouble() * 0.3;
      } else if ((i > 8 && i < 12) ||
          (i > _spikeCount - 12 && i < _spikeCount - 8)) {
        // Higher in the middle sections
        height = 0.4 + random.nextDouble() * 0.4;
      } else {
        // Highest in the very middle
        height = 0.3 + random.nextDouble() * 0.7;
      }
      _visualizationData.add(height);
    }
  }

  // Load audio duration from post metadata if available
  void _loadAudioDuration() {
    if (widget.post.audioDuration != null && widget.post.audioDuration! > 0) {
      setState(() {
        _totalAudioDuration = Duration(seconds: widget.post.audioDuration!);
      });
    } else if (widget.post.audioUrl != null &&
        widget.post.audioUrl!.isNotEmpty) {
      // If duration is not available but we have a URL, set a temporary value
      // but also try to fetch the actual duration by checking with provider
      setState(() {
        // Initial placeholder duration while waiting for actual duration
        _totalAudioDuration = const Duration(seconds: 0);
      });

      // Notify parent to fetch the actual duration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onNeedDuration != null) {
          widget.onNeedDuration!(widget.post.id, widget.post.audioUrl!);
        }
      });
    }
  }

  // Load audio duration from post metadata if available
  // void _loadAudioDuration() {
  //   if (widget.post.audioDuration != null && widget.post.audioDuration! > 0) {
  //     setState(() {
  //       _totalAudioDuration = Duration(seconds: widget.post.audioDuration!);
  //     });
  //   } else if (widget.post.audioUrl != null &&
  //       widget.post.audioUrl!.isNotEmpty) {
  //     // If duration is not available but we have a URL, set a temporary value
  //     // but also try to fetch the actual duration by checking with provider
  //     setState(() {
  //       // Initial placeholder duration while waiting for actual duration
  //       _totalAudioDuration = Duration(seconds: 0);
  //     });

  //     // Notify parent to fetch the actual duration
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (widget.onNeedDuration != null) {
  //         widget.onNeedDuration!(widget.post.id, widget.post.audioUrl!);
  //       }
  //     });
  //   }
  // }

  // Add this debug method
  void _debugProfilePicture() {
    debugPrint('Post ID: ${widget.post.id}');
    debugPrint('User ID: ${widget.post.userId}');
    debugPrint('User Name: ${widget.post.userName}');
    debugPrint('User Avatar URL: ${widget.post.userAvatar}');
  }

  // Check if post belongs to current user
  Future<void> _checkIfCurrentUserPost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    setState(() {
      _isCurrentUserPost =
          (currentUserId != null && currentUserId == widget.post.userId);
    });
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likes != widget.post.likes) {
      setState(() {
        _isLiked = widget.post.isLiked;
        _likeCount = widget.post.likes;
      });
    }

    // Recalculate distance if current position changed
    if (oldWidget.currentPosition != widget.currentPosition) {
      _calculateDistance();
    }

    // Update audio duration if available
    if (oldWidget.audioDuration != widget.audioDuration) {
      setState(() {
        if (widget.audioDuration != null) {
          _totalAudioDuration = widget.audioDuration;
        }
      });
    }

    // Check if audioDuration was received from parent
    if (widget.audioDuration != null &&
        oldWidget.audioDuration != widget.audioDuration) {
      setState(() {
        _totalAudioDuration = widget.audioDuration;
      });
    }
  }

  @override
  void dispose() {
    _audioVisualizationController.dispose();
    super.dispose();
  }

  // Format duration to show mm:ss format - improved to handle null/zero values
  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inMilliseconds == 0) {
      // Check if we have a duration from post metadata
      if (widget.post.audioDuration != null && widget.post.audioDuration! > 0) {
        duration = Duration(seconds: widget.post.audioDuration!);
      } else {
        return "00:00"; // Unknown duration
      }
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Calculate distance between current user and post location - improved to handle large distances
  void _calculateDistance() {
    // First check for precalculated city-based distance
    if (widget.distanceFromUserCity != null) {
      final distanceInKm = widget.distanceFromUserCity!;

      setState(() {
        if (distanceInKm < 0.1) {
          // Very close - less than 100m
          _distanceText = 'Near you';
        } else if (distanceInKm < 1) {
          // Less than 1 km - show in meters
          _distanceText = '${(distanceInKm * 1000).round()}m ';
        } else if (distanceInKm < 10) {
          // Less than 10 km - show with 1 decimal
          _distanceText = '${distanceInKm.toStringAsFixed(1)}km ';
        } else if (distanceInKm < 100) {
          // Less than 100 km - show as integer km
          _distanceText = '${distanceInKm.round()}km ';
        } else if (distanceInKm < 1000) {
          // Less than 1000 km - show as integer km
          _distanceText = '${distanceInKm.round()}km ';
        } else {
          // 1000+ km - show in miles for US users
          double distanceInMiles = distanceInKm * 0.621371;
          _distanceText = '${distanceInMiles.round()}mi ';
        }

        // Add more context for debugging
        debugPrint(
            'Post city: ${widget.post.city}, User city: ${widget.userHomeCity}, Distance: $distanceInKm km');
      });
    }
    // Fall back to GPS-based distance if available
    else if (widget.currentPosition != null &&
        widget.post.latitude != null &&
        widget.post.longitude != null) {
      try {
        double distanceInMeters = Geolocator.distanceBetween(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
            widget.post.latitude!,
            widget.post.longitude!);

        double distanceInKm = distanceInMeters / 1000;

        setState(() {
          if (distanceInKm < 0.1) {
            _distanceText = 'Near you';
          } else if (distanceInKm < 1) {
            _distanceText = '${distanceInMeters.round()}m';
          } else if (distanceInKm < 10) {
            _distanceText = '${distanceInKm.toStringAsFixed(1)}km ';
          } else if (distanceInKm < 1000) {
            _distanceText = '${distanceInKm.round()}km ';
          } else {
            // 1000+ km - show in miles for US users
            double distanceInMiles = distanceInKm * 0.621371;
            _distanceText = '${distanceInMiles.round()}mi';
          }
        });
      } catch (e) {
        debugPrint('Error calculating GPS-based distance: $e');
        _distanceText = null;
      }
    } else {
      setState(() {
        _distanceText = null;
      });
    }
  }

  // Calculate time left based on expiry date
  String _getTimeLeft(Post post) {
    // If no expiry date or duration is set, return empty string
    if (post.expiryDate == null && post.duration == null) {
      return '';
    }

    final now = DateTime.now();

    // If we have an expiry date, calculate based on that
    if (post.expiryDate != null) {
      final difference = post.expiryDate!.difference(now);

      // If post is expired
      if (difference.isNegative) {
        return 'Expired';
      }

      // If expiry is less than 48 hours
      if (difference.inHours <= 48) {
        return '${difference.inHours}hr left';
      }
      // If expiry is less than 7 days
      else if (difference.inDays < 7) {
        return '${difference.inDays}day left';
      }
      // If expiry is more than 7 days
      else {
        return '${difference.inDays}day left';
      }
    }

    // Fallback if we only have duration string
    else if (post.duration != null) {
      switch (post.duration) {
        case '48h':
          return '48hr left';
        case '7d':
          return '7day left';
        case '30d':
          return '30day left';
        case 'Unlimited':
        default:
          return '';
      }
    }

    return '';
  }

  // Get color for time left indicator
  Color _getTimeLeftColor(String timeLeft) {
    if (timeLeft.contains('Expired')) {
      return Colors.red.shade700;
    } else if (timeLeft.contains('hr')) {
      return Colors.red.shade700;
    } else if (timeLeft.contains('day') &&
        (int.tryParse(timeLeft.split('day')[0]) ?? 0) <= 7) {
      return Colors.orange.shade700;
    } else {
      return Colors.blue.shade700;
    }
  }

  // Get background color for time left indicator
  Color _getTimeLeftBgColor(String timeLeft) {
    if (timeLeft.contains('Expired')) {
      return Colors.red.shade50;
    } else if (timeLeft.contains('hr')) {
      return Colors.red.shade50;
    } else if (timeLeft.contains('day') &&
        (int.tryParse(timeLeft.split('day')[0]) ?? 0) <= 7) {
      return Colors.orange.shade50;
    } else {
      return Colors.blue.shade50;
    }
  }

  // Get border color for time left indicator
  Color _getTimeLeftBorderColor(String timeLeft) {
    if (timeLeft.contains('Expired')) {
      return Colors.red.shade200;
    } else if (timeLeft.contains('hr')) {
      return Colors.red.shade200;
    } else if (timeLeft.contains('day') &&
        (int.tryParse(timeLeft.split('day')[0]) ?? 0) <= 7) {
      return Colors.orange.shade200;
    } else {
      return Colors.blue.shade200;
    }
  }

  // Build custom audio visualization with spikes
  Widget _buildAudioVisualization(bool isPlaying, double progress) {
    return SizedBox(
      height: 20.h,
      child: Row(
        children: List.generate(
          _visualizationData.length,
          (index) {
            final position = index / (_visualizationData.length - 1);
            final isActive = position <= progress;

            // Apply subtle animation to make it look alive when playing
            double heightFactor = _visualizationData[index];
            if (isPlaying && isActive) {
              final animation = math.sin(
                          _audioVisualizationController.value * math.pi +
                              index * 0.2) *
                      0.15 +
                  0.85;
              heightFactor *= animation;
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isPlaying ? Colors.red : AppTheme.primaryColor)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  height: 16.h * heightFactor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Handle like button press with Firebase update
  Future<void> _handleLikePress() async {
    // Don't allow liking if user is the post owner
    if (_isLikeInProgress || _isCurrentUserPost) return;

    setState(() {
      _isLikeInProgress = true;
    });

    try {
      // Toggle like status
      final newLikeStatus = !_isLiked;

      // Update like count locally first for immediate feedback
      setState(() {
        _isLiked = newLikeStatus;
        _likeCount += newLikeStatus ? 1 : -1;

        // Ensure like count doesn't go below 0
        if (_likeCount < 0) _likeCount = 0;
      });

      // Update post in Firebase (this will also trigger a notification)
      await _postService.updatePostLike(widget.post.id, newLikeStatus);

      // Call the onLikeUpdated callback with new status and count
      if (widget.onLikeUpdated != null) {
        widget.onLikeUpdated!(_isLiked, _likeCount);
      }
    } catch (e) {
      // If there's an error, revert the local changes
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;

        // Ensure like count doesn't go below 0
        if (_likeCount < 0) _likeCount = 0;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeInProgress = false;
        });
      }
    }
  }

  // Show the response dialog
  void _showResponseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResponseDialog(
        post: widget.post,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response sent successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  // Add method to build city distance indicator with better visual presentation
  Widget _buildCityDistanceIndicator() {
    if (_distanceText == null) return const SizedBox.shrink();

    // Determine if this is a long distance (for visual styling)
    bool isLongDistance = _distanceText != null &&
        (_distanceText!.contains('mi') ||
            (_distanceText!.contains('km') &&
                (int.tryParse(_distanceText!.split('km')[0].trim()) ?? 0) >
                    100));

    if (widget.distanceFromUserCity != null && widget.userHomeCity != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        // decoration: BoxDecoration(
        //   // color: isLongDistance
        //   //     ? Colors.orange.withOpacity(0.1)
        //   //     : AppTheme.primaryColor.withOpacity(0.1),
        //   // borderRadius: BorderRadius.circular(8.r),
        //   border: Border.all(
        //     color: isLongDistance
        //         ? Colors.orange.withOpacity(0.2)
        //         : AppTheme.primaryColor.withOpacity(0.2),
        //     width: 1,
        //   ),
        // ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLongDistance ? Icons.map_outlined : Icons.location_on_outlined,
              size: 14.w,
              color: isLongDistance ? Colors.orange : AppTheme.primaryColor,
            ),
            SizedBox(width: 4.w),
            Text(
              _distanceText!,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isLongDistance ? Colors.orange : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions_walk,
          size: 14.w,
          color: AppTheme.primaryColor,
        ),
        SizedBox(width: 4.w),
        Text(
          _distanceText!,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Add a method to navigate to user profile
  void _navigateToUserProfile(BuildContext context) {
    if (widget.post.userId.isEmpty) {
      // Show error if userId is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User information not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to view profile page with the user's ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfile(userId: widget.post.userId),
      ),
    );
  }

  // Modified version to use DirectionalityText for text content
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeLeft = _getTimeLeft(widget.post);

    // Check if the post is expired based on timeLeft text or the method
    final bool isExpired = timeLeft.contains('Expired') || _isPostExpired();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and post type
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Use the new method for user avatar
                _buildUserAvatar(),
                SizedBox(width: 12.w),

                // User info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username row with verification badge if professional - Now clickable
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(context),
                        child: Row(
                          children: [
                            Flexible(
                              child: DirectionalityText(
                                widget.post.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.post.isProfessional) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.verified,
                                size: 14.w,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Dynamic rating display
                      _buildRatingDisplay(),
                    ],
                  ),
                ),

                // Add time left indicator if exists
                if (timeLeft.isNotEmpty) ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: _getTimeLeftBgColor(timeLeft),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _getTimeLeftBorderColor(timeLeft),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      timeLeft,
                      style: TextStyle(
                        color: _getTimeLeftColor(timeLeft),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // Post type chip (Request/Offer)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: widget.post.type == PostType.request
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: widget.post.type == PostType.request
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.post.type == PostType.request ? 'Request' : 'Offer',
                    style: TextStyle(
                      color: widget.post.type == PostType.request
                          ? Colors.blue
                          : Colors.green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ENHANCED: Activity with large icon
          // if (widget.post.activity.isNotEmpty)
          //   Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          //     child: Container(
          //       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          //       decoration: BoxDecoration(
          //         color: ActivityIconHelper.getColorForActivity(
          //                 widget.post.activity)
          //             .withOpacity(0.1),
          //         borderRadius: BorderRadius.circular(12.r),
          //         border: Border.all(
          //           color: ActivityIconHelper.getColorForActivity(
          //                   widget.post.activity)
          //               .withOpacity(0.3),
          //           width: 1.5,
          //         ),
          //       ),
          //       child: Row(
          //         children: [
          //           Container(
          //             padding: EdgeInsets.all(8.w),
          //             decoration: BoxDecoration(
          //               color: Colors.white,
          //               shape: BoxShape.circle,
          //               boxShadow: [
          //                 BoxShadow(
          //                   color: ActivityIconHelper.getColorForActivity(
          //                           widget.post.activity)
          //                       .withOpacity(0.2),
          //                   blurRadius: 8,
          //                   spreadRadius: 0,
          //                 ),
          //               ],
          //             ),
          //             child: Icon(
          //               ActivityIconHelper.getIconForActivity(
          //                   widget.post.activity),
          //               size: 28.w,
          //               color: ActivityIconHelper.getColorForActivity(
          //                   widget.post.activity),
          //             ),
          //           ),
          //           SizedBox(width: 12.w),
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 Text(
          //                   'Activity',
          //                   style: TextStyle(
          //                     fontSize: 12.sp,
          //                     color: Colors.black54,
          //                   ),
          //                 ),
          //                 SizedBox(height: 2.h),
          //                 DirectionalityText(
          //                   widget.post.activity,
          //                   style: TextStyle(
          //                     fontSize: 16.sp,
          //                     fontWeight: FontWeight.bold,
          //                     color: ActivityIconHelper.getColorForActivity(
          //                         widget.post.activity),
          //                   ),
          //                   maxLines: 1,
          //                   overflow: TextOverflow.ellipsis,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),

          // Location and Distance - Redesigned for better spacing and ellipsis
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // City with ellipsis
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.w,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: DirectionalityText(
                          widget.post.city,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance with ellipsis
                if (_distanceText != null)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14.w,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              _distanceText!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Time ago with ellipsis
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.watch_later_outlined,
                        size: 14.w,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: DirectionalityText(
                          timeago.format(widget.post.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message content
          if (widget.post.message.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: DirectionalityText(
                widget.post.message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimaryColor,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Audio message - Enhanced WhatsApp style player with visualization
          if (widget.post.audioUrl != null && widget.post.audioUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Play/Pause button with animation
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: widget.isPlayingAudio
                            ? Colors.red.shade100
                            : AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isPlayingAudio
                              ? Colors.red.shade300
                              : AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => widget.isPlayingAudio
                            ? widget.onStopAudio()
                            : widget.onPlayAudio(widget.post.audioUrl!),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Icon(
                          widget.isPlayingAudio
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: widget.isPlayingAudio
                              ? Colors.red
                              : AppTheme.primaryColor,
                          size: 20.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Progress and duration information - WhatsApp style with visualization
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Audio visualization with spikes
                          _buildAudioVisualization(
                            widget.isPlayingAudio,
                            widget.isPlayingAudio &&
                                    widget.audioProgress != null &&
                                    widget.audioDuration != null
                                ? (widget.audioProgress!.inMilliseconds /
                                        widget.audioDuration!.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                          ),

                          SizedBox(height: 6.h),

                          // Time display (current / total)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Current position when playing
                              DirectionalityText(
                                widget.isPlayingAudio &&
                                        widget.audioProgress != null
                                    ? _formatDuration(widget.audioProgress)
                                    : "00:00",
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              // Total duration
                              DirectionalityText(
                                _formatDuration(_totalAudioDuration),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Footer with interactions
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.post.activity.isNotEmpty)
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ActivityIconHelper.getColorForActivity(
                                        widget.post.activity)
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: ActivityIconHelper.getColorForActivity(
                                      widget.post.activity)
                                  .withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            ActivityIconHelper.getIconForActivity(
                                widget.post.activity),
                            size: 22.w,
                            color: ActivityIconHelper.getColorForActivity(
                                widget.post.activity),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DirectionalityText(
                            widget.post.activity,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: ActivityIconHelper.getColorForActivity(
                                  widget.post.activity),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(width: 12.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _isLikeInProgress || _isCurrentUserPost
                          ? null
                          : _handleLikePress,
                      borderRadius: BorderRadius.circular(20.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(8.w),
                        child: Row(
                          children: [
                            _isLikeInProgress
                                ? SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _isLiked
                                            ? Colors.red
                                            : AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  )
                                : TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 300),
                                    tween: Tween<double>(
                                      begin: _isLiked ? 0.8 : 1.0,
                                      end: _isLiked ? 1.0 : 1.0,
                                    ),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: _isLiked ? value : 1.0,
                                        child: Icon(
                                          _isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border_outlined,
                                          color: _isCurrentUserPost
                                              ? Colors.grey.withOpacity(0.5)
                                              : (_isLiked
                                                  ? Colors.red
                                                  : AppTheme
                                                      .textSecondaryColor),
                                          size: 18.r,
                                        ),
                                      );
                                    },
                                  ),
                            SizedBox(width: 4.w),
                            DirectionalityText(
                              _likeCount.toString(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _isCurrentUserPost
                                    ? Colors.grey.withOpacity(0.5)
                                    : (_isLiked
                                        ? Colors.red
                                        : AppTheme.textSecondaryColor),
                                fontWeight: _isLiked
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton.icon(
                      onPressed: _isCurrentUserPost || isExpired
                          ? null
                          : _showResponseDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCurrentUserPost || isExpired
                            ? Colors.grey
                            : Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(
                        Icons.reply_rounded,
                        size: 16.r,
                      ),
                      label: DirectionalityText(
                        _isCurrentUserPost
                            ? 'Your Post'
                            : isExpired
                                ? 'Expired'
                                : 'Response',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Add method to build user avatar properly
  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: () => _navigateToUserProfile(context),
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            widget.post.userAvatar != null && widget.post.userAvatar!.isNotEmpty
                ? NetworkImage(widget.post.userAvatar!)
                : null,
        child: widget.post.userAvatar == null || widget.post.userAvatar!.isEmpty
            ? Text(
                widget.post.userName.isNotEmpty
                    ? widget.post.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              )
            : null,
      ),
    );
  }

  // Add method to display ratings properly
  Widget _buildRatingDisplay() {
    final rating = widget.post.rating ?? 0.0;
    final reviewCount = widget.post.reviewCount ?? 0;

    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 14.w,
        ),
        SizedBox(width: 2.w),
        Text(
          '${rating.toStringAsFixed(1)}($reviewCount)',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Add method to check if post is expired
  bool _isPostExpired() {
    // If no expiry date is set, the post is not considered expired
    if (widget.post.expiryDate == null) {
      // If we have a duration string that says "Expired", consider it expired
      if (widget.post.duration != null && widget.post.duration == 'Expired') {
        return true;
      }
      return false;
    }

    // Check if the expiry date is in the past
    final now = DateTime.now();
    return widget.post.expiryDate!.isBefore(now);
  }
}
