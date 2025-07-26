import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:achno/pages/notification/components/notification_controller.dart';
import 'package:achno/pages/notification/components/notification_widgets.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView>
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = NotificationController();
        controller.initialize();
        return controller;
      },
      child: Consumer<NotificationController>(
        builder: (context, controller, child) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: NotificationWidgets.buildAppBar(context, controller)
                as PreferredSizeWidget,
            body: Stack(
              children: [
                // Background
                NotificationWidgets.buildBackground(),

                // Content
                SafeArea(
                  child: StreamBuilder(
                    stream: controller.notificationsStream,
                    builder: (context, snapshot) {
                      // Handle loading state
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          controller.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Handle error state
                      if (snapshot.hasError ||
                          controller.errorMessage.isNotEmpty) {
                        return NotificationWidgets.buildErrorState(
                          context,
                          controller.errorMessage.isNotEmpty
                              ? controller.errorMessage
                              : 'Failed to load notifications',
                          () {
                            // Show a helpful message about Firestore permissions
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please check FIREBASE_SETUP.md for instructions to fix Firestore permissions'),
                                duration: Duration(seconds: 5),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            controller.refreshNotifications();
                          },
                        );
                      }

                      // Get notifications from stream or use the cached ones
                      final notifications =
                          snapshot.data ?? controller.allNotifications;

                      // Show empty state if no notifications
                      if (notifications.isEmpty) {
                        return NotificationWidgets.buildEmptyState(
                          context,
                          _fadeAnimation,
                        );
                      }

                      // Show the list of notifications
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: controller.refreshNotifications,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return NotificationWidgets.buildNotificationItem(
                                context,
                                notification,
                                index,
                                controller,
                              );
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
        },
      ),
    );
  }
}
