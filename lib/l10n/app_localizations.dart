import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Achno'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get hello;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsAll;

  /// No description provided for @notificationsMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationsMessages;

  /// No description provided for @notificationsActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get notificationsActivity;

  /// No description provided for @notificationsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationsSystem;

  /// No description provided for @notificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get notificationEmpty;

  /// No description provided for @notificationEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notificationEmptyMessage;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markAsUnread;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No description provided for @clearAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This action cannot be undone.'**
  String get clearAllConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with someone'**
  String get startConversation;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @addPost.
  ///
  /// In en, this message translates to:
  /// **'Add Post'**
  String get addPost;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get messageHint;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get cityHint;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLabel;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get recordVoice;

  /// No description provided for @postButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postButtonLabel;

  /// No description provided for @errorSharingPost.
  ///
  /// In en, this message translates to:
  /// **'Failed to share post'**
  String get errorSharingPost;

  /// No description provided for @errorLikePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to update like'**
  String get errorLikePost;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get activeFilters;

  /// Dialog title for sending message to a user
  ///
  /// In en, this message translates to:
  /// **'Message to {userName}'**
  String messageToUser(String userName);

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message'**
  String get typeYourMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully'**
  String get messageSent;

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @responses.
  ///
  /// In en, this message translates to:
  /// **'responses'**
  String get responses;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @postType.
  ///
  /// In en, this message translates to:
  /// **'Post Type'**
  String get postType;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No Posts Available'**
  String get noPosts;

  /// No description provided for @createFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Be the first one to create a post!'**
  String get createFirstPost;

  /// No description provided for @errorLoadingPosts.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Posts'**
  String get errorLoadingPosts;

  /// No description provided for @pleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No Matching Results'**
  String get noMatchingResults;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try different filter options'**
  String get tryDifferentFilters;

  /// No description provided for @playingAudioMessage.
  ///
  /// In en, this message translates to:
  /// **'Playing audio message...'**
  String get playingAudioMessage;

  /// No description provided for @tapToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Tap to play audio message'**
  String get tapToPlayAudio;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @whatAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get whatAreYouLookingFor;

  /// User's current location display
  ///
  /// In en, this message translates to:
  /// **'Your location: {location}'**
  String yourLocation(String location);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @woodWorker.
  ///
  /// In en, this message translates to:
  /// **'Wood Worker'**
  String get woodWorker;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsPermanentlyDenied;

  /// No description provided for @failedToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get failedToGetLocation;

  /// No description provided for @gotLocation.
  ///
  /// In en, this message translates to:
  /// **'Got location'**
  String get gotLocation;

  /// No description provided for @cannotPrecalculateDistances.
  ///
  /// In en, this message translates to:
  /// **'Cannot precalculate distances - user home city is not available'**
  String get cannotPrecalculateDistances;

  /// No description provided for @userHomeCityFetched.
  ///
  /// In en, this message translates to:
  /// **'User home city fetched'**
  String get userHomeCityFetched;

  /// Distance in kilometers
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String kmDistance(int distance);

  /// Distance filter waiting for location
  ///
  /// In en, this message translates to:
  /// **'{distance}km (waiting for location...)'**
  String waitingForLocation(int distance);

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @iAm.
  ///
  /// In en, this message translates to:
  /// **'I am a:'**
  String get iAm;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @chooseProfession.
  ///
  /// In en, this message translates to:
  /// **'Choose your profession:'**
  String get chooseProfession;

  /// No description provided for @selectOtherActivity.
  ///
  /// In en, this message translates to:
  /// **'Select Other Activity'**
  String get selectOtherActivity;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?'**
  String get alreadyMember;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreated;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get continueToApp;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @textBio.
  ///
  /// In en, this message translates to:
  /// **'Text Bio (Optional)'**
  String get textBio;

  /// No description provided for @audioBio.
  ///
  /// In en, this message translates to:
  /// **'Audio Bio'**
  String get audioBio;

  /// No description provided for @recordAudioBio.
  ///
  /// In en, this message translates to:
  /// **'Record Audio Bio'**
  String get recordAudioBio;

  /// No description provided for @audioBioAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio Bio Available'**
  String get audioBioAvailable;

  /// No description provided for @recordNewAudio.
  ///
  /// In en, this message translates to:
  /// **'Record New Audio'**
  String get recordNewAudio;

  /// No description provided for @audioBioDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a short audio bio (up to 30 seconds)'**
  String get audioBioDescription;

  /// Recording duration display
  ///
  /// In en, this message translates to:
  /// **'Recording: {duration}'**
  String recording(String duration);

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @phoneCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be changed'**
  String get phoneCannotBeChanged;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @professionalActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Professional Activity'**
  String get professionalActivity;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @mediaPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature requires permission to access your media. Please enable it in app settings.'**
  String get mediaPermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter your city'**
  String get pleaseEnterCity;

  /// No description provided for @postDuration.
  ///
  /// In en, this message translates to:
  /// **'Post Duration'**
  String get postDuration;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @hours48.
  ///
  /// In en, this message translates to:
  /// **'48 Hours'**
  String get hours48;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @maxOneMinute.
  ///
  /// In en, this message translates to:
  /// **'Max 1 minute'**
  String get maxOneMinute;

  /// No description provided for @allowMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allowMicPermission;

  /// No description provided for @microphoneAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone access needed'**
  String get microphoneAccessNeeded;

  /// No description provided for @failedToInitializeRecorder.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize recorder'**
  String get failedToInitializeRecorder;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get tapToRecord;

  /// No description provided for @tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tapToStop;

  /// No description provided for @audioRecording.
  ///
  /// In en, this message translates to:
  /// **'Audio recording'**
  String get audioRecording;

  /// No description provided for @otherActivities.
  ///
  /// In en, this message translates to:
  /// **'Other Activities'**
  String get otherActivities;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get typeToSearch;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City required'**
  String get cityRequired;

  /// No description provided for @addOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Add optional details (not required)'**
  String get addOptionalDetails;

  /// No description provided for @postSuccessfullySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Post Successfully Submitted'**
  String get postSuccessfullySubmitted;

  /// No description provided for @postSubmittedAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your post has been submitted and is awaiting admin approval. It will appear on the homepage once approved.'**
  String get postSubmittedAwaitingApproval;

  /// No description provided for @maximumRecordingTimeReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum recording time of 1 minute reached.'**
  String get maximumRecordingTimeReached;

  /// No description provided for @textOrVoiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide either text or voice message'**
  String get textOrVoiceRequired;

  /// No description provided for @mustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to post'**
  String get mustBeLoggedIn;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice messages'**
  String get microphonePermissionRequired;

  /// No description provided for @failedToCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post'**
  String get failedToCreatePost;

  /// No description provided for @audioFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Audio file too large. Please record a shorter message.'**
  String get audioFileTooLarge;

  /// No description provided for @bothPermissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Both microphone and storage permissions are required'**
  String get bothPermissionsRequired;

  /// No description provided for @failedToInitializeRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize recording'**
  String get failedToInitializeRecording;

  /// No description provided for @failedToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording'**
  String get failedToStartRecording;

  /// No description provided for @failedToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording'**
  String get failedToStopRecording;

  /// No description provided for @failedToPlayRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to play recording'**
  String get failedToPlayRecording;

  /// No description provided for @voiceRecorderNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Voice recorder is not initialized. Please check microphone permissions.'**
  String get voiceRecorderNotInitialized;

  /// No description provided for @failedToLoadProfileData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile data'**
  String get failedToLoadProfileData;

  /// No description provided for @placeSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Place search failed'**
  String get placeSearchFailed;

  /// No description provided for @failedToSearchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Failed to search places'**
  String get failedToSearchPlaces;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @painter.
  ///
  /// In en, this message translates to:
  /// **'Painter'**
  String get painter;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @mason.
  ///
  /// In en, this message translates to:
  /// **'Mason'**
  String get mason;

  /// No description provided for @tiler.
  ///
  /// In en, this message translates to:
  /// **'Tiler'**
  String get tiler;

  /// No description provided for @gardener.
  ///
  /// In en, this message translates to:
  /// **'Gardener'**
  String get gardener;

  /// No description provided for @cleaner.
  ///
  /// In en, this message translates to:
  /// **'Cleaner'**
  String get cleaner;

  /// No description provided for @roofer.
  ///
  /// In en, this message translates to:
  /// **'Roofer'**
  String get roofer;

  /// No description provided for @welder.
  ///
  /// In en, this message translates to:
  /// **'Welder'**
  String get welder;

  /// No description provided for @windowInstaller.
  ///
  /// In en, this message translates to:
  /// **'Window Installer'**
  String get windowInstaller;

  /// No description provided for @hvacTechnician.
  ///
  /// In en, this message translates to:
  /// **'HVAC Technician'**
  String get hvacTechnician;

  /// No description provided for @flooringInstaller.
  ///
  /// In en, this message translates to:
  /// **'Flooring Installer'**
  String get flooringInstaller;

  /// No description provided for @landscaper.
  ///
  /// In en, this message translates to:
  /// **'Landscaper'**
  String get landscaper;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @loadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get loadingMessages;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @recordingAudio.
  ///
  /// In en, this message translates to:
  /// **'Recording audio...'**
  String get recordingAudio;

  /// No description provided for @audioReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Audio ready to send'**
  String get audioReadyToSend;

  /// No description provided for @sendingAudio.
  ///
  /// In en, this message translates to:
  /// **'Sending audio...'**
  String get sendingAudio;

  /// No description provided for @sendingImage.
  ///
  /// In en, this message translates to:
  /// **'Sending image...'**
  String get sendingImage;

  /// No description provided for @audioMessage.
  ///
  /// In en, this message translates to:
  /// **'Audio message'**
  String get audioMessage;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @cannotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot send message: Invalid conversation'**
  String get cannotSendMessage;

  /// No description provided for @cannotSendImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot send image: Invalid conversation'**
  String get cannotSendImage;

  /// No description provided for @errorSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending message'**
  String get errorSendingMessage;

  /// No description provided for @errorSendingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error sending audio message'**
  String get errorSendingAudio;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @errorSendingImage.
  ///
  /// In en, this message translates to:
  /// **'Error sending image'**
  String get errorSendingImage;

  /// No description provided for @cannotViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Cannot view profile: User ID not available'**
  String get cannotViewProfile;

  /// No description provided for @couldNotOpenConversation.
  ///
  /// In en, this message translates to:
  /// **'Could not open conversation'**
  String get couldNotOpenConversation;

  /// No description provided for @errorLoadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations. Please try again.'**
  String get errorLoadingConversations;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @viewRelatedPost.
  ///
  /// In en, this message translates to:
  /// **'View Related Post'**
  String get viewRelatedPost;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @clearChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear this chat? This action cannot be undone.'**
  String get clearChatConfirmation;

  /// Request post type with activity
  ///
  /// In en, this message translates to:
  /// **'Request: {activity}'**
  String requestWithActivity(String activity);

  /// Offer post type with activity
  ///
  /// In en, this message translates to:
  /// **'Offer: {activity}'**
  String offerWithActivity(String activity);

  /// No description provided for @viewPost.
  ///
  /// In en, this message translates to:
  /// **'View Post'**
  String get viewPost;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message:'**
  String get messageLabel;

  /// No description provided for @audioMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio Message:'**
  String get audioMessageLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @mention.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get mention;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @sendingTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Sending test notification...'**
  String get sendingTestNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! Check your notification panel.'**
  String get testNotificationSent;

  /// No description provided for @failedToSendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification'**
  String get failedToSendTestNotification;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @voiceBio.
  ///
  /// In en, this message translates to:
  /// **'Voice Bio'**
  String get voiceBio;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @shareFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Share your first post with the community'**
  String get shareFirstPost;

  /// No description provided for @userHasNoPosts.
  ///
  /// In en, this message translates to:
  /// **'This user hasn\'t posted anything yet'**
  String get userHasNoPosts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @noReviewsReceived.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t received any reviews yet'**
  String get noReviewsReceived;

  /// No description provided for @userHasNoReviews.
  ///
  /// In en, this message translates to:
  /// **'This user hasn\'t received any reviews yet'**
  String get userHasNoReviews;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noPendingPostsToReview.
  ///
  /// In en, this message translates to:
  /// **'No pending posts to review'**
  String get noPendingPostsToReview;

  /// No description provided for @noApprovedPosts.
  ///
  /// In en, this message translates to:
  /// **'No approved posts'**
  String get noApprovedPosts;

  /// No description provided for @noRejectedPosts.
  ///
  /// In en, this message translates to:
  /// **'No rejected posts'**
  String get noRejectedPosts;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @moveToApproved.
  ///
  /// In en, this message translates to:
  /// **'Move to Approved'**
  String get moveToApproved;

  /// No description provided for @moveToRejected.
  ///
  /// In en, this message translates to:
  /// **'Move to Rejected'**
  String get moveToRejected;

  /// No description provided for @postApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post approved and now visible on homepage'**
  String get postApprovedSuccess;

  /// No description provided for @postRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post rejected and removed from homepage'**
  String get postRejectedSuccess;

  /// No description provided for @errorApprovingPost.
  ///
  /// In en, this message translates to:
  /// **'Error approving post'**
  String get errorApprovingPost;

  /// No description provided for @errorRejectingPost.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting post'**
  String get errorRejectingPost;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Minutes ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Hours ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Days ago timestamp
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @voiceReview.
  ///
  /// In en, this message translates to:
  /// **'Voice Review'**
  String get voiceReview;

  /// Audio duration display
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(String duration);

  /// Number of reviews
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
