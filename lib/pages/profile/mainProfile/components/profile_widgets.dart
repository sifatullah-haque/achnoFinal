import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/widgets/directionality_text.dart';
import 'package:achno/utils/activity_icon_helper.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

class ProfileWidgets {
  static Widget buildProfileHeader({
    required BuildContext context,
    required Map<String, dynamic> userData,
    required bool isCurrentUser,
    required bool isFollowing,
    required VoidCallback onFollowToggle,
    required VoidCallback onEditProfile,
    required VoidCallback onSettings,
    required VoidCallback onAudioBioPlay,
    required bool isAudioPlaying,
    required String currentlyPlayingId,
    required VoidCallback onLogout,
    required VoidCallback onAdminDashboard,
    required VoidCallback onMessage,
    required VoidCallback onAddPost,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    // Get user data with proper null checks and defaults
    final name = userData['name'] ?? 'User';
    final username = userData['username'] ?? '@username';
    final bio = userData['bio'] ?? '';
    final activity = userData['activity'] ?? '';
    final location = userData['location'] ?? '';
    final profilePicture = userData['profilePicture'];
    final audioBioUrl = userData['audioBioUrl'];
    final followersCount = userData['followersCount'] ?? 0;
    final followingCount = userData['followingCount'] ?? 0;
    final postsCount = userData['postsCount'] ?? 0;
    final reviewsCount = userData['reviewsCount'] ?? 0;
    final rating = userData['rating'] ?? 0.0;
    final isProfessional = userData['isProfessional'] ?? false;
    final isAdmin = userData['isAdmin'] ?? false;

    // Use a key based on the profilePicture to force refresh when image changes
    final imageKey =
        profilePicture != null ? profilePicture : DateTime.now().toString();

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
                    if (isCurrentUser)
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
                              onPressed: onAdminDashboard,
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
                            onPressed: onLogout,
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

                          // Edit profile button
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: primaryColor,
                              size: 20.r,
                            ),
                            onPressed: onEditProfile,
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
                            icon: isFollowing
                                ? Icons.person_remove
                                : Icons.person_add,
                            label: isFollowing ? 'Following' : 'Follow',
                            onTap: onFollowToggle,
                            isPrimary: !isFollowing,
                          ),
                          SizedBox(width: 8.w),
                          _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: 'Message',
                            onTap: onMessage,
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
                              l10n?.professional ?? 'Professional',
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
                        style: TextStyle(
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
                      l10n?.bio ?? 'Bio',
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
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => onAudioBioPlay(),
                              icon: Icon(
                                isAudioPlaying &&
                                        currentlyPlayingId == 'audio_bio'
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 18.w,
                              ),
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.all(6.w),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              l10n?.voiceBio ?? 'Voice Bio',
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
                      rating: rating.toDouble(),
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      ' ($reviewsCount ${l10n?.reviews?.toLowerCase() ?? 'reviews'})',
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
                      _buildStatItem(l10n?.posts ?? 'Posts', postsCount),
                      _buildDivider(),
                      _buildStatItem(
                          l10n?.followers ?? 'Followers', followersCount),
                      _buildDivider(),
                      _buildStatItem(
                          l10n?.following ?? 'Following', followingCount),
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

  static Widget _buildDivider() {
    return Container(
      height: 24.h,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  static Widget _buildStatItem(String label, int count) {
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

  static Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primaryColor
              : Colors.black.withOpacity(0.05),
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

  static Widget buildPostCard({
    required BuildContext context,
    required Map<String, dynamic> post,
    required VoidCallback onAudioPlay,
    required bool isCurrentlyPlaying,
    required String currentlyPlayingId,
    required Function(DateTime) formatTimestamp,
  }) {
    final timestamp = post['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? formatTimestamp(timestamp.toDate())
        : 'Unknown date';
    final postId = post['id'] as String;
    final audioUrl = post['audioUrl'] as String?;
    final message = post['message'] ?? '';
    final activity = post['activity'] ?? '';
    final city = post['city'] ?? '';
    final likesCount = post['likesCount'] ?? 0;
    final isLiked = post['isLiked'] ?? false;

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
          // Post content
          if (message.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
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
                      color: AppTheme.primaryColor,
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
                                AppTheme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                      ),
                      onPressed: () => onAudioPlay(),
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

          // Post actions
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

  static Widget _buildPostAction(
      IconData icon, String label, VoidCallback onTap) {
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

  static Widget buildReviewCard({
    required BuildContext context,
    required Map<String, dynamic> review,
    required VoidCallback onAudioPlay,
    required bool isCurrentlyPlaying,
    required String currentlyPlayingId,
    required Function(DateTime) formatTimestamp,
  }) {
    final l10n = AppLocalizations.of(context);
    final timestamp = review['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? formatTimestamp(timestamp.toDate())
        : 'Unknown date';
    final rating = (review['rating'] ?? 0.0).toDouble();
    final comment = review['comment'] ?? '';
    final reviewerName = review['reviewerName'] ?? 'Anonymous';
    final reviewerProfilePicture = review['reviewerProfilePicture'];
    final audioUrl = review['audioUrl'] as String?;
    final isAudioReview = review['isAudioReview'] == true || audioUrl != null;
    final reviewId = review['id'] as String;

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
                        icon: Icon(
                          isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                          size: 20.r,
                        ),
                        onPressed: () => onAudioPlay(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Review',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                          if (isCurrentlyPlaying)
                            LinearProgressIndicator(
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
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildTabBar({
    required BuildContext context,
    required TabController tabController,
    required int pendingPostsCount,
  }) {
    final l10n = AppLocalizations.of(context);

    return Container(
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
        controller: tabController,
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
            icon: Icon(Icons.star, size: 20.r),
          ),
        ],
      ),
    );
  }
}
