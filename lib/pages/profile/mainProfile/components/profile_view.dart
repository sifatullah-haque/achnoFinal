import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/config/theme.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'profile_controller.dart';
import 'profile_states.dart';
import 'profile_widgets.dart';

class ProfileView extends StatefulWidget {
  final String? userId;
  final ProfileController? controller;

  const ProfileView({
    super.key,
    this.userId,
    this.controller,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProfileController _controller;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isScrolledUnderAppBar = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProfileController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setCurrentTabIndex(_tabController.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller == null) {
      _controller.initialize(widget.userId, context);
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
    _tabController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ProfileController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              body: ProfileStates.buildLoadingState(context),
            );
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
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
                      backgroundColor: Colors.white.withOpacity(0.7),
                      elevation: 0,
                      title: Text(
                        controller.isCurrentUser
                            ? 'Profile'
                            : controller.userData['name'] ?? 'Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.black87,
                        ),
                      ),
                      centerTitle: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      actions: [
                        if (!controller.isCurrentUser)
                          IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.black87),
                            onPressed: _showProfileOptions,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                // Background gradient (restored to previous style, but starts from the very top)
                Container(
                  width: double.infinity,
                  height: double.infinity,
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
                // Background pattern (restored, but starts from the very top)
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
                // Remove SafeArea to avoid extra top padding
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Profile header
                    SliverToBoxAdapter(
                      child: ProfileWidgets.buildProfileHeader(
                        context: context,
                        userData: controller.userData,
                        isCurrentUser: controller.isCurrentUser,
                        isFollowing: controller.isFollowing,
                        onFollowToggle: () => controller.toggleFollow(context),
                        onEditProfile: _navigateToEditProfile,
                        onSettings: _navigateToSettings,
                        onAudioBioPlay: () {
                          final audioUrl = controller.userData['audioBioUrl'];
                          if (audioUrl != null) {
                            controller.playAudioBio(audioUrl);
                          }
                        },
                        isAudioPlaying: controller.isPlaying,
                        currentlyPlayingId: controller.currentlyPlayingId,
                        onLogout: _showLogoutConfirmation,
                        onAdminDashboard: _navigateToAdminDashboard,
                        onMessage: _navigateToMessages,
                        onAddPost: _navigateToAddPost,
                      ),
                    ),
                    // Tab bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        minHeight: 60.h,
                        maxHeight: 60.h,
                        child: ProfileWidgets.buildTabBar(
                          context: context,
                          tabController: _tabController,
                          pendingPostsCount: 0,
                        ),
                      ),
                    ),
                    // Tab content as slivers
                    if (_tabController.index == 0)
                      _buildPostsSliver(controller)
                    else
                      _buildReviewsSliver(controller),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Replace ListView with SliverList for posts
  Widget _buildPostsSliver(ProfileController controller) {
    if (controller.userPosts.isEmpty) {
      return SliverToBoxAdapter(
          child: ProfileStates.buildEmptyPostsState(context));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = controller.userPosts[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ProfileWidgets.buildPostCard(
              context: context,
              post: post,
              onAudioPlay: () {
                final audioUrl = post['audioUrl'];
                final postId = post['id'];
                if (audioUrl != null && postId != null) {
                  controller.playAudio(audioUrl, postId);
                }
              },
              isCurrentlyPlaying: controller.isPlaying &&
                  controller.currentlyPlayingId == post['id'],
              currentlyPlayingId: controller.currentlyPlayingId,
              formatTimestamp: controller.formatTimestamp,
            ),
          );
        },
        childCount: controller.userPosts.length,
      ),
    );
  }

  // Replace ListView with SliverList for reviews
  Widget _buildReviewsSliver(ProfileController controller) {
    if (controller.userReviews.isEmpty) {
      return SliverToBoxAdapter(
          child: ProfileStates.buildEmptyReviewsState(context));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final review = controller.userReviews[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ProfileWidgets.buildReviewCard(
              context: context,
              review: review,
              onAudioPlay: () {
                final audioUrl = review['audioUrl'];
                final reviewId = review['id'];
                if (audioUrl != null && reviewId != null) {
                  controller.playAudio(audioUrl, reviewId);
                }
              },
              isCurrentlyPlaying: controller.isPlaying &&
                  controller.currentlyPlayingId == review['id'],
              currentlyPlayingId: controller.currentlyPlayingId,
              formatTimestamp: controller.formatTimestamp,
            ),
          );
        },
        childCount: controller.userReviews.length,
      ),
    );
  }

  void _navigateToEditProfile() {
    context.push('/edit-profile');
  }

  void _navigateToSettings() {
    context.push('/settings');
  }

  void _navigateToAdminDashboard() {
    context.push('/admin');
  }

  void _navigateToMessages() {
    context.push('/messages');
  }

  void _navigateToAddPost() {
    context.push('/add-post');
  }

  void _showLogoutConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n?.logout ?? 'Logout'),
          content: Text(
              l10n?.areYouSureLogout ?? 'Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: _logout,
              child: Text(
                l10n?.logout ?? 'Logout',
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

  Future<void> _logout() async {
    try {
      // Close the dialog first
      Navigator.of(context).pop();
      // Navigate to the login page
      context.go('/is-login');
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
              title: Text(l10n?.blockUser ?? 'Block user'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(l10n?.reportUser ?? 'Report user'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n?.shareProfile ?? 'Share profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
