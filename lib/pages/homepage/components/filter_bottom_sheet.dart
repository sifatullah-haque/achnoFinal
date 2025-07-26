import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/models/post_model.dart';
import 'package:achno/config/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'homepage_controller.dart';
import 'homepage_filters.dart';

class FilterBottomSheet {
  static void show(BuildContext context, HomepageController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildFilterBottomSheet(context, controller);
      },
    );
  }

  static Widget _buildFilterBottomSheet(
      BuildContext context, HomepageController controller) {
    final l10n = AppLocalizations.of(context);
    final localizedActivities = controller.getLocalizedActivities(l10n);

    return StatefulBuilder(builder: (context, setModalState) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Title with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.filters,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20.r),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Post Type Filter
                  Text(
                    l10n.postType,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      HomepageFilters.buildTypeFilterChip(
                        context,
                        PostType.request,
                        l10n.request,
                        setModalState,
                        controller,
                      ),
                      SizedBox(width: 8.w),
                      HomepageFilters.buildTypeFilterChip(
                        context,
                        PostType.offer,
                        l10n.offer,
                        setModalState,
                        controller,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // City Filter
                  Text(
                    l10n.city,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  HomepageFilters.buildCityDropdown(
                      context, setModalState, controller),
                  SizedBox(height: 16.h),

                  // Distance filters
                  if (controller.selectedCity != null &&
                      controller.selectedCity != 'All')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.distance,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: controller.distanceOptions.map((distance) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: HomepageFilters
                                  .buildDistanceFilterChipForModal(
                                context,
                                distance,
                                setModalState,
                                controller,
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),

                  // Activity Filter
                  Text(
                    l10n.activity,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: localizedActivities
                            .map((activity) =>
                                HomepageFilters.buildActivityFilterChip(context,
                                    activity, setModalState, controller))
                            .toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Apply and Clear buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              controller.resetFilters();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          child: Text(
                            l10n.clearFilters,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            l10n.apply,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
