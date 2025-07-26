import 'package:flutter/material.dart';

/// Global navigation key to be used for navigation without context
/// This is used by services like NotificationService for navigation outside of widgets
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
