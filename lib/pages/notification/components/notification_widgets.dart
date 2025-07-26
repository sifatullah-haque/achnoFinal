import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;
import 'package:achno/models/notification_model.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/pages/notification/components/notification_controller.dart';

class NotificationWidgets {
  static Widget buildAppBar(
      BuildContext context, NotificationController controller) {
    final l10n = AppLocalizations.of(context);

    return PreferredSize(
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
            title: Text(
              l10n.notifications,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            centerTitle: true,
            actions: [
              // Test notification button
              IconButton(
                icon: const Icon(
                  Icons.notification_add,
                  color: AppTheme.primaryColor,
                ),
                tooltip: l10n.sendTestNotification,
                onPressed: () => controller.sendTestNotification(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.textSecondaryColor,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) =>
                        _buildOptionsSheet(context, controller),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildBackground() {
    return Stack(
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
      ],
    );
  }

  static Widget buildEmptyState(
      BuildContext context, Animation<double> fadeAnimation) {
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80.w,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.notificationEmpty,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                l10n.notificationEmptyMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState(
      BuildContext context, String error, VoidCallback onRetry) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  static Widget buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    int index,
    NotificationController controller,
  ) {
    // Softer text colors for better readability
    const textColor = AppTheme.textPrimaryColor;
    const subtitleColor = AppTheme.textSecondaryColor;

    // New accent color based on notification type
    Color accentColor = _getNotificationAccentColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        controller.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).deleteNotification),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          leading: Stack(
            children: [
              _buildLeadingAvatar(notification, accentColor),
              if (!notification.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 15.sp,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                timeago.format(notification.time, locale: 'en_short'),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: notification.isRead ? Colors.grey[500] : accentColor,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.message != null) ...[
                SizedBox(height: 4.h),
                Text(
                  notification.message!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: notification.isRead ? subtitleColor : textColor,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getNotificationTypeIcon(notification.type),
                          size: 12.w,
                          color: accentColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getNotificationTypeText(context, notification.type),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: _buildActionButton(context, notification, accentColor),
          onTap: () => controller.handleNotificationTap(context, notification),
          onLongPress: () =>
              _showNotificationOptions(context, notification, controller),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  static Widget _buildLeadingAvatar(
      NotificationModel notification, Color accentColor) {
    if (notification.type == NotificationType.system) {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.announcement_outlined,
          color: accentColor,
          size: 24.w,
        ),
      );
    }

    if (notification.senderAvatar != null) {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : accentColor.withOpacity(0.5),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 23.r,
          backgroundImage: NetworkImage(notification.senderAvatar!),
        ),
      );
    }

    // Fallback avatar with first letter of sender name
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: notification.isRead
              ? Colors.grey[200]!
              : accentColor.withOpacity(0.5),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 23.r,
        backgroundColor: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
            .withOpacity(1.0),
        child: Text(
          notification.senderName.isNotEmpty
              ? notification.senderName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static Widget? _buildActionButton(
    BuildContext context,
    NotificationModel notification,
    Color accentColor,
  ) {
    final l10n = AppLocalizations.of(context);

    switch (notification.type) {
      case NotificationType.follow:
        return ElevatedButton(
          onPressed: () {
            // Follow back functionality
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            minimumSize: Size(24.w, 30.h),
            textStyle: TextStyle(fontSize: 12.sp),
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            elevation: 0,
          ),
          child: Text(l10n.follow),
        );
      default:
        return null;
    }
  }

  static Widget _buildOptionsSheet(
      BuildContext context, NotificationController controller) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  l10n.notifications,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 24.h),

                _buildOptionItem(
                  icon: Icons.done_all,
                  label: l10n.markAllAsRead,
                  onTap: () {
                    Navigator.pop(context);
                    controller.markAllNotificationsAsRead();
                  },
                ),

                _buildOptionItem(
                  icon: Icons.delete_sweep,
                  label: l10n.clearAllNotifications,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.clearAllNotifications),
                        content: Text(l10n.clearAllConfirmation),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              controller.clearAllNotifications();
                            },
                            child: Text(l10n.clearAll),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                _buildOptionItem(
                  icon: Icons.settings,
                  label: l10n.notificationSettings,
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to notification settings screen
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20.w,
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSecondaryColor,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  static void _showNotificationOptions(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
  ) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 5.h,
                        margin: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        notification.isRead
                            ? Icons.mark_email_unread_outlined
                            : Icons.mark_email_read_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        notification.isRead
                            ? l10n.markAsUnread
                            : l10n.markAsRead,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (!notification.isRead) {
                          controller.markNotificationAsRead(notification.id);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                      ),
                      title: Text(
                        l10n.deleteNotification,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        controller.deleteNotification(notification.id);
                      },
                    ),
                    if (notification.type == NotificationType.message ||
                        notification.type == NotificationType.follow)
                      ListTile(
                        leading: const Icon(
                          Icons.person_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          '${l10n.viewProfile} ${notification.senderName}',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to profile
                        },
                      ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  static String _getNotificationTypeText(
      BuildContext context, NotificationType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case NotificationType.message:
        return l10n.message;
      case NotificationType.like:
        return l10n.like;
      case NotificationType.comment:
        return l10n.comment;
      case NotificationType.follow:
        return l10n.follow;
      case NotificationType.mention:
        return l10n.mention;
      case NotificationType.system:
        return l10n.system;
    }
  }

  static Color _getNotificationAccentColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.like:
        return Colors.pink;
      case NotificationType.comment:
        return Colors.amber[700]!;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.mention:
        return Colors.purple;
      case NotificationType.system:
        return AppTheme.primaryColor;
    }
  }

  static IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment_outlined;
      case NotificationType.follow:
        return Icons.person_add_outlined;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }
}
