import 'dart:async';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IsLogin extends StatefulWidget {
  const IsLogin({super.key});

  @override
  State<IsLogin> createState() => _IsLoginState();
}

class _IsLoginState extends State<IsLogin> with SingleTickerProviderStateMixin {
  bool _isChecking = true;
  bool _redirecting = false;

  // Animation controller and animations for splash effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animation
    _animationController.forward();

    // Delay a bit to let the widget tree initialize and show splash for 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        checkAuthAndRedirect();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkAuthAndRedirect() async {
    if (_redirecting) return; // Prevent multiple redirects
    _redirecting = true;

    setState(() {
      _isChecking = true;
    });

    try {
      // Check shared preferences first for faster response
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      debugPrint('IsLogin: SharedPreferences isLoggedIn = $isLoggedIn');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (isLoggedIn) {
        // User was logged in according to SharedPrefs, try to load user data
        await authProvider.initialize();

        // Double check authentication status
        if (authProvider.isAuthenticated) {
          debugPrint('IsLogin: User is authenticated. Navigating to home.');

          if (mounted) {
            // Use pushReplacement to ensure no going back to splash screen
            await Future.delayed(const Duration(
                milliseconds: 300)); // Small delay to allow provider to update
            context.go('/');
            return;
          }
        } else {
          debugPrint(
              'IsLogin: User was logged in according to SharedPrefs but auth provider says not authenticated.');
        }
      }

      // If we get here, either SharedPrefs showed not logged in,
      // or the auth provider couldn't confirm authentication
      await authProvider.initialize();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        debugPrint(
            'IsLogin: After initialize, user is authenticated. Navigating to home.');
        // Use pushReplacement to ensure no going back to splash screen
        context.go('/');
      } else {
        debugPrint(
            'IsLogin: User is not authenticated. Navigating to registration.');
        context.go('/register');
      }
    } catch (e) {
      debugPrint('IsLogin: Error in auth check: $e');
      if (mounted) {
        context.go('/register');
      }
    } finally {
      _redirecting = false;
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background elements
          Positioned(
            top: -100.h,
            left: -50.w,
            child: Container(
              height: 250.h,
              width: 250.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80.h,
            right: -30.w,
            child: Container(
              height: 200.h,
              width: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.15),
              ),
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo with gradient border instead of filled background
                        Container(
                          height: 120.h,
                          width: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent, // Transparent background
                            gradient: null, // Remove the fill gradient
                            border: const GradientBoxBorder(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.accentColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              width: 3.0, // Border width
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/logo.png",
                              height:
                                  80.h, // Increased size for better visibility
                              width:
                                  80.w, // Increased size for better visibility
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // App name
                        Text(
                          'Achno',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Tagline
                        Text(
                          'Connect with experts nearby',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),

                        SizedBox(height: 50.h),

                        // Loading indicator
                        SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                            strokeWidth: 3.w,
                          ),
                        ),
                      ],
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
}

// Add this custom Border class to support gradient borders - with required methods implemented
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  BoxBorder scale(double t) {
    return GradientBoxBorder(
      gradient: gradient,
      width: width * t,
    );
  }

  // Add missing getter implementations
  @override
  BorderSide get top => BorderSide(width: width);

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  BorderSide get left => BorderSide(width: width);

  @override
  BorderSide get right => BorderSide(width: width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (width <= 0.0) return;

    final Paint paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    if (shape == BoxShape.circle) {
      if (rect.width != rect.height) {
        // If the box is not actually a circle, draw an oval instead
        final Rect adjusted = Rect.fromCenter(
          center: rect.center,
          width: rect.width - width,
          height: rect.height - width,
        );

        final path = Path()..addOval(adjusted);
        paint.shader = gradient.createShader(rect);
        canvas.drawPath(path, paint);
      } else {
        // Draw a perfect circle
        final double radius = (rect.width / 2) - (width / 2);
        paint.shader = gradient.createShader(rect);
        canvas.drawCircle(rect.center, radius, paint);
      }
    } else {
      // For rounded rectangles
      final RRect rrect =
          borderRadius?.toRRect(rect) ?? RRect.fromRectXY(rect, 0, 0);
      final RRect inner = rrect.deflate(width / 2);

      final Path path = Path()..addRRect(inner);
      paint.shader = gradient.createShader(rect);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool get isUniform => true;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return null;
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    return null;
  }
}
