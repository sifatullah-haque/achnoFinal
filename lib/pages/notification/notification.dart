import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math' as math;
import 'package:achno/models/notification_model.dart';
import 'package:achno/services/notification_service.dart';
import 'package:achno/config/theme.dart';
import 'dart:ui';
import 'package:achno/l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final List<NotificationModel> _allNotifications = [];
  final NotificationService _notificationService = NotificationService();

  // Stream subscription for real-time updates
  Stream<List<NotificationModel>>? _notificationsStream;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup real-time notifications stream
    _notificationsStream = _notificationService.getNotificationsStream();

    // Also fetch initial notifications
    _fetchNotifications();

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

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the stream to get notifications instead of fetchNotifications
      final notifications =
          await _notificationService.getNotificationsStream().first;

      setState(() {
        _allNotifications.clear();
        _allNotifications.addAll(notifications);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load notifications'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    return _fetchNotifications();
  }

  Future<void> _sendTestNotification() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sendingTestNotification),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );

      // Send test push notification - TEMPORARILY DISABLED
      // await _notificationService.sendTestPushNotification();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.testNotificationSent),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSendTestNotification}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _sendTestNotification,
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
                      builder: (context) => _buildOptionsSheet(context),
                    );
                  },
                ),
              ],
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
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle error state
                if (snapshot.hasError) {
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
                          l10n.failedToLoadNotifications,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshNotifications,
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  );
                }

                // Get notifications from stream or use the cached ones
                final notifications = snapshot.data ?? _allNotifications;

                // Show empty state if no notifications
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                // Show the list of notifications
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
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

  Widget _buildNotificationItem(NotificationModel notification, int index) {
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
        setState(() {
          _allNotifications.removeWhere((n) => n.id == notification.id);
        });
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
              _buildLeadingAvatar(notification),
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
                          _getNotificationTypeText(notification.type),
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
          trailing: _buildActionButton(notification),
          onTap: () {
            _handleNotificationTap(notification);
          },
          onLongPress: () {
            _showNotificationOptions(notification);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  String _getNotificationTypeText(NotificationType type) {
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

  Color _getNotificationAccentColor(NotificationType type) {
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

  Widget _buildLeadingAvatar(NotificationModel notification) {
    final accentColor = _getNotificationAccentColor(notification.type);

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

  Widget? _buildActionButton(NotificationModel notification) {
    final l10n = AppLocalizations.of(context);
    final accentColor = _getNotificationAccentColor(notification.type);

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

  IconData _getNotificationTypeIcon(NotificationType type) {
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

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    _notificationService.markNotificationAsRead(notification.id);

    setState(() {
      final index =
          _allNotifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _allNotifications[index] = notification.copyWith(isRead: true);
      }
    });

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat with this sender
        // if (notification.relatedItemId != null) {
        //   // relatedItemId contains the conversation ID for messages
        //   GoRouter.of(context).push(
        //     '/chat/${notification.relatedItemId}',
        //     extra: {
        //       'contactName': notification.senderName,
        //       'contactAvatar': notification.senderAvatar,
        //       'contactId': notification.senderId,
        //     },
        //   );
        // }
        break;
      case NotificationType.like:
      case NotificationType.comment:
        // Navigate to the post that was liked/commented on
        // if (notification.relatedItemId != null) {
        //   GoRouter.of(context).push('/post/${notification.relatedItemId}');
        // }
        break;
      case NotificationType.follow:
        // Navigate to follower's profile
        // if (notification.senderId != null) {
        //   GoRouter.of(context).push('/profile/${notification.senderId}');
        // }
        break;
      case NotificationType.mention:
        // Navigate to the comment where user was mentioned
        // if (notification.relatedItemId != null) {
        //   GoRouter.of(context).push('/post/${notification.relatedItemId}');
        // }
        break;
      case NotificationType.system:
        // Show full system message
        _showSystemNotificationDetails(notification);
        break;
    }
  }

  void _showSystemNotificationDetails(NotificationModel notification) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(NotificationModel notification) {
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

                        if (notification.isRead) {
                          // This would require a method like markAsUnread in your service
                          // For now we'll just update the local state
                        } else {
                          _notificationService
                              .markNotificationAsRead(notification.id);
                        }

                        setState(() {
                          final index = _allNotifications
                              .indexWhere((n) => n.id == notification.id);
                          if (index != -1) {
                            _allNotifications[index] = notification.copyWith(
                                isRead: !notification.isRead);
                          }
                        });
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
                        _notificationService
                            .deleteNotification(notification.id);
                        setState(() {
                          _allNotifications
                              .removeWhere((n) => n.id == notification.id);
                        });
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

  Widget _buildOptionsSheet(BuildContext context) {
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
                    _notificationService.markAllNotificationsAsRead();
                    setState(() {
                      for (int i = 0; i < _allNotifications.length; i++) {
                        if (!_allNotifications[i].isRead) {
                          _allNotifications[i] =
                              _allNotifications[i].copyWith(isRead: true);
                        }
                      }
                    });
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
                              // _notificationService.deleteAllNotifications(); // TEMPORARILY DISABLED
                              setState(() {
                                _allNotifications.clear();
                              });
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

  Widget _buildOptionItem({
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
}
