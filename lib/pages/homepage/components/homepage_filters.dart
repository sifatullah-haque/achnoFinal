import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/models/post_model.dart';
import 'package:achno/config/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'homepage_controller.dart';

class HomepageFilters {
  static Widget buildFilterIndicator(
      BuildContext context, HomepageController controller) {
    final l10n = AppLocalizations.of(context);
    final bool hasActiveFilters = controller.selectedCity != null ||
        controller.selectedActivity != null ||
        controller.selectedPostType != null ||
        controller.selectedDistance != null;

    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    List<String> activeFilters = [];
    if (controller.selectedCity != null) {
      activeFilters.add(controller.selectedCity!);
    }
    if (controller.selectedActivity != null) {
      activeFilters.add(controller.selectedActivity!);
    }
    if (controller.selectedPostType != null) {
      activeFilters.add(controller.selectedPostType == PostType.request
          ? l10n.request
          : l10n.offer);
    }
    if (controller.selectedDistance != null) {
      if (controller.currentPosition == null) {
        activeFilters
            .add(l10n.waitingForLocation(controller.selectedDistance!));
      } else {
        activeFilters.add(l10n.kmDistance(controller.selectedDistance!));
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 18.w,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${l10n.activeFilters}: ${activeFilters.join(", ")}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: controller.resetFilters,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14.w,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDistanceFilterChip(
      BuildContext context, int distance, HomepageController controller) {
    final l10n = AppLocalizations.of(context);
    final isSelected = controller.selectedDistance == distance;

    return ChoiceChip(
      label: Text(l10n.kmDistance(distance)),
      selected: isSelected,
      onSelected: (selected) {
        controller.setSelectedDistance(selected ? distance : null);

        if (selected && controller.currentPosition == null) {
          controller.getCurrentLocation(context);
        }
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontSize: 11.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget buildDistanceFilterChipForModal(BuildContext context,
      int distance, StateSetter setModalState, HomepageController controller) {
    final l10n = AppLocalizations.of(context);
    final isSelected = controller.selectedDistance == distance;

    return ChoiceChip(
      label: Text(l10n.kmDistance(distance)),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          controller.setSelectedDistance(selected ? distance : null);
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontSize: 12.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget buildTypeFilterChip(BuildContext context, PostType type,
      String label, StateSetter setModalState, HomepageController controller) {
    final isSelected = controller.selectedPostType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            controller.setSelectedPostType(isSelected ? null : type);
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildActivityFilterChip(BuildContext context, String activity,
      StateSetter setModalState, HomepageController controller) {
    final l10n = AppLocalizations.of(context);
    final isSelected = controller.selectedActivity == activity;

    return ChoiceChip(
      label: Text(
        activity,
        style: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          controller.setSelectedActivity(selected ? activity : null);
          if (activity == l10n.all) controller.setSelectedActivity(null);
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget buildCityDropdown(BuildContext context,
      StateSetter setModalState, HomepageController controller) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(l10n.selectCity),
          value: controller.selectedCity,
          items: controller.cities.map((String city) {
            return DropdownMenuItem<String>(
              value: city == 'All' ? null : city,
              child: Text(
                city == 'All' ? l10n.all : city,
                style: TextStyle(fontSize: 14.sp),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setModalState(() {
              controller.setSelectedCity(newValue);
            });
          },
        ),
      ),
    );
  }
}
