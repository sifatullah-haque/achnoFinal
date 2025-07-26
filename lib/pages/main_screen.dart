import 'package:achno/pages/addPost/addPost.dart';
import 'package:flutter/material.dart';
import 'package:achno/pages/homepage/homepage.dart';
import 'package:achno/pages/chat/messages.dart';
import 'package:achno/pages/notification/notification.dart';
import 'package:achno/pages/profile/mainProfile/profile.dart';
import 'package:achno/pages/buttonNavigator/buttonNavigator.dart';
import 'package:achno/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex; // Add parameter for initial tab index

  const MainScreen(
      {super.key, this.initialIndex = 0}); // Default to 0 (homepage)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Initialize selected index from widget parameter
    _selectedIndex = widget.initialIndex;

    // Initialize notification listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initializeListeners();
    });
  }

  // Update _pages to use a method instead of a constant list
  List<Widget> get _pages => [
        Homepage(onNavigateToAddPost: () => _navigateToAddTab(2)),
        const Messages(),
        const Addpost(),
        const NotificationScreen(),
        const Profile(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Mark notifications/messages as viewed when navigating to those tabs
    final notificationProvider = context.read<NotificationProvider>();
    if (index == 1) {
      // Messages tab
      notificationProvider.markMessagesAsRead();
    } else if (index == 3) {
      // Notifications tab
      notificationProvider.markNotificationsAsRead();
    }
  }

  // Add a method to navigate to a specific tab
  void _navigateToAddTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: CustomBottomNavigationBar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
            unreadMessageCount: notificationProvider.unreadMessageCount,
            unreadNotificationCount:
                notificationProvider.unreadNotificationCount,
          ),
        );
      },
    );
  }
}
