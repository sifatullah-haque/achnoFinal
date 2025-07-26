// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'dart:ui';
// import 'package:achno/config/theme.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:achno/models/post_model.dart'; // Import PostType from here

// class HomepageGlassComponents {
//   // Glass AppBar component
//   static PreferredSizeWidget buildGlassAppBar(
//     BuildContext context, {
//     VoidCallback? onFilterPressed,
//   }) {
//     return PreferredSize(
//       preferredSize: Size.fromHeight(60.h),
//       child: ClipRRect(
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(24.r),
//           bottomRight: Radius.circular(24.r),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: AppBar(
//             backgroundColor: Colors.white.withOpacity(0.8),
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(24.r),
//                 bottomRight: Radius.circular(24.r),
//               ),
//             ),
//             shadowColor: Colors.grey.withOpacity(0.2),
//             surfaceTintColor: Colors.transparent,
//             flexibleSpace: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(24.r),
//                   bottomRight: Radius.circular(24.r),
//                 ),
//                 border: Border(
//                   bottom: BorderSide(
//                     color: Colors.black.withOpacity(0.05),
//                     width: 1,
//                   ),
//                 ),
//               ),
//             ),
//             title: Image.asset(
//               'assets/logo.png',
//               height: 40.h,
//               fit: BoxFit.cover,
//             ),
//             centerTitle: true,
//             leading: IconButton(
//               icon: Icon(
//                 Icons.filter_list,
//                 color: AppTheme.textSecondaryColor,
//               ),
//               onPressed: onFilterPressed ?? () {},
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Glass search bar component
//   static Widget buildGlassSearchBar({
//     required BuildContext context,
//     required VoidCallback onTap,
//     TextEditingController? controller,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16.w),
//       height: 50.h,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(
//           color: Colors.grey.withOpacity(0.2),
//           width: 1,
//         ),
//         borderRadius: BorderRadius.circular(12.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.search,
//             color: Colors.grey[400],
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               enabled: false,
//               decoration: InputDecoration(
//                 hintText: 'What are you looking for?',
//                 hintStyle: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: 14.sp,
//                 ),
//                 border: InputBorder.none,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Glass filter bottom sheet
//   static Widget buildGlassFilterBottomSheet({
//     required BuildContext context,
//     required StateSetter setModalState,
//     required String? selectedCity,
//     required String? selectedActivity,
//     required PostType? selectedPostType,
//     required int? selectedDistance,
//     required List<String> cities,
//     required List<String> activities,
//     required List<int> distanceOptions,
//     required Function(String?) onCityChanged,
//     required Function(String?) onActivityChanged,
//     required Function(PostType?) onPostTypeChanged,
//     required Function(int?) onDistanceChanged,
//     required VoidCallback onClearAll,
//     required VoidCallback onApply,
//   }) {
//     final l10n = AppLocalizations.of(context)!;

//     return Container(
//       height: MediaQuery.of(context).size.height * 0.6,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24.r),
//           topRight: Radius.circular(24.r),
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24.r),
//           topRight: Radius.circular(24.r),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.95),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(24.r),
//                 topRight: Radius.circular(24.r),
//               ),
//             ),
//             padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Handle bar
//                 Center(
//                   child: Container(
//                     width: 40.w,
//                     height: 4.h,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2.r),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16.h),

//                 // Title with close button
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       l10n.filters,
//                       style: TextStyle(
//                         fontSize: 20.sp,
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.textPrimaryColor,
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close, size: 20.r),
//                       padding: EdgeInsets.zero,
//                       constraints: BoxConstraints(),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16.h),

//                 // Post Type Filter
//                 Text(
//                   l10n.postType,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimaryColor,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Row(
//                   children: [
//                     _buildTypeFilterChip(
//                       PostType.request,
//                       l10n.request,
//                       selectedPostType,
//                       onPostTypeChanged,
//                       setModalState,
//                     ),
//                     SizedBox(width: 8.w),
//                     _buildTypeFilterChip(
//                       PostType.offer,
//                       l10n.offer,
//                       selectedPostType,
//                       onPostTypeChanged,
//                       setModalState,
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16.h),

//                 // City Filter
//                 Text(
//                   l10n.city,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimaryColor,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Container(
//                   height: 40.h,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8.r),
//                     border: Border.all(
//                       color: Colors.grey.withOpacity(0.3),
//                     ),
//                   ),
//                   padding: EdgeInsets.symmetric(horizontal: 12.w),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       isExpanded: true,
//                       hint: Text('Select City'),
//                       value: selectedCity,
//                       items: cities.map((String city) {
//                         return DropdownMenuItem<String>(
//                           value: city == 'All' ? null : city,
//                           child: Text(
//                             city,
//                             style: TextStyle(fontSize: 14.sp),
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: onCityChanged,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16.h),

//                 // Distance filters
//                 if (selectedCity != null && selectedCity != 'All')
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Distance',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.textPrimaryColor,
//                         ),
//                       ),
//                       SizedBox(height: 8.h),
//                       Row(
//                         children: distanceOptions.map((distance) {
//                           return Padding(
//                             padding: EdgeInsets.only(right: 8.w),
//                             child: _buildDistanceFilterChipForModal(
//                               distance,
//                               selectedDistance,
//                               onDistanceChanged,
//                               setModalState,
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                       SizedBox(height: 8.h),
//                     ],
//                   ),

//                 // Activity Filter
//                 Text(
//                   l10n.activity,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.textPrimaryColor,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),

//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Wrap(
//                       spacing: 8.w,
//                       runSpacing: 8.h,
//                       children: activities
//                           .map((activity) => _buildActivityFilterChip(
//                                 activity,
//                                 selectedActivity,
//                                 onActivityChanged,
//                                 setModalState,
//                               ))
//                           .toList(),
//                     ),
//                   ),
//                 ),

//                 SizedBox(height: 16.h),

//                 // Apply and Clear buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: onClearAll,
//                         style: OutlinedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12.h),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                           side: BorderSide(
//                             color: AppTheme.primaryColor,
//                           ),
//                         ),
//                         child: Text(
//                           l10n.clearAll,
//                           style: TextStyle(
//                             color: AppTheme.primaryColor,
//                             fontSize: 14.sp,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 12.w),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: onApply,
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12.h),
//                           backgroundColor: AppTheme.primaryColor,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                         ),
//                         child: Text(
//                           l10n.apply,
//                           style: TextStyle(fontSize: 14.sp),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Glass location indicator
//   static Widget buildLocationIndicator({
//     required String userHomeCity,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             spreadRadius: 0,
//           ),
//         ],
//         border: Border.all(
//           color: AppTheme.primaryColor.withOpacity(0.2),
//           width: 1.0,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.location_on,
//             size: 18.w,
//             color: AppTheme.primaryColor,
//           ),
//           SizedBox(width: 6.w),
//           Text(
//             'Your location: $userHomeCity',
//             style: TextStyle(
//               fontSize: 13.sp,
//               fontWeight: FontWeight.w500,
//               color: AppTheme.textPrimaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper methods for filter chips
//   static Widget _buildTypeFilterChip(
//     PostType type,
//     String label,
//     PostType? selectedPostType,
//     Function(PostType?) onPostTypeChanged,
//     StateSetter setModalState,
//   ) {
//     final isSelected = selectedPostType == type;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setModalState(() {
//             onPostTypeChanged(isSelected ? null : type);
//           });
//         },
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 8.h),
//           decoration: BoxDecoration(
//             color: isSelected
//                 ? AppTheme.primaryColor
//                 : Colors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8.r),
//             border: Border.all(
//               color: isSelected
//                   ? AppTheme.primaryColor
//                   : Colors.grey.withOpacity(0.5),
//             ),
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
//               fontWeight: FontWeight.w500,
//               fontSize: 14.sp,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   static Widget _buildDistanceFilterChipForModal(
//     int distance,
//     int? selectedDistance,
//     Function(int?) onDistanceChanged,
//     StateSetter setModalState,
//   ) {
//     final isSelected = selectedDistance == distance;

//     return ChoiceChip(
//       label: Text('$distance km'),
//       selected: isSelected,
//       onSelected: (selected) {
//         setModalState(() {
//           onDistanceChanged(selected ? distance : null);
//         });
//       },
//       backgroundColor: Colors.grey.withOpacity(0.1),
//       selectedColor: AppTheme.primaryColor.withOpacity(0.8),
//       labelStyle: TextStyle(
//         color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
//         fontSize: 12.sp,
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: VisualDensity.compact,
//     );
//   }

//   static Widget _buildActivityFilterChip(
//     String activity,
//     String? selectedActivity,
//     Function(String?) onActivityChanged,
//     StateSetter setModalState,
//   ) {
//     final isSelected = selectedActivity == activity;

//     return ChoiceChip(
//       label: Text(
//         activity,
//         style: TextStyle(
//           fontSize: 12.sp,
//           color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
//         ),
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         setModalState(() {
//           onActivityChanged(selected ? activity : null);
//           if (activity == 'All') onActivityChanged(null);
//         });
//       },
//       backgroundColor: Colors.grey.withOpacity(0.1),
//       selectedColor: AppTheme.primaryColor.withOpacity(0.8),
//       padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: VisualDensity.compact,
//     );
//   }
// }
