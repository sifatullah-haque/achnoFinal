import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'homepage_controller.dart';

class HomepageStates {
  static Widget buildEmptyState(BuildContext context,
      HomepageController controller, VoidCallback onNavigateToAddPost) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add,
            size: 80.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noPosts,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.createFirstPost,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onNavigateToAddPost,
            icon: const Icon(Icons.add),
            label: Text(l10n.addPost),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildErrorState(
      BuildContext context, HomepageController controller) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.w,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.errorLoadingPosts,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.pleaseRetry,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => controller.refreshPosts(context),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildNoResultsState(
      BuildContext context, HomepageController controller) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              Icons.search_off,
              size: 80.w,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noMatchingResults,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.tryDifferentFilters,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.resetFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: Text(l10n.clearFilters),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
