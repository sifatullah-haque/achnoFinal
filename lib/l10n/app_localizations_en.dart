// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Achno';

  @override
  String get hello => 'Hello World';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get french => 'French';

  @override
  String get spanish => 'Spanish';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsAll => 'All';

  @override
  String get notificationsMessages => 'Messages';

  @override
  String get notificationsActivity => 'Activity';

  @override
  String get notificationsSystem => 'System';

  @override
  String get notificationEmpty => 'No Notifications';

  @override
  String get notificationEmptyMessage => 'You\'re all caught up!';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get viewProfile => 'View profile';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get clearAllNotifications => 'Clear all notifications';

  @override
  String get clearAllConfirmation =>
      'Are you sure you want to delete all notifications? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAll => 'Clear All';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get follow => 'Follow';

  @override
  String get messages => 'Messages';

  @override
  String get search => 'Search';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get startConversation => 'Start a conversation with someone';

  @override
  String get newMessage => 'New Message';

  @override
  String get addPost => 'Add Post';

  @override
  String get messageHint => 'Write your message...';

  @override
  String get cityHint => 'Select city';

  @override
  String get activityLabel => 'Activity';

  @override
  String get recordVoice => 'Record voice message';

  @override
  String get postButtonLabel => 'Post';

  @override
  String get errorSharingPost => 'Failed to share post';

  @override
  String get errorLikePost => 'Failed to update like';

  @override
  String get activeFilters => 'Active filters';

  @override
  String messageToUser(String userName) {
    return 'Message to $userName';
  }

  @override
  String get typeYourMessage => 'Type your message';

  @override
  String get send => 'Send';

  @override
  String get messageSent => 'Message sent successfully';

  @override
  String get respond => 'Respond';

  @override
  String get share => 'Share';

  @override
  String get message => 'Message';

  @override
  String get responses => 'responses';

  @override
  String get filters => 'Filters';

  @override
  String get postType => 'Post Type';

  @override
  String get request => 'Request';

  @override
  String get offer => 'Offer';

  @override
  String get city => 'City';

  @override
  String get activity => 'Activity';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get apply => 'Apply';

  @override
  String get noPosts => 'No Posts Available';

  @override
  String get createFirstPost => 'Be the first one to create a post!';

  @override
  String get errorLoadingPosts => 'Error Loading Posts';

  @override
  String get pleaseRetry => 'Please try again later';

  @override
  String get retry => 'Retry';

  @override
  String get noMatchingResults => 'No Matching Results';

  @override
  String get tryDifferentFilters => 'Try different filter options';

  @override
  String get playingAudioMessage => 'Playing audio message...';

  @override
  String get tapToPlayAudio => 'Tap to play audio message';

  @override
  String get distance => 'Distance';

  @override
  String get whatAreYouLookingFor => 'What are you looking for?';

  @override
  String yourLocation(String location) {
    return 'Your location: $location';
  }

  @override
  String get all => 'All';

  @override
  String get woodWorker => 'Wood Worker';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'Location permissions are permanently denied';

  @override
  String get failedToGetLocation => 'Failed to get location';

  @override
  String get gotLocation => 'Got location';

  @override
  String get cannotPrecalculateDistances =>
      'Cannot precalculate distances - user home city is not available';

  @override
  String get userHomeCityFetched => 'User home city fetched';

  @override
  String kmDistance(int distance) {
    return '$distance km';
  }

  @override
  String waitingForLocation(int distance) {
    return '${distance}km (waiting for location...)';
  }

  @override
  String get selectCity => 'Select City';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterName => 'Please enter your full name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number';

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get iAm => 'I am a:';

  @override
  String get client => 'Client';

  @override
  String get professional => 'Professional';

  @override
  String get chooseProfession => 'Choose your profession:';

  @override
  String get selectOtherActivity => 'Select Other Activity';

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get continue_ => 'Continue';

  @override
  String get alreadyMember => 'Already a member?';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get success => 'Success!';

  @override
  String get accountCreated => 'Account created successfully';

  @override
  String get continueToApp => 'Continue to App';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get textBio => 'Text Bio (Optional)';

  @override
  String get audioBio => 'Audio Bio';

  @override
  String get recordAudioBio => 'Record Audio Bio';

  @override
  String get audioBioAvailable => 'Audio Bio Available';

  @override
  String get recordNewAudio => 'Record New Audio';

  @override
  String get audioBioDescription =>
      'Record a short audio bio (up to 30 seconds)';

  @override
  String recording(String duration) {
    return 'Recording: $duration';
  }

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get phoneCannotBeChanged => 'Phone number cannot be changed';

  @override
  String get phone => 'Phone';

  @override
  String get professionalActivity => 'Your Professional Activity';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get mediaPermissionMessage =>
      'This feature requires permission to access your media. Please enable it in app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get pleaseEnterCity => 'Please enter your city';

  @override
  String get postDuration => 'Post Duration';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get hours48 => '48 Hours';

  @override
  String get days7 => '7 Days';

  @override
  String get days30 => '30 Days';

  @override
  String get maxOneMinute => 'Max 1 minute';

  @override
  String get allowMicPermission => 'Allow';

  @override
  String get microphoneAccessNeeded => 'Microphone access needed';

  @override
  String get failedToInitializeRecorder => 'Failed to initialize recorder';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get tapToRecord => 'Tap to record';

  @override
  String get tapToStop => 'Tap to stop';

  @override
  String get audioRecording => 'Audio recording';

  @override
  String get otherActivities => 'Other Activities';

  @override
  String get typeToSearch => 'Type to search';

  @override
  String get cityRequired => 'City required';

  @override
  String get addOptionalDetails => 'Add optional details (not required)';

  @override
  String get postSuccessfullySubmitted => 'Post Successfully Submitted';

  @override
  String get postSubmittedAwaitingApproval =>
      'Your post has been submitted and is awaiting admin approval. It will appear on the homepage once approved.';

  @override
  String get maximumRecordingTimeReached =>
      'Maximum recording time of 1 minute reached.';

  @override
  String get textOrVoiceRequired =>
      'Please provide either text or voice message';

  @override
  String get mustBeLoggedIn => 'You must be logged in to post';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required for voice messages';

  @override
  String get failedToCreatePost => 'Failed to create post';

  @override
  String get audioFileTooLarge =>
      'Audio file too large. Please record a shorter message.';

  @override
  String get bothPermissionsRequired =>
      'Both microphone and storage permissions are required';

  @override
  String get failedToInitializeRecording => 'Failed to initialize recording';

  @override
  String get failedToStartRecording => 'Failed to start recording';

  @override
  String get failedToStopRecording => 'Failed to stop recording';

  @override
  String get failedToPlayRecording => 'Failed to play recording';

  @override
  String get voiceRecorderNotInitialized =>
      'Voice recorder is not initialized. Please check microphone permissions.';

  @override
  String get failedToLoadProfileData => 'Failed to load profile data';

  @override
  String get placeSearchFailed => 'Place search failed';

  @override
  String get failedToSearchPlaces => 'Failed to search places';

  @override
  String get plumber => 'Plumber';

  @override
  String get electrician => 'Electrician';

  @override
  String get painter => 'Painter';

  @override
  String get carpenter => 'Carpenter';

  @override
  String get mason => 'Mason';

  @override
  String get tiler => 'Tiler';

  @override
  String get gardener => 'Gardener';

  @override
  String get cleaner => 'Cleaner';

  @override
  String get roofer => 'Roofer';

  @override
  String get welder => 'Welder';

  @override
  String get windowInstaller => 'Window Installer';

  @override
  String get hvacTechnician => 'HVAC Technician';

  @override
  String get flooringInstaller => 'Flooring Installer';

  @override
  String get landscaper => 'Landscaper';

  @override
  String get other => 'Other';

  @override
  String get loadingMessages => 'Loading messages...';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get recordingAudio => 'Recording audio...';

  @override
  String get audioReadyToSend => 'Audio ready to send';

  @override
  String get sendingAudio => 'Sending audio...';

  @override
  String get sendingImage => 'Sending image...';

  @override
  String get audioMessage => 'Audio message';

  @override
  String get image => 'Image';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get cannotSendMessage => 'Cannot send message: Invalid conversation';

  @override
  String get cannotSendImage => 'Cannot send image: Invalid conversation';

  @override
  String get errorSendingMessage => 'Error sending message';

  @override
  String get errorSendingAudio => 'Error sending audio message';

  @override
  String get errorSelectingImage => 'Error selecting image';

  @override
  String get errorSendingImage => 'Error sending image';

  @override
  String get cannotViewProfile => 'Cannot view profile: User ID not available';

  @override
  String get couldNotOpenConversation => 'Could not open conversation';

  @override
  String get errorLoadingConversations =>
      'Error loading conversations. Please try again.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get user => 'User';

  @override
  String get viewRelatedPost => 'View Related Post';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get clearChatConfirmation =>
      'Are you sure you want to clear this chat? This action cannot be undone.';

  @override
  String requestWithActivity(String activity) {
    return 'Request: $activity';
  }

  @override
  String offerWithActivity(String activity) {
    return 'Offer: $activity';
  }

  @override
  String get viewPost => 'View Post';

  @override
  String get messageLabel => 'Message:';

  @override
  String get audioMessageLabel => 'Audio Message:';

  @override
  String get close => 'Close';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get mention => 'Mention';

  @override
  String get system => 'System';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get sendingTestNotification => 'Sending test notification...';

  @override
  String get testNotificationSent =>
      'Test notification sent! Check your notification panel.';

  @override
  String get failedToSendTestNotification => 'Failed to send test notification';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String get posts => 'Posts';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get reviews => 'Reviews';

  @override
  String get bio => 'Bio';

  @override
  String get voiceBio => 'Voice Bio';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get shareFirstPost => 'Share your first post with the community';

  @override
  String get userHasNoPosts => 'This user hasn\'t posted anything yet';

  @override
  String get createPost => 'Create Post';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get noReviewsReceived => 'You haven\'t received any reviews yet';

  @override
  String get userHasNoReviews => 'This user hasn\'t received any reviews yet';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get noPendingPostsToReview => 'No pending posts to review';

  @override
  String get noApprovedPosts => 'No approved posts';

  @override
  String get noRejectedPosts => 'No rejected posts';

  @override
  String get refresh => 'Refresh';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get moveToApproved => 'Move to Approved';

  @override
  String get moveToRejected => 'Move to Rejected';

  @override
  String get postApprovedSuccess => 'Post approved and now visible on homepage';

  @override
  String get postRejectedSuccess => 'Post rejected and removed from homepage';

  @override
  String get errorApprovingPost => 'Error approving post';

  @override
  String get errorRejectingPost => 'Error rejecting post';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get you => 'You';

  @override
  String get voiceReview => 'Voice Review';

  @override
  String duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get blockUser => 'Block user';

  @override
  String get reportUser => 'Report user';

  @override
  String get shareProfile => 'Share profile';
}
