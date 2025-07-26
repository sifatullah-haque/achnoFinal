// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أشنو';

  @override
  String get hello => 'مرحبا بكم';

  @override
  String get settings => 'الإعدادات';

  @override
  String get darkMode => 'الوضع المظلم';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'الفرنسية';

  @override
  String get spanish => 'Spanish';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsAll => 'الكل';

  @override
  String get notificationsMessages => 'الرسائل';

  @override
  String get notificationsActivity => 'النشاط';

  @override
  String get notificationsSystem => 'النظام';

  @override
  String get notificationEmpty => 'لا توجد إشعارات';

  @override
  String get notificationEmptyMessage => 'أنت على اطلاع!';

  @override
  String get markAsRead => 'وضع علامة كمقروء';

  @override
  String get markAsUnread => 'وضع علامة كغير مقروء';

  @override
  String get deleteNotification => 'حذف الإشعار';

  @override
  String get viewProfile => 'عرض الملف الشخصي';

  @override
  String get markAllAsRead => 'وضع علامة على الكل كمقروء';

  @override
  String get clearAllNotifications => 'مسح جميع الإشعارات';

  @override
  String get clearAllConfirmation =>
      'هل أنت متأكد أنك تريد حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get follow => 'متابعة';

  @override
  String get messages => 'الرسائل';

  @override
  String get search => 'بحث';

  @override
  String get noMessages => 'لا توجد رسائل بعد';

  @override
  String get startConversation => 'ابدأ محادثة مع شخص ما';

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get addPost => 'إضافة منشور';

  @override
  String get messageHint => 'اكتب رسالتك...';

  @override
  String get cityHint => 'اختر المدينة';

  @override
  String get activityLabel => 'الحرفة';

  @override
  String get recordVoice => 'تسجيل رسالة صوتية';

  @override
  String get postButtonLabel => 'نشر';

  @override
  String get errorSharingPost => 'فشل مشاركة المنشور';

  @override
  String get errorLikePost => 'فشل تحديث الإعجاب';

  @override
  String get activeFilters => 'الفلاتر النشطة';

  @override
  String messageToUser(String userName) {
    return 'رسالة إلى $userName';
  }

  @override
  String get typeYourMessage => 'اكتب رسالتك';

  @override
  String get send => 'إرسال';

  @override
  String get messageSent => 'تم إرسال الرسالة بنجاح';

  @override
  String get respond => 'رد';

  @override
  String get share => 'مشاركة';

  @override
  String get message => 'رسالة';

  @override
  String get responses => 'ردود';

  @override
  String get filters => 'الفلاتر';

  @override
  String get postType => 'نوع المنشور';

  @override
  String get request => 'طلب';

  @override
  String get offer => 'عرض';

  @override
  String get city => 'المدينة';

  @override
  String get activity => 'الحرفة';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get apply => 'تطبيق';

  @override
  String get noPosts => 'لا توجد منشورات متاحة';

  @override
  String get createFirstPost => 'كن أول من ينشئ منشور!';

  @override
  String get errorLoadingPosts => 'خطأ في تحميل المنشورات';

  @override
  String get pleaseRetry => 'الرجاء المحاولة لاحقاً';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noMatchingResults => 'لا توجد نتائج مطابقة';

  @override
  String get tryDifferentFilters => 'جرب خيارات تصفية مختلفة';

  @override
  String get playingAudioMessage => 'جاري تشغيل الرسالة الصوتية...';

  @override
  String get tapToPlayAudio => 'انقر لتشغيل الرسالة الصوتية';

  @override
  String get distance => 'المسافة';

  @override
  String get whatAreYouLookingFor => 'اشنوخاصك ليوم؟';

  @override
  String yourLocation(String location) {
    return 'موقعك: $location';
  }

  @override
  String get all => 'الكل';

  @override
  String get woodWorker => 'نجار خشب';

  @override
  String get locationServicesDisabled => 'خدمات الموقع معطلة';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'أذونات الموقع مرفوضة نهائياً';

  @override
  String get failedToGetLocation => 'فشل في الحصول على الموقع';

  @override
  String get gotLocation => 'تم الحصول على الموقع';

  @override
  String get cannotPrecalculateDistances =>
      'لا يمكن حساب المسافات مسبقاً - مدينة المستخدم الأصلية غير متوفرة';

  @override
  String get userHomeCityFetched => 'تم جلب مدينة المستخدم الأصلية';

  @override
  String kmDistance(int distance) {
    return '$distance كم';
  }

  @override
  String waitingForLocation(int distance) {
    return '$distanceكم (في انتظار الموقع...)';
  }

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get passwordMinLength =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get pleaseConfirmPassword => 'الرجاء تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get pleaseEnterName => 'الرجاء إدخال الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get pleaseEnterPhone => 'الرجاء إدخال رقم الهاتف';

  @override
  String get invalidPhoneNumber => 'الرجاء إدخال رقم هاتف صحيح';

  @override
  String get preferredLanguage => 'اللغة المفضلة';

  @override
  String get iAm => 'أنا:';

  @override
  String get client => 'عميل';

  @override
  String get professional => 'محترف';

  @override
  String get chooseProfession => 'اختر حرفتك:';

  @override
  String get selectOtherActivity => 'اختر حرفة آخر';

  @override
  String get completeRegistration => 'إكمال التسجيل';

  @override
  String get continue_ => 'متابعة';

  @override
  String get alreadyMember => 'هل أنت عضو مسجل؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get success => 'تم بنجاح!';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح';

  @override
  String get continueToApp => 'المتابعة إلى التطبيق';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get textBio => 'السيرة النصية (اختياري)';

  @override
  String get audioBio => 'السيرة الصوتية';

  @override
  String get recordAudioBio => 'تسجيل سيرة صوتية';

  @override
  String get audioBioAvailable => 'السيرة الصوتية متاحة';

  @override
  String get recordNewAudio => 'تسجيل صوت جديد';

  @override
  String get audioBioDescription => 'سجّل سيرة صوتية قصيرة (حتى 30 ثانية)';

  @override
  String recording(String duration) {
    return 'جاري التسجيل: $duration';
  }

  @override
  String get stopRecording => 'إيقاف التسجيل';

  @override
  String get phoneCannotBeChanged => 'لا يمكن تغيير رقم الهاتف';

  @override
  String get phone => 'الهاتف';

  @override
  String get professionalActivity => 'نشاطك المهني';

  @override
  String get selectImageSource => 'اختر مصدر الصورة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get permissionRequired => 'الإذن مطلوب';

  @override
  String get mediaPermissionMessage =>
      'تتطلب هذه الميزة إذنًا للوصول إلى الوسائط الخاصة بك. يرجى تمكينه في إعدادات التطبيق.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get pleaseEnterCity => 'الرجاء إدخال المدينة';

  @override
  String get postDuration => 'مدة المنشور';

  @override
  String get unlimited => 'غير محدود';

  @override
  String get hours48 => '48 ساعة';

  @override
  String get days7 => '7 أيام';

  @override
  String get days30 => '30 يوم';

  @override
  String get maxOneMinute => 'حد أقصى دقيقة واحدة';

  @override
  String get allowMicPermission => 'السماح';

  @override
  String get microphoneAccessNeeded => 'يتطلب الوصول للميكروفون';

  @override
  String get failedToInitializeRecorder => 'فشل في تهيئة المسجل';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get tapToRecord => 'انقر للتسجيل';

  @override
  String get tapToStop => 'انقر للتوقف';

  @override
  String get audioRecording => 'تسجيل صوتي';

  @override
  String get otherActivities => 'حرف أخرى';

  @override
  String get typeToSearch => 'اكتب للبحث';

  @override
  String get cityRequired => 'المدينة مطلوبة';

  @override
  String get addOptionalDetails => 'إضافة تفاصيل اختيارية (غير مطلوب)';

  @override
  String get postSuccessfullySubmitted => 'تم إرسال المنشور بنجاح';

  @override
  String get postSubmittedAwaitingApproval =>
      'تم إرسال منشورك وهو بانتظار موافقة المدير. سيظهر على الصفحة الرئيسية بعد الموافقة.';

  @override
  String get maximumRecordingTimeReached =>
      'تم الوصول لأقصى مدة تسجيل وهي دقيقة واحدة.';

  @override
  String get textOrVoiceRequired => 'يرجى تقديم رسالة نصية أو صوتية';

  @override
  String get mustBeLoggedIn => 'يجب تسجيل الدخول للنشر';

  @override
  String get microphonePermissionRequired =>
      'إذن الميكروفون مطلوب للرسائل الصوتية';

  @override
  String get failedToCreatePost => 'فشل في إنشاء المنشور';

  @override
  String get audioFileTooLarge =>
      'الملف الصوتي كبير جداً. يرجى تسجيل رسالة أقصر.';

  @override
  String get bothPermissionsRequired => 'كلا إذني الميكروفون والتخزين مطلوبان';

  @override
  String get failedToInitializeRecording => 'فشل في تهيئة التسجيل';

  @override
  String get failedToStartRecording => 'فشل في بدء التسجيل';

  @override
  String get failedToStopRecording => 'فشل في إيقاف التسجيل';

  @override
  String get failedToPlayRecording => 'فشل في تشغيل التسجيل';

  @override
  String get voiceRecorderNotInitialized =>
      'مسجل الصوت غير مهيأ. يرجى فحص أذونات الميكروفون.';

  @override
  String get failedToLoadProfileData => 'فشل في تحميل بيانات الملف الشخصي';

  @override
  String get placeSearchFailed => 'فشل في البحث عن المكان';

  @override
  String get failedToSearchPlaces => 'فشل في البحث عن الأماكن';

  @override
  String get plumber => 'سباك';

  @override
  String get electrician => 'كهربائي';

  @override
  String get painter => 'نقاش';

  @override
  String get carpenter => 'نجار';

  @override
  String get mason => 'بناء';

  @override
  String get tiler => 'بلاطي';

  @override
  String get gardener => 'بستاني';

  @override
  String get cleaner => 'منظف';

  @override
  String get roofer => 'سقاف';

  @override
  String get welder => 'حداد';

  @override
  String get windowInstaller => 'مركب النوافذ';

  @override
  String get hvacTechnician => 'فني تكييف';

  @override
  String get flooringInstaller => 'مركب الأرضيات';

  @override
  String get landscaper => 'منسق حدائق';

  @override
  String get other => 'أخرى';

  @override
  String get loadingMessages => 'جاري تحميل الرسائل...';

  @override
  String get typeAMessage => 'اكتب رسالة...';

  @override
  String get recordingAudio => 'جاري تسجيل الصوت...';

  @override
  String get audioReadyToSend => 'الصوت جاهز للإرسال';

  @override
  String get sendingAudio => 'جاري إرسال الصوت...';

  @override
  String get sendingImage => 'جاري إرسال الصورة...';

  @override
  String get audioMessage => 'رسالة صوتية';

  @override
  String get image => 'صورة';

  @override
  String get failedToLoadImage => 'فشل في تحميل الصورة';

  @override
  String get cannotSendMessage => 'لا يمكن إرسال الرسالة: محادثة غير صحيحة';

  @override
  String get cannotSendImage => 'لا يمكن إرسال الصورة: محادثة غير صحيحة';

  @override
  String get errorSendingMessage => 'خطأ في إرسال الرسالة';

  @override
  String get errorSendingAudio => 'خطأ في إرسال الرسالة الصوتية';

  @override
  String get errorSelectingImage => 'خطأ في اختيار الصورة';

  @override
  String get errorSendingImage => 'خطأ في إرسال الصورة';

  @override
  String get cannotViewProfile =>
      'لا يمكن عرض الملف الشخصي: معرف المستخدم غير متوفر';

  @override
  String get couldNotOpenConversation => 'لا يمكن فتح المحادثة';

  @override
  String get errorLoadingConversations =>
      'خطأ في تحميل المحادثات. يرجى المحاولة مرة أخرى.';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get user => 'مستخدم';

  @override
  String get viewRelatedPost => 'عرض المنشور المرتبط';

  @override
  String get clearChat => 'مسح المحادثة';

  @override
  String get clearChatConfirmation =>
      'هل أنت متأكد أنك تريد مسح هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String requestWithActivity(String activity) {
    return 'طلب: $activity';
  }

  @override
  String offerWithActivity(String activity) {
    return 'عرض: $activity';
  }

  @override
  String get viewPost => 'عرض المنشور';

  @override
  String get messageLabel => 'الرسالة:';

  @override
  String get audioMessageLabel => 'الرسالة الصوتية:';

  @override
  String get close => 'إغلاق';

  @override
  String get like => 'إعجاب';

  @override
  String get comment => 'تعليق';

  @override
  String get mention => 'إشارة';

  @override
  String get system => 'النظام';

  @override
  String get sendTestNotification => 'إرسال إشعار تجريبي';

  @override
  String get sendingTestNotification => 'جاري إرسال الإشعار التجريبي...';

  @override
  String get testNotificationSent =>
      'تم إرسال الإشعار التجريبي! تحقق من لوحة الإشعارات.';

  @override
  String get failedToSendTestNotification => 'فشل في إرسال الإشعار التجريبي';

  @override
  String get failedToLoadNotifications => 'فشل في تحميل الإشعارات';

  @override
  String get posts => 'المنشورات';

  @override
  String get followers => 'المتابعون';

  @override
  String get following => 'المتابَعون';

  @override
  String get reviews => 'التقييمات';

  @override
  String get bio => 'السيرة الذاتية';

  @override
  String get voiceBio => 'السيرة الصوتية';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد';

  @override
  String get shareFirstPost => 'شارك منشورك الأول مع المجتمع';

  @override
  String get userHasNoPosts => 'لم ينشر هذا المستخدم أي شيء بعد';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد';

  @override
  String get noReviewsReceived => 'لم تتلق أي تقييمات بعد';

  @override
  String get userHasNoReviews => 'لم يتلق هذا المستخدم أي تقييمات بعد';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get areYouSureLogout => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String get adminDashboard => 'لوحة تحكم المدير';

  @override
  String get pending => 'في الانتظار';

  @override
  String get approved => 'موافق عليها';

  @override
  String get rejected => 'مرفوضة';

  @override
  String get noPendingPostsToReview => 'لا توجد منشورات في انتظار المراجعة';

  @override
  String get noApprovedPosts => 'لا توجد منشورات موافق عليها';

  @override
  String get noRejectedPosts => 'لا توجد منشورات مرفوضة';

  @override
  String get refresh => 'تحديث';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get moveToApproved => 'نقل إلى الموافق عليها';

  @override
  String get moveToRejected => 'نقل إلى المرفوضة';

  @override
  String get postApprovedSuccess =>
      'تمت الموافقة على المنشور وهو مرئي الآن على الصفحة الرئيسية';

  @override
  String get postRejectedSuccess => 'تم رفض المنشور وإزالته من الصفحة الرئيسية';

  @override
  String get errorApprovingPost => 'خطأ في الموافقة على المنشور';

  @override
  String get errorRejectingPost => 'خطأ في رفض المنشور';

  @override
  String get voiceMessage => 'رسالة صوتية';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String hoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String daysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String get you => 'أنت';

  @override
  String get voiceReview => 'تقييم صوتي';

  @override
  String duration(String duration) {
    return 'المدة: $duration';
  }

  @override
  String reviewsCount(int count) {
    return '$count تقييم';
  }

  @override
  String get unknownDate => 'تاريخ غير معروف';

  @override
  String get anonymous => 'مجهول';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get reportUser => 'الإبلاغ عن المستخدم';

  @override
  String get shareProfile => 'مشاركة الملف الشخصي';
}
