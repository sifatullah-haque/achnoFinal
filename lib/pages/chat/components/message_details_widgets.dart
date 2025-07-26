import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/pages/chat/components/message_details_controller.dart';
import 'package:achno/models/post_model.dart';
import 'dart:math' as math;

class MessageDetailsWidgets {
  // Loading state
  static Widget buildLoadingState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.loadingMessages ?? 'Loading messages...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Date divider
  static Widget buildDateDivider(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = l10n.today ?? 'Today';
    } else if (messageDate == yesterday) {
      dateText = l10n.yesterday ?? 'Yesterday';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // Message bubble
  static Widget buildMessageBubble(
    ChatMessage message,
    bool isMe,
    MessageDetailsController controller,
    AnimationController audioVisualizationController,
    BuildContext context,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.75.sw,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8.h,
            left: isMe ? 50.w : 0,
            right: isMe ? 0 : 50.w,
          ),
          decoration: BoxDecoration(
            color: message.type == MessageType.image
                ? Colors.transparent
                : isMe
                    ? AppTheme.primaryColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(16.r).copyWith(
              bottomRight:
                  isMe ? const Radius.circular(0) : Radius.circular(16.r),
              bottomLeft:
                  isMe ? Radius.circular(16.r) : const Radius.circular(0),
            ),
            boxShadow: message.type == MessageType.image
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: message.type == MessageType.audio ||
                    isMe ||
                    message.type == MessageType.image
                ? null
                : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message content
              if (message.type == MessageType.image)
                buildImageMessage(context, message, isMe)
              else if (message.type == MessageType.audio)
                buildAudioMessage(
                    message, isMe, controller, audioVisualizationController)
              else
                buildTextMessage(context, message, isMe),

              // Timestamp and status
              if (message.type != MessageType.image)
                Padding(
                  padding: EdgeInsets.only(
                    right: 8.w,
                    bottom: 4.h,
                    left: 8.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      if (isMe) buildMessageStatus(message.status),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Text message
  static Widget buildTextMessage(
      BuildContext context, ChatMessage message, bool isMe) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14.sp,
          color: isMe ? Colors.white : AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  // Audio message
  static Widget buildAudioMessage(
    ChatMessage message,
    bool isMe,
    MessageDetailsController controller,
    AnimationController audioVisualizationController,
  ) {
    final isPlaying =
        controller.isPlaying && controller.currentlyPlayingId == message.id;
    final visualizationData = controller.getAudioVisualizationData(message.id);

    // Calculate progress for the visualization
    double progress = 0.0;
    try {
      if (isPlaying &&
          controller.audioPosition != null &&
          controller.audioDuration != null &&
          controller.audioDuration!.inMilliseconds > 0) {
        progress = (controller.audioPosition!.inMilliseconds /
                controller.audioDuration!.inMilliseconds)
            .clamp(0.0, 1.0);
      }
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      progress = 0.0;
    }

    return InkWell(
      onTap: () => controller.playAudio(message.id, message.content),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMe
                    ? Colors.white.withOpacity(0.2)
                    : isPlaying
                        ? Colors.red.shade100
                        : AppTheme.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: isMe
                      ? Colors.white.withOpacity(0.3)
                      : isPlaying
                          ? Colors.red.shade300
                          : AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isMe
                    ? Colors.white
                    : isPlaying
                        ? Colors.red
                        : AppTheme.primaryColor,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),

            // Audio visualization and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio visualization
                  SizedBox(
                    height: 20.h,
                    child: Row(
                      children: List.generate(
                        visualizationData.length,
                        (index) {
                          final position =
                              index / (visualizationData.length - 1);
                          final isActive = position <= progress;

                          // Apply subtle animation to make it look alive when playing
                          double heightFactor = visualizationData[index];
                          if (isPlaying && isActive) {
                            final animation = math.sin(
                                        audioVisualizationController.value *
                                                math.pi +
                                            index * 0.2) *
                                    0.15 +
                                0.85;
                            heightFactor *= animation;
                          }

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.w),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.7)
                                      : isActive && isPlaying
                                          ? Colors.red
                                          : isActive
                                              ? AppTheme.primaryColor
                                              : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                                height: 16.h * heightFactor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  // Display current time / total time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current position when playing
                      Text(
                        isPlaying && controller.audioPosition != null
                            ? formatDurationToTime(controller.audioPosition)
                            : "00:00",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Total duration
                      Text(
                        isPlaying && controller.audioDuration != null
                            ? formatDurationToTime(controller.audioDuration)
                            : message.audioDuration != null
                                ? formatSecondsToTime(message.audioDuration!)
                                : "00:00",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image message
  static Widget buildImageMessage(
      BuildContext context, ChatMessage message, bool isMe) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r).copyWith(
        bottomRight: isMe ? const Radius.circular(0) : Radius.circular(16.r),
        bottomLeft: isMe ? Radius.circular(16.r) : const Radius.circular(0),
      ),
      child: Stack(
        children: [
          // Image
          Image.network(
            message.content,
            width: 200.w,
            height: 200.h,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200.w,
                height: 200.h,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200.w,
                height: 200.h,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 32.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.failedToLoadImage ?? 'Failed to load image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Overlay with timestamp and status
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  bottomRight:
                      isMe ? const Radius.circular(0) : Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  if (isMe)
                    Icon(
                      getStatusIcon(message.status),
                      size: 12.w,
                      color: getStatusColor(message.status),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Message status
  static Widget buildMessageStatus(MessageStatus? status) {
    if (status == null) return const SizedBox();

    IconData icon;
    Color color = Colors.white70;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.error:
        icon = Icons.error_outline;
        color = Colors.red.shade300;
        break;
    }

    return Icon(
      icon,
      size: 12.w,
      color: color,
    );
  }

  // Recording view
  static Widget buildRecordingView(
    BuildContext context,
    MessageDetailsController controller,
    AnimationController audioVisualizationController,
    VoidCallback onDelete,
  ) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.isRecording
                  ? Colors.red.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
            ),
            child: Icon(
              controller.isRecording ? Icons.mic : Icons.mic_none,
              color: controller.isRecording ? Colors.red : Colors.blue,
              size: 20.w,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.isRecording
                      ? (l10n.recordingAudio ?? 'Recording audio...')
                      : (l10n.audioReadyToSend ?? 'Audio ready to send'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color: controller.isRecording ? Colors.red : Colors.blue,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      formatSecondsToTime(controller.recordingDuration),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color:
                            controller.isRecording ? Colors.red : Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 20.h,
                        child: controller.isRecording &&
                                controller.audioWaveform.isNotEmpty
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  controller.audioWaveform.length,
                                  (index) {
                                    double heightFactor =
                                        controller.audioWaveform[index];
                                    final animation = math.sin(
                                                audioVisualizationController
                                                            .value *
                                                        math.pi +
                                                    index * 0.2) *
                                            0.15 +
                                        0.85;
                                    heightFactor *= animation;

                                    return buildCompactWaveformBar(
                                        heightFactor, true);
                                  },
                                ),
                              )
                            : controller.recordingStopped
                                ? buildStaticWaveform()
                                : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Only show delete button when recording is stopped
          if (controller.recordingStopped)
            InkWell(
              onTap: onDelete,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20.w,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Compact waveform bar
  static Widget buildCompactWaveformBar(double amplitude, bool isRecording) {
    final minHeight = 2.h;
    final maxHeight = 16.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 2.w,
      height: height,
      decoration: BoxDecoration(
        color: isRecording
            ? Colors.red.withOpacity(0.7)
            : Colors.blue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }

  // Static waveform
  static Widget buildStaticWaveform() {
    final random = math.Random(42);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        15,
        (index) {
          final height = (0.3 + random.nextDouble() * 0.7) * 16.h;
          return Container(
            width: 2.w,
            height: height,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(1.r),
            ),
          );
        },
      ),
    );
  }

  // Post reference bar
  static Widget buildPostReferenceBar(
    BuildContext context,
    Post relatedPost,
    bool isDarkMode,
    VoidCallback onViewPost,
  ) {
    final l10n = AppLocalizations.of(context);

    final postTypeLabel = relatedPost.type == PostType.request
        ? (l10n.request ?? 'Request')
        : (l10n.offer ?? 'Offer');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.primaryColor.withOpacity(0.2)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: relatedPost.type == PostType.request
                  ? AppTheme.primaryColor
                  : AppTheme.accentColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              postTypeLabel,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.work_outline,
            size: 14.w,
            color: isDarkMode
                ? AppTheme.primaryColor.withOpacity(0.9)
                : AppTheme.primaryColor,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              relatedPost.activity,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : AppTheme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onViewPost,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                l10n.viewPost ?? "View Post",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static String formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  static String formatDurationToTime(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  static String formatSecondsToTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static IconData getStatusIcon(MessageStatus? status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.error:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  static Color getStatusColor(MessageStatus? status) {
    switch (status) {
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.error:
        return Colors.red.shade300;
      default:
        return Colors.white70;
    }
  }
}

// Global navigator key for accessing context in static methods
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
