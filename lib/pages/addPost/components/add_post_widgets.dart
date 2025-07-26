import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:ui';
import 'package:achno/config/theme.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'add_post_controller.dart';

class AddPostWidgets {
  // Voice recording section
  static Widget buildVoiceRecordingSection(
    BuildContext context,
    AddPostController controller,
    String recordVoice,
  ) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.darkAccentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: Colors.white,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                recordVoice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
              Text(
                ' (${l10n.maxOneMinute ?? 'Max 1 minute'})',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (controller.micPermissionStatus != PermissionStatus.granted)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => controller.requestMicrophonePermission(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          l10n.allowMicPermission ?? 'Allow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Audio waveform visualization
          if (controller.isRecording && controller.audioWaveform.isNotEmpty)
            Column(
              children: [
                Container(
                  height: 40.h,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      controller.audioWaveform.length,
                      (index) => _buildWaveformBar(
                          controller.audioWaveform[index], index),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: controller.recordingDuration /
                        controller.maxRecordingDuration,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      controller.recordingDuration >=
                              controller.maxRecordingDuration * 0.8
                          ? Colors.red.shade300
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),

          if (controller.recordedAudioPath != null && !controller.isRecording)
            // Display recorded audio player
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      controller.isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 20.w,
                    ),
                    onPressed: controller.isPlaying
                        ? controller.stopPlaying
                        : controller.playRecording,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.audioRecording ?? 'Audio recording',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          controller
                              .formatDuration(controller.recordingDuration),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white, size: 18.w),
                    onPressed: controller.deleteRecording,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )
          else if (controller.micPermissionStatus != PermissionStatus.granted)
            // Permission denied message
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                children: [
                  Icon(
                    Icons.mic_off,
                    size: 32.w,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.microphoneAccessNeeded ?? 'Microphone access needed',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (!controller.recorderInitialized)
            // Initialization failed
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 28.w,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.failedToInitializeRecorder ??
                        'Failed to initialize recorder',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => controller.initializeRecorder(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.tryAgain ?? 'Try Again',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            )
          else
            // Record button with pulse animation
            Center(
              child: Column(
                children: [
                  _buildPulseAnimation(
                    isRecording: controller.isRecording,
                    child: GestureDetector(
                      onTap: controller.isRecording
                          ? controller.stopRecording
                          : controller.startRecording,
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.isRecording
                              ? Colors.red
                              : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: (controller.isRecording
                                      ? Colors.red
                                      : Colors.white)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          controller.isRecording ? Icons.stop : Icons.mic,
                          color: controller.isRecording
                              ? Colors.white
                              : AppTheme.primaryColor,
                          size: 30.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    controller.isRecording
                        ? controller
                            .formatDuration(controller.recordingDuration)
                        : l10n.tapToRecord ?? 'Tap to record',
                    style: TextStyle(
                      fontSize: controller.isRecording ? 14.sp : 12.sp,
                      fontWeight: controller.isRecording
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  if (controller.isRecording)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        l10n.tapToStop ?? 'Tap to stop',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  // Duration selector
  static Widget buildDurationSelector(
    BuildContext context,
    AddPostController controller,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.postDuration ?? "Post Duration",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.durationOptions.map((option) {
                    final isSelected =
                        controller.selectedDuration == option['value'];
                    final labelKey = option['labelKey'] as String;

                    String localizedLabel;
                    switch (labelKey) {
                      case 'unlimited':
                        localizedLabel = l10n.unlimited ?? 'Unlimited';
                        break;
                      case 'hours48':
                        localizedLabel = l10n.hours48 ?? '48 Hours';
                        break;
                      case 'days7':
                        localizedLabel = l10n.days7 ?? '7 Days';
                        break;
                      case 'days30':
                        localizedLabel = l10n.days30 ?? '30 Days';
                        break;
                      default:
                        localizedLabel = labelKey;
                    }

                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      child: GestureDetector(
                        onTap: () {
                          controller
                              .setSelectedDuration(option['value'] as String);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white70
                                        : AppTheme.textSecondaryColor,
                                size: 14.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                localizedLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : isDarkMode
                                          ? Colors.white70
                                          : AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Message input
  static Widget buildMessageInput(
    BuildContext context,
    AddPostController controller,
    String messageHint,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                messageHint,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: controller.messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.addOptionalDetails ??
                      "Add optional details (not required)",
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4),
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 10.w,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // City selector
  static Widget buildCitySelector(
    BuildContext context,
    AddPostController controller,
    String cityHint,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 14.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    cityHint,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: controller.cityController,
                decoration: InputDecoration(
                  hintText: l10n.typeToSearch ?? 'Type to search',
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 11.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 6.h,
                    horizontal: 8.w,
                  ),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 12.sp),
                onChanged: controller.searchPlaces,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.cityRequired ?? 'City required';
                  }
                  return null;
                },
              ),
              if (controller.placePredictions.isNotEmpty)
                Container(
                  height: 100.h,
                  margin: EdgeInsets.only(top: 6.h),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: controller.placePredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = controller.placePredictions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4.r),
                          onTap: () => controller.selectPlace(prediction),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4.h, horizontal: 4.w),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: 12.w,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction.description.split(',').first,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        prediction.description
                                            .split(',')
                                            .skip(1)
                                            .join(',')
                                            .trim(),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white54
                                              : Colors.black45,
                                          fontSize: 9.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Activity selection
  static Widget buildActivitySelection(
    BuildContext context,
    AddPostController controller,
    String activityLabel,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    activityLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Grid of main activities with icons
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                ),
                itemCount: controller.mainActivities.length,
                itemBuilder: (context, index) {
                  final activity = controller.mainActivities[index];
                  final localizedName = controller.getLocalizedActivityName(
                    activity['name'],
                    activity['key'],
                    l10n,
                  );
                  return _buildActivityCard(
                    activity['name'],
                    localizedName,
                    activity['icon'],
                    isDarkMode,
                    controller,
                  );
                },
              ),

              SizedBox(height: 12.h),

              // Dropdown for additional activities
              DropdownButtonFormField<String>(
                value: controller.additionalActivities.any(
                  (activity) => activity['name'] == controller.selectedActivity,
                )
                    ? controller.selectedActivity
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.otherActivities ?? "Other Activities",
                  prefixIcon: Icon(
                    Icons.add_circle_outline,
                    size: 18.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 10.w,
                  ),
                  isDense: true,
                ),
                items: controller.additionalActivities
                    .map((Map<String, String> activity) {
                  final localizedName = controller.getLocalizedActivityName(
                    activity['name']!,
                    activity['key'],
                    l10n,
                  );
                  return DropdownMenuItem<String>(
                    value: activity['name'],
                    child: Text(
                      localizedName,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  controller.setSelectedActivity(newValue);
                },
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 22.w,
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                hint: Text(
                  l10n.selectOtherActivity ?? "Select other activity",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  static Widget _buildWaveformBar(double amplitude, int index) {
    final minHeight = 3.h;
    final maxHeight = 25.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 3.w,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(index == 29 ? 1.0 : 0.5 + (index / 60)),
        borderRadius: BorderRadius.circular(1.5.r),
      ),
    );
  }

  static Widget _buildPulseAnimation(
      {required bool isRecording, required Widget child}) {
    if (!isRecording) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.05),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget _buildActivityCard(
    String activityName,
    String displayName,
    IconData icon,
    bool isDarkMode,
    AddPostController controller,
  ) {
    final isSelected = controller.selectedActivity == activityName;

    return GestureDetector(
      onTap: () {
        controller.setSelectedActivity(activityName);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.w,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.textPrimaryColor),
            ),
            SizedBox(height: 4.h),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
