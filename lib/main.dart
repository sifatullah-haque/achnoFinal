import 'package:flutter/material.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/providers/language_provider.dart';
import 'package:achno/providers/theme_provider.dart';
import 'package:achno/router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:achno/config/navigation.dart';
import 'package:achno/services/notification_service.dart';
import 'package:achno/providers/notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Add this background message handler at the top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with a safer approach to handle potential duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If the app is already initialized, this will catch the exception
    // We can safely ignore it since we just want to make sure Firebase is initialized
    debugPrint(
        'Firebase initialization error (likely already initialized): ${e.toString()}');
  }

  // Set up the notification service with the global navigator key
  navigatorKey = rootNavigatorKey;
  await NotificationService().init();

  // Initialize FCM
  await NotificationService.initializeFCM();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false, // Make sure auth provider initializes right away
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
            Locale('fr'), // French
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Modified builder to keep LTR layout while allowing text to follow RTL
          builder: (context, child) {
            return Directionality(
              // Always use LTR for layout direction to keep UI elements in place
              textDirection: TextDirection.ltr,
              child: DirectionalityOverride(
                // Only apply RTL to text content when in Arabic
                textDirection: languageProvider.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            );
          },
          routerConfig: appRouter, // Use the existing appRouter directly
        );
      },
    );
  }
}

// Custom widget to apply text directionality without affecting layout
class DirectionalityOverride extends InheritedWidget {
  final TextDirection textDirection;

  const DirectionalityOverride({
    super.key,
    required this.textDirection,
    required super.child,
  });

  static DirectionalityOverride? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DirectionalityOverride>();
  }

  @override
  bool updateShouldNotify(DirectionalityOverride oldWidget) {
    return textDirection != oldWidget.textDirection;
  }
}
