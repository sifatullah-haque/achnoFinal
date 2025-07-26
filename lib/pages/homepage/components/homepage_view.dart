import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/config/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:achno/widgets/post_card.dart';
import 'package:achno/models/post_model.dart';
import 'homepage_controller.dart';
import 'homepage_filters.dart';
import 'homepage_states.dart';
import 'filter_bottom_sheet.dart';

class HomepageView extends StatefulWidget {
  final Function? onNavigateToAddPost;
  final HomepageController controller;

  const HomepageView({
    super.key,
    this.onNavigateToAddPost,
    required this.controller,
  });

  @override
  State<HomepageView> createState() => _HomepageViewState();
}

class _HomepageViewState extends State<HomepageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAddPost() {
    if (widget.onNavigateToAddPost != null) {
      widget.onNavigateToAddPost!();
    }
  }

  Widget _buildPostItem(Post post, int index) {
    final controller = widget.controller;

    // Only pass audio progress for currently playing post
    final isCurrentlyPlaying =
        controller.isPlaying && controller.currentlyPlayingId == post.id;

    // Get duration either from cache or post metadata
    Duration? duration;
    if (controller.audioDurations.containsKey(post.id)) {
      duration = controller.audioDurations[post.id];
    } else if (post.audioDuration != null && post.audioDuration! > 0) {
      duration = Duration(seconds: post.audioDuration!);
    }

    // Calculate city-based distance if available
    double? distanceInKm;
    if (controller.userHomeCity != null &&
        post.city != controller.userHomeCity) {
      distanceInKm = controller.getDistanceBetweenCities(post.city);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: PostCard(
        post: post,
        isPlayingAudio: isCurrentlyPlaying,
        onPlayAudio: (url) => controller.playAudio(url, post.id),
        onStopAudio: () => controller.playAudio('', ''), // This will stop audio
        onLikeUpdated: (isLiked, likeCount) {
          controller.updatePostLikeStatus(post.id, isLiked, likeCount);
        },
        currentPosition: controller.currentPosition,
        // Pass audio progress information
        audioDuration: isCurrentlyPlaying ? controller.audioDuration : duration,
        audioProgress: isCurrentlyPlaying ? controller.audioPosition : null,
        // Add callback to fetch audio duration if needed
        onNeedDuration: controller.fetchAudioDuration,
        // Pass the precalculated distance
        distanceFromUserCity: distanceInKm,
        userHomeCity: controller.userHomeCity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final filteredPosts = controller.getFilteredPosts(context);

        // Debug prints to understand the state
        debugPrint('HomepageView - isLoading: ${controller.isLoading}');
        debugPrint('HomepageView - hasError: ${controller.hasError}');
        debugPrint('HomepageView - posts count: ${controller.posts.length}');
        debugPrint(
            'HomepageView - filtered posts count: ${filteredPosts.length}');

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
                  backgroundColor: Colors.white.withOpacity(0.8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),
                      bottomRight: Radius.circular(24.r),
                    ),
                  ),
                  shadowColor: Colors.grey.withOpacity(0.2),
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24.r),
                        bottomRight: Radius.circular(24.r),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  title: Image.asset(
                    'assets/logo.png',
                    height: 40.h,
                    fit: BoxFit.cover,
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () =>
                        FilterBottomSheet.show(context, controller),
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Background patterns
              Positioned(
                top: -50.h,
                left: -50.w,
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
                bottom: -100.h,
                right: -60.w,
                child: Container(
                  height: 250.h,
                  width: 250.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: controller.isLoading
                    ? HomepageStates.buildLoadingState()
                    : controller.hasError
                        ? HomepageStates.buildErrorState(context, controller)
                        : controller.posts.isEmpty
                            ? HomepageStates.buildEmptyState(
                                context, controller, _navigateToAddPost)
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8.h),

                                    // Search bar
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      child: GestureDetector(
                                        onTap: _navigateToAddPost,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w),
                                          height: 50.h,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.search,
                                                color: Colors.grey[400],
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: TextField(
                                                  controller: controller
                                                      .searchController,
                                                  enabled: false,
                                                  decoration: InputDecoration(
                                                    hintText: l10n
                                                        .whatAreYouLookingFor,
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 14.sp,
                                                    ),
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 8.h),

                                    // User location indicator
                                    if (controller.userHomeCity != null)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.03),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.2),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 18.w,
                                                color: AppTheme.primaryColor,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                l10n.yourLocation(
                                                    controller.userHomeCity!),
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppTheme.textPrimaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    SizedBox(height: 6.h),

                                    // Distance filters
                                    if (controller.currentPosition != null)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${l10n.distance}:',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Wrap(
                                              spacing: 4.w,
                                              children: controller
                                                  .distanceOptions
                                                  .map((distance) =>
                                                      HomepageFilters
                                                          .buildDistanceFilterChip(
                                                              context,
                                                              distance,
                                                              controller))
                                                  .toList(),
                                            ),
                                            if (controller.selectedDistance !=
                                                null)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  size: 16.w,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () {
                                                  controller
                                                      .setSelectedDistance(
                                                          null);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),

                                    // Filter indicators
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      child:
                                          HomepageFilters.buildFilterIndicator(
                                              context, controller),
                                    ),

                                    SizedBox(height: 6.h),

                                    // Posts list
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w),
                                        child: RefreshIndicator(
                                          onRefresh: () =>
                                              controller.refreshPosts(context),
                                          child: filteredPosts.isEmpty
                                              ? HomepageStates
                                                  .buildNoResultsState(
                                                      context, controller)
                                              : ListView.builder(
                                                  physics:
                                                      const AlwaysScrollableScrollPhysics(),
                                                  itemCount:
                                                      filteredPosts.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return _buildPostItem(
                                                        filteredPosts[index],
                                                        index);
                                                  },
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
