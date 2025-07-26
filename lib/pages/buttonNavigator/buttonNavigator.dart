import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:achno/config/theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final int unreadMessageCount;
  final int unreadNotificationCount;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.unreadMessageCount = 0,
    this.unreadNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppTheme.backgroundColor;
    const navBarColor = AppTheme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: CurvedNavigationBar(
        index: selectedIndex,
        backgroundColor: backgroundColor,
        color: navBarColor,
        buttonBackgroundColor: AppTheme.darkAccentColor,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        onTap: onItemSelected,
        items: [
          const Icon(Icons.home, size: 26, color: Colors.white),
          _buildIconWithBadge(
            icon: Icons.chat_bubble,
            badgeCount: unreadMessageCount,
          ),
          const Icon(Icons.add_circle, size: 26, color: Colors.white),
          _buildIconWithBadge(
            icon: Icons.notifications,
            badgeCount: unreadNotificationCount,
          ),
          const Icon(Icons.person, size: 26, color: Colors.white),
        ],
      ),
    );
  }

  static Widget _buildIconWithBadge({
    required IconData icon,
    required int badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 26, color: Colors.white),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
