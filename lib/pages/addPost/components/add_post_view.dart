import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:achno/config/theme.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'add_post_controller.dart';
import 'add_post_widgets.dart';
import 'add_post_states.dart';

class AddPostView extends StatefulWidget {
  final AddPostController? controller;

  const AddPostView({
    super.key,
    this.controller,
  });

  @override
  State<AddPostView> createState() => _AddPostViewState();
}

class _AddPostViewState extends State<AddPostView>
    with SingleTickerProviderStateMixin {
  late AddPostController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AddPostController();

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
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Fallback for localization
    final addPostTitle = l10n.addPost ?? 'Add Post';
    final messageHint = l10n.messageHint ?? 'Write your message...';
    final cityHint = l10n.cityHint ?? 'Select city';
    final activityLabel = l10n.activityLabel ?? 'Activity';
    final recordVoice = l10n.recordVoice ?? 'Record voice message';
    final postButtonLabel = l10n.postButtonLabel ?? 'Post';

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : Colors.white.withOpacity(0.8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                shadowColor: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                surfaceTintColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  addPostTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                centerTitle: true,
                automaticallyImplyLeading: false,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background patterns
            _buildBackgroundPatterns(),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: 8.h,
                    left: 16.w,
                    right: 16.w,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Consumer<AddPostController>(
                    builder: (context, controller, child) {
                      return Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),

                            // Voice recording section
                            AddPostWidgets.buildVoiceRecordingSection(
                              context,
                              controller,
                              recordVoice,
                            ),

                            SizedBox(height: 10.h),

                            // Duration selector
                            AddPostWidgets.buildDurationSelector(
                              context,
                              controller,
                            ),

                            SizedBox(height: 10.h),

                            // Message input
                            AddPostWidgets.buildMessageInput(
                              context,
                              controller,
                              messageHint,
                            ),

                            SizedBox(height: 10.h),

                            // City selector
                            AddPostWidgets.buildCitySelector(
                              context,
                              controller,
                              cityHint,
                            ),

                            SizedBox(height: 10.h),

                            // Activity selection
                            AddPostWidgets.buildActivitySelection(
                              context,
                              controller,
                              activityLabel,
                            ),

                            // Error message
                            if (controller.errorMessage.isNotEmpty)
                              AddPostStates.buildErrorMessage(
                                context,
                                controller.errorMessage,
                              ),

                            SizedBox(height: 16.h),

                            // Post Button
                            _buildPostButton(
                                context, controller, postButtonLabel),

                            SizedBox(height: 16.h),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPatterns() {
    return Stack(
      children: [
        Positioned(
          top: -70.h,
          left: -40.w,
          child: Container(
            width: 150.w,
            height: 150.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -60.h,
          right: -30.w,
          child: Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.09),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: 30.w,
          child: Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkAccentColor.withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          left: 40.w,
          child: Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostButton(BuildContext context, AddPostController controller,
      String postButtonLabel) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 46.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.darkAccentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _handleSubmitPost(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 10.h),
        ),
        child: controller.isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              )
            : Text(
                postButtonLabel,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmitPost(
      BuildContext context, AddPostController controller) async {
    final l10n = AppLocalizations.of(context);

    final success = await controller.submitPost(context);

    if (success && mounted) {
      // Reset form
      controller.resetForm();

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
                      size: 48.r,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.postSuccessfullySubmitted ??
                        'Post Successfully Submitted',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.postSubmittedAwaitingApproval ??
                        'Your post has been submitted and is awaiting admin approval. It will appear on the homepage once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (mounted) {
                        context.go("/mainScreen", extra: {
                          'initialIndex': 0,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      l10n.continue_ ?? 'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
