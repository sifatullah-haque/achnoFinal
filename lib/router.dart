import 'package:achno/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:achno/pages/profile/settings_page.dart';
import 'package:achno/pages/auth/login.dart';
import 'package:achno/pages/auth/register.dart';
import 'package:achno/pages/auth/isLogin.dart';
import 'package:achno/pages/main_screen.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:achno/pages/chat/messageDetails.dart';

// Define your routes
final appRouter = GoRouter(
  navigatorKey: navigatorKey, // Use the global navigator key
  initialLocation: '/is-login', // Changed back to is-login as our initial route
  routes: [
    // Auth check route with splash screen
    GoRoute(
      path: '/is-login',
      builder: (context, state) => const IsLogin(),
    ),

    GoRoute(
      path: '/',
      builder: (context, state) {
        // Extract initialIndex from extra if provided
        final params = state.extra as Map<String, dynamic>?;
        final initialIndex = params?['initialIndex'] ?? 0;
        return MainScreen(initialIndex: initialIndex);
      },
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/mainScreen',
      builder: (context, state) {
        // Extract initialIndex from extra if provided
        final params = state.extra as Map<String, dynamic>?;
        final initialIndex = params?['initialIndex'] ?? 0;
        return MainScreen(initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const Register(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId'];
        final params = state.extra as Map<String, dynamic>?;

        debugPrint('Router: Conversation ID from path: $conversationId');
        debugPrint('Router: Extra params: $params');

        // Validate conversation ID
        if (conversationId == null || conversationId.isEmpty) {
          debugPrint('Router: Invalid conversation ID');
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Invalid conversation'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => GoRouter.of(context).go('/'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        debugPrint(
            'Router: Creating MessageDetails with conversationId: $conversationId');
        return MessageDetails(
          conversationId: conversationId,
          contactName: params?['contactName'] ?? 'Unknown',
          contactAvatar: params?['contactAvatar'],
          contactId: params?['contactId'],
          relatedPost: params?['relatedPost'],
        );
      },
    ),
  ],

  // Redirect logic for authenticated routes
  redirect: (BuildContext context, GoRouterState state) async {
    // Don't redirect the is-login page
    if (state.matchedLocation == '/is-login') {
      return null;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Get the current path
    final String currentPath = state.matchedLocation;

    final isAuthRoute = currentPath == '/login' || currentPath == '/register';

    if (authProvider.isAuthenticated || isLoggedIn) {
      // If user is authenticated and tries to access login or register, redirect to home
      if (isAuthRoute) {
        debugPrint(
            'Router redirect: Authenticated user trying to access auth route, redirecting to home');
        return '/';
      }
    }

    return null; // No redirection needed
  },

  // Error page builder
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('The page you requested was not found.',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
