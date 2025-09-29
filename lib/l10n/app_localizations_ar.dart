// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get locationPermissionMessage => 'الرجاء السماح بالوصول إلى الموقع للعثور على مقدمي الخدمات القريبين';

  @override
  String get allow => 'السماح';

  @override
  String get goToLogin => 'الذهاب إلى تسجيل الدخول';

  @override
  String get serverTimeout => 'استغرق الخادم وقتًا طويلاً للرد.';

  @override
  String get authError => 'فشل التحقق من تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get checkingLoginStatus => 'انتظر قليلا لتحميل معلوماتك..';

  @override
  String get welcome1Title => 'مساعدة ذكية';

  @override
  String get welcome1Desc => 'هو تطبيق ذكي يساعدك في حل الأعطال \nالتي تتعرض لها مركبتك';

  @override
  String get welcome2Title => 'فنيون متخصصون';

  @override
  String get welcome2Desc => 'سنوفر اكثر الاشخاص خبرة\n و الاقرب اليك لاخراجك من المأزق';

  @override
  String get welcome3Title => 'خدمات إضافية';

  @override
  String get welcome3Desc => 'يمكنك ايضا الاستفادة من خدماتنا الاضافية\n الابلاغ و استئجار سيارات ...';

  @override
  String get welcome4Title => 'دعم على مدار الساعة';

  @override
  String get welcome4Desc => 'سنكون معكم اينما كنتكم  \n ان كنت تريد ان توفر الوقت و المال فاخترنا';

  @override
  String get continueButton => 'متابعة';

  @override
  String get nextButton => 'التالي';

  @override
  String get skipButton => 'تخطي';

  @override
  String get anonymous_user => 'مستخدم مجهول';

  @override
  String get no_chats_found => 'لم يتم العثور على محادثات';

  @override
  String get message_queued => 'تم وضع الرسالة في قائمة الانتظار';

  @override
  String get about => 'حول';

  @override
  String get aboutUs => 'من نحن';

  @override
  String get aboutUsDesc => 'نربطك بمحترفي إصلاح السيارات الموثوقين لإعادتك إلى الطريق بسرعة.';

  @override
  String get acRepair => 'إصلاح التكييف';

  @override
  String get addComment => 'أضف تعليقًا';

  @override
  String get add_content => 'إضافة محتوى';

  @override
  String get add_from_gallery => 'إضافة من المعرض';

  @override
  String get additionalFeedback => 'تعليقات إضافية';

  @override
  String get additional_info => 'معلومات إضافية';

  @override
  String get addressError => 'فشل في جلب العنوان';

  @override
  String get addressFetchError => 'فشل في الحصول على العنوان.';

  @override
  String get addressFetchFailed => 'فشل في جلب العنوان، حاول مرة أخرى';

  @override
  String get address_error => 'خطأ في جلب العنوان. يرجى المحاولة مرة أخرى.';

  @override
  String get advice => 'نصائح';

  @override
  String get alert => 'تنبيه';

  @override
  String get alertComingSoon => 'يتم حالياً العمل على ميزة التنبيه في حالات الطوارئ وسوف تكون متاحة في تحديث قادم. نقدر تفهمكم!';

  @override
  String get all => 'الكل';

  @override
  String get allCategories => 'جميع الفئات';

  @override
  String get allServices => 'جميع الخدمات';

  @override
  String get all_providers_busy => 'جميع المزودين المتاحين مشغولون';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get ambulance => 'الإسعافات';

  @override
  String get ambulanceDescription => 'يهمنا سلامتك. فور حدوث أي طارئ، يمكنك الاتصال مباشرة أو إرسال تنبيه أو رسالة مع موقع تواجدك.';

  @override
  String get apiBlockedError => 'واجهة برمجة يوتيوب محظورة حاليًا. يرجى المحاولة مرة أخرى لاحقًا أو التواصل مع الدعم.';

  @override
  String get apiInvalidError => 'مفتاح واجهة برمجة يوتيوب غير صالح. يرجى التواصل مع الدعم.';

  @override
  String get appDescription => 'تطبيق يقدم مجموعة من الخدمات لكل مستعملي الطرقات ومستقلي السيارات.';

  @override
  String get appLogo => 'شعار رانا جايين';

  @override
  String get appRating => 'قيم تطبيقنا';

  @override
  String get appointmentTime => 'وقت الموعد';

  @override
  String get appointmentTimeError => 'يرجى اختيار وقت الموعد';

  @override
  String get appointment_booked => 'تم حجز الموعد';

  @override
  String get arabic => 'العربية';

  @override
  String get arrivalTimeError => 'خطأ في تحديث وقت الوصول.';

  @override
  String get articles => 'المقالات';

  @override
  String get assigned_provider_info => 'معلومات مقدم الخدمة المعين';

  @override
  String get assigned_to_request => 'تم تعيينه لطلبك!';

  @override
  String authenticationFailed(Object error) {
    return 'فشل المصادقة: $error';
  }

  @override
  String get available => 'مقدمو الخدمة المتاحون';

  @override
  String get back => 'رجوع';

  @override
  String get batteryChargeDescription => 'شحن أو استبدال بطارية السيارة في الموقع';

  @override
  String get batteryChargeTitle => 'شحن أو استبدال البطارية';

  @override
  String get batteryChargeType => 'شحن البطارية';

  @override
  String get batteryReplacement => 'استبدال البطارية';

  @override
  String get becauseWeCome => 'لأننا نأتي إليك بما تحتاجه في أي زمان أو مكان.';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get bookingConfirmed => 'تم تأكيد الحجز';

  @override
  String get bookingSummary => 'ملخص الحجز';

  @override
  String get brakeRepair => 'إصلاح الفرامل';

  @override
  String get brakeServiceDescription => 'إصلاح وصيانة نظام الفرامل للأمان.';

  @override
  String get brakeServiceTitle => 'إصلاح الفرامل';

  @override
  String get brands => 'علامات تجارية';

  @override
  String get browse_posts => 'تصفح المنشورات';

  @override
  String get call => 'الاتصال';

  @override
  String get callDriver => 'الاتصال بمقدم الخدمة';

  @override
  String get callError => 'فشل في إجراء المكالمة الهاتفية.';

  @override
  String get callFailed => 'لا يمكن إجراء المكالمة';

  @override
  String get callProvider => 'الاتصال بالمزود';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String get call_now => 'الاتصال الآن';

  @override
  String get call_provider => 'الاتصال بمقدم الخدمة';

  @override
  String get call_provider_button => 'زر الاتصال بمقدم الخدمة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get cancelService => 'إلغاء الخدمة';

  @override
  String get cancel_request => 'إلغاء الطلب';

  @override
  String get cancel_request_button => 'زر إلغاء الطلب';

  @override
  String get cannot_make_call => 'غير قادر على إجراء مكالمة إلى';

  @override
  String get car => 'سيارة';

  @override
  String get carACServiceDescription => 'إصلاح أو إعادة شحن نظام تكييف السيارة';

  @override
  String get carACServiceTitle => 'خدمة تكييف السيارة';

  @override
  String get carElectricianDescription => 'تشخيص وإصلاح الأنظمة الكهربائية للسيارة';

  @override
  String get carElectricianTitle => 'كهربائي سيارات';

  @override
  String get carFixesTips => 'إصلاح السيارات ونصائح';

  @override
  String get carInspectionDescription => 'فحص شامل للسيارة قبل الشراء أو بشكل دوري';

  @override
  String get carInspectionTitle => 'فحص السيارة';

  @override
  String get carMechanicDescription => 'إصلاحات ميكانيكية عامة للسيارة في موقعك';

  @override
  String get carMechanicTitle => 'ميكانيكي سيارات';

  @override
  String get carRental => 'تأجير السيارات';

  @override
  String get carRentalDescription => 'خدمات تأجير السيارات المريحة';

  @override
  String get carRentalTitle => 'تأجير السيارات';

  @override
  String get carUnlock => 'فتح السيارة';

  @override
  String get carWash => 'غسيل السيارات';

  @override
  String get carWashDescription => 'خدمات تنظيف السيارات الاحترافية';

  @override
  String get carWashTitle => 'غسيل السيارات';

  @override
  String get cars => 'سيارات';

  @override
  String get cashback => 'استرداد نقدي 20%';

  @override
  String get category => 'الفئة';

  @override
  String get center_map => 'تمركز الخريطة على موقعي';

  @override
  String get changeAddress => 'تغيير العنوان';

  @override
  String get changeLocation => 'تغيير الموقع';

  @override
  String get changeLocationTitle => 'تغيير الموقع';

  @override
  String get changePhoneNumber => 'تغيير رقم الهاتف';

  @override
  String get change_address => 'تغيير العنوان';

  @override
  String get change_location => 'تغيير الموقع';

  @override
  String get change_location_button => 'زر تغيير الموقع';

  @override
  String get chat => 'دردشة';

  @override
  String get chatNow => 'دردش الآن';

  @override
  String chat_initiated(Object serviceTitle) {
    return 'تم بدء الدردشة لـ $serviceTitle';
  }

  @override
  String get chat_queued => 'تمت إضافة الدردشة إلى قائمة الانتظار ليتم إرسالها عند الاتصال بالإنترنت';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get civilProtection => 'الحماية المدنية';

  @override
  String get civilProtectionDescription => 'يهمنا سلامتك. فور حدوث أي طارئ، يمكنك الاتصال مباشرة أو إرسال تنبيه أو رسالة مع موقع تواجدك.';

  @override
  String get close => 'إغلاق';

  @override
  String get comfortableSedan => 'سيدان مريح';

  @override
  String get comingSoon => 'قريباً!';

  @override
  String get commentError => 'حدث خطأ أثناء نشر التعليق';

  @override
  String get commentPosted => 'تم نشر التعليق بنجاح';

  @override
  String get comments => 'التعليقات';

  @override
  String get completeRegistrationMessage => 'أدخل تفاصيلك للبدء.';

  @override
  String get confirmCode => 'تأكيد الرمز';

  @override
  String get confirmDeletePost => 'تأكيد حذف المنشور';

  @override
  String get confirmDeletePostMessage => 'هل أنت متأكد من أنك تريد حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get confirmSubscribe => 'تأكيد الاشتراك';

  @override
  String get confirmSubscribeMessage => 'هل تريد الاشتراك في محتوى هذا المستخدم؟';

  @override
  String get confirmUnsubscribe => 'تأكيد إلغاء الاشتراك';

  @override
  String get confirmUnsubscribeMessage => 'هل تريد إلغاء الاشتراك من محتوى هذا المستخدم؟';

  @override
  String get confirmVerificationCode => 'تأكيد رمز التحقق';

  @override
  String get connection_restored => 'تم استعادة الاتصال';

  @override
  String get contact => 'الاتصال';

  @override
  String get contactProvider => 'جاري التواصل مع';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get contact_provider_button => 'التواصل مع مقدم الخدمة';

  @override
  String get contacting_driver => 'جارٍ التواصل مع السائق';

  @override
  String get content => 'المحتوى';

  @override
  String get currency => 'دج';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get dataError => 'خطأ في تحميل البيانات.';

  @override
  String dataSavedError(Object error) {
    return 'خطأ في حفظ البيانات: $error';
  }

  @override
  String get dataSavedSuccess => 'تم حفظ البيانات بنجاح';

  @override
  String get date => 'التاريخ';

  @override
  String get dateError => 'يرجى اختيار تاريخ الغسيل';

  @override
  String get dateOfWash => 'تاريخ الغسيل';

  @override
  String get days => 'أيام';

  @override
  String days_ago(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count أيام',
      one: 'قبل يوم واحد',
      zero: 'قبل 0 أيام',
    );
    return '$_temp0';
  }

  @override
  String get defaultSort => 'الافتراضي';

  @override
  String get default_location => 'الموقع الافتراضي (الجزائر)';

  @override
  String get delete => 'حذف';

  @override
  String get deletePost => 'حذف المنشور';

  @override
  String get delivery_option => 'خيار التوصيل';

  @override
  String get delivery_option_subtitle => 'اختر ما إذا كنت تريد توصيل الخدمة إليك';

  @override
  String get desc_bmw_r1250gs => 'دراجة نارية سياحية بميزات فاخرة';

  @override
  String get desc_chevrolet_silverado => 'شاحنة كبيرة بسحب قوي';

  @override
  String get desc_ford_f150 => 'شاحنة صغيرة ذات قدرات قوية';

  @override
  String get desc_ford_mustang => 'سيارة أمريكية قوية ذات أداء متميز';

  @override
  String get desc_harley_sportster => 'دراجة نارية كلاسيكية بتصميم خالد';

  @override
  String get desc_honda_cbr600rr => 'دراجة نارية رياضية عالية الأداء للهواة';

  @override
  String get desc_honda_civic => 'سيارة رياضية صغيرة مع قيادة ممتازة';

  @override
  String get desc_toyota_corolla => 'سيارة سيدان موثوقة وموفرة للوقود مع ميزات حديثة';

  @override
  String get desc_toyota_tacoma => 'شاحنة متوسطة معروفة بمتانتها وأدائها على الطرق الوعرة';

  @override
  String get description => 'الوصف';

  @override
  String get determining_provider_location => 'جاري تحديد موقع مقدم الخدمة...';

  @override
  String get diagnostic => 'التشخيص';

  @override
  String get discountBanner => 'مفاجأة صيفية';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get distance => 'المسافة';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get driver => 'سائق';

  @override
  String get driverArrived => 'وصل مقدم الخدمة';

  @override
  String get driverComing => 'مقدم الخدمة قادم خلال';

  @override
  String get driverHasArrived => 'وصل مقدم الخدمة';

  @override
  String get driverIconLoadFailed => 'فشل في تحميل أيقونة مقدم الخدمة';

  @override
  String get driverIncluded => 'يشمل السائق';

  @override
  String get driverInfo => 'معلومات مقدم الخدمة';

  @override
  String get driverInfoError => 'خطأ في استرجاع معلومات مقدم الخدمة.';

  @override
  String get driverIsComing => 'مقدم الخدمة قادم - وقت الوصول: ';

  @override
  String get driverOnWay => 'مقدم الخدمة في طريقه';

  @override
  String get driverSearchError => 'فشل في العثور على مزودين.';

  @override
  String get driverToDestination => 'في طريقه إلى الوجهة';

  @override
  String get driver_info_not_found => 'بيانات السائق غير متوفرة';

  @override
  String get editPost => 'تعديل المنشور';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailUs => 'راسلنا عبر البريد الإلكتروني';

  @override
  String get emergencies => 'الطوارئ';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String get titleRequired => 'العنوان مطلوب';

  @override
  String get contentRequired => 'المحتوى مطلوب';

  @override
  String get videoRequired => 'الفيديو مطلوب';

  @override
  String get postCreated => 'تم إنشاء المنشور بنجاح';

  @override
  String get postCreateError => 'فشل في إنشاء المنشور';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get uploadVideo => 'رفع فيديو';

  @override
  String get videoSelected => 'تم تحديد الفيديو';

  @override
  String get submit => 'إرسال الطلب';

  @override
  String get rating => 'التقييم';

  @override
  String get emergencyRepair => 'إصلاح طارئ';

  @override
  String get emergencyRepairMessage => 'هل تحتاج إلى إصلاح سيارة عاجل؟ ابحث عن ميكانيكي الآن!';

  @override
  String get searchMechanics => 'ابحث عن الميكانيكيين...';

  @override
  String get emergencyContacts => 'جهات الاتصال في حالات الطوارئ';

  @override
  String get welcomeToRanaJayeen => 'مرحبًا بكم في رنا جايين';

  @override
  String get findMechanicsFast => 'ابحث عن ميكانيكيين موثوقين بسرعة';

  @override
  String get emergencyInfo => 'في حالة الطوارئ، لا تتردد في الاتصال فوراً. سلامتك أولويتنا.';

  @override
  String get emergencyNumbers => 'أرقام الطوارئ';

  @override
  String get emptyComment => 'لا يمكن أن يكون التعليق فارغًا';

  @override
  String get empty_field_error => 'لا يمكن أن يكون هذا الحقل فارغًا';

  @override
  String get enRoute => 'في الطريق:';

  @override
  String get enable_notifications => 'سماح بالاشعارات';

  @override
  String get english => 'الإنجليزية';

  @override
  String enterCodeSentTo(Object phoneNumber) {
    return 'أدخل الرمز المرسل إلى $phoneNumber';
  }

  @override
  String get enterDescription => 'أدخل وصفًا (اختياري)';

  @override
  String get enterFeedback => 'أدخل تقييمك (اختياري)...';

  @override
  String get enterPartName => 'أدخل اسم القطعة';

  @override
  String get enterText => 'رجاءً أدخل النص';

  @override
  String get enterValidOtp => 'الرجاء إدخال رمز OTP صحيح مكون من 6 أرقام';

  @override
  String get enterVehicleBrand => 'أدخل ماركة المركبة';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get error => 'خطأ';

  @override
  String get errorAddress => 'خطأ في الحصول على العنوان';

  @override
  String get errorLoadingServices => 'حدث خطأ أثناء تحميل الخدمات';

  @override
  String get errorLocation => 'خطأ في الحصول على الموقع';

  @override
  String get errorMessage => 'حدث خطأ ما';

  @override
  String get errorRequest => 'فشل معالجة طلبك';

  @override
  String errorSendingOtp(Object error) {
    return 'فشل في إرسال رمز التحقق: $error';
  }

  @override
  String get errorUnexpected => 'خطأ غير متوقع';

  @override
  String get error_checking_location_permission => 'خطأ في التحقق من إذن الموقع';

  @override
  String get error_fetching_chats => 'خطأ في جلب الدردشات';

  @override
  String get error_fetching_driver_details => 'فشل في جلب تفاصيل المزود';

  @override
  String get error_fetching_gas_stations => 'فشل في جلب محطات الوقود';

  @override
  String get error_fetching_provider => 'خطأ في جلب تفاصيل مقدم الخدمة';

  @override
  String get error_fetching_stores => 'خطأ في جلب المتاجر';

  @override
  String get error_location_denied => 'تم رفض إذن الموقع';

  @override
  String get error_location_denied_forever => 'تم رفض إذن الموقع بشكل دائم';

  @override
  String get error_location_disabled => 'خدمة الموقع معطلة';

  @override
  String error_location_failed(Object error) {
    return 'تعذر الحصول على الموقع';
  }

  @override
  String get error_message_fetch_failed => 'فشل في جلب الرسائل: %s';

  @override
  String get error_message_send_failed => 'فشل في إرسال الرسالة: %s';

  @override
  String get error_phone_call => 'فشل إجراء المكالمة';

  @override
  String error_request_failed(Object error) {
    return 'فشل تقديم الطلب: $error';
  }

  @override
  String get error_request_save => 'فشل في حفظ الطلب';

  @override
  String error_request_status(Object error) {
    return 'خطأ في متابعة حالة الطلب: $error';
  }

  @override
  String error_search_failed(Object error) {
    return 'فشل البحث عن مقدم الخدمة: $error';
  }

  @override
  String get error_tracking_request => 'فشل في تتبع الطلب';

  @override
  String get error_user_location => 'فشل في الحصول على معلومات المستخدم أو الموقع';

  @override
  String get expand_search => 'توسيع البحث';

  @override
  String get expanding_search => 'توسيع نطاق البحث إلى';

  @override
  String get exteriorWash => 'غسيل خارجي';

  @override
  String get exterior_wash => 'غسيل خارجي';

  @override
  String get failed_phone_call => 'فشل في إجراء مكالمة هاتفية';

  @override
  String get failed_to_book_store => 'فشل في حجز المتجر';

  @override
  String get failed_to_cancel_request => 'فشل في إلغاء الطلب.';

  @override
  String get failed_to_create_request => 'فشل في إنشاء الطلب. جاري إعادة المحاولة...';

  @override
  String get failed_to_fetch_driver_details => 'فشل في جلب تفاصيل السائق';

  @override
  String get failed_to_get_address => 'فشل في جلب العنوان.';

  @override
  String get failed_to_get_location => 'فشل في الحصول على الموقع';

  @override
  String get failed_to_initialize => 'فشل في تهيئة التطبيق';

  @override
  String get failed_to_initialize_provider_search => 'فشل في تهيئة البحث عن مقدمي الخدمة.';

  @override
  String get failed_to_load_messages => 'فشل في تحميل رسائل الدردشة';

  @override
  String get failed_to_load_providers => 'فشل في تحميل مقدمي الخدمة.';

  @override
  String get failed_to_make_call => 'فشل في إجراء المكالمة';

  @override
  String get failed_to_monitor_status => 'فشل في مراقبة حالة الطلب';

  @override
  String get failed_to_notify_provider => 'فشل في إشعار مقدم الخدمة';

  @override
  String get failed_to_open_chat => 'فشل في فتح الدردشة';

  @override
  String get failed_to_receive_ride_updates => 'فشل في استقبال تحديثات الرحلة';

  @override
  String get failed_to_restore_state => 'فشل في استعادة الحالة';

  @override
  String get failed_to_search_providers => 'فشل في البحث عن مقدمي الخدمة.';

  @override
  String get failed_to_send_notification => 'فشل في إرسال الإشعار';

  @override
  String get failed_to_send_request => 'فشل في إرسال الطلب إلى مقدم الخدمة.';

  @override
  String get failed_to_start_chat => 'فشل في بدء الدردشة';

  @override
  String get failed_to_submit_request => 'فشل في إرسال الطلب';

  @override
  String get failed_to_sync => 'فشل في مزامنة البيانات';

  @override
  String get failed_to_sync_driver_data => 'فشل في مزامنة بيانات مقدم الخدمة';

  @override
  String get failed_to_update_location => 'فشل في تحديث الموقع';

  @override
  String get featureNotAvailable => 'ميزة قيد التطوير حالياً. نحن نعمل بجد لتوفيرها لك في أقرب وقت ممكن!';

  @override
  String get featuredOffer => 'عرض مميز';

  @override
  String get features => 'الميزات';

  @override
  String get feedback => 'التقييم';

  @override
  String get feedbackSuccess => 'تم إرسال تقييمك بنجاح. شكرًا لرأيك!';

  @override
  String get fetching_location => 'جاري جلب الموقع...';

  @override
  String get findYourRide => 'ابحث عن سيارتك';

  @override
  String get findingProvider => 'البحث عن مقدم خدمة';

  @override
  String get firstname => 'الاسم الأول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get freeDiagnostic => 'تشخيص مجاني';

  @override
  String get freeDiagnosticDesc => 'احصل على تشخيص مجاني لسيارتك هذا الأسبوع فقط!';

  @override
  String get french => 'الفرنسية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameOptional => 'الاسم الكامل';

  @override
  String get fullRepairTitle => 'إصلاح كامل';

  @override
  String get fullRepairType => 'تصليح شامل';

  @override
  String get fullWash => 'غسيل كامل';

  @override
  String get full_wash => 'غسيل كامل';

  @override
  String get gasStation => 'محطة وقود';

  @override
  String get gasStationDescription => 'خدمات الوقود والتسهيلات';

  @override
  String get gasStationTitle => 'محطة وقود';

  @override
  String get gas_station_selected => 'تم اختيار محطة الوقود';

  @override
  String get gendarmerie => 'الدرك الوطني';

  @override
  String get gendarmerieDescription => 'يهمنا سلامتك. فور حدوث أي طارئ، يمكنك الاتصال مباشرة أو إرسال تنبيه أو رسالة مع موقع تواجدك.';

  @override
  String get geoFireError => 'خطأ في تهيئة GeoFire.';

  @override
  String get glassRepairDescription => 'خدمات إصلاح الزجاج الأمامي والزجاج';

  @override
  String get glassRepairTitle => 'إصلاح الزجاج';

  @override
  String get go_back => 'العودة';

  @override
  String get goingToDestination => 'في الطريق إلى الوجهة - وقت الوصول: ';

  @override
  String get guest => 'ضيف';

  @override
  String get guides => 'مقالة';

  @override
  String get help => 'المساعدة';

  @override
  String get helpDescription => 'يبدو أنك تواجه مشكلة. نحن هنا لمساعدتك!\nلا تتردد في التواصل معنا عبر إرسال رسالة أو الاتصال بنا.';

  @override
  String get helpText => 'نص المساعدة';

  @override
  String get hide_stores => 'إخفاء المتاجر';

  @override
  String get highestRated => 'الأعلى تقييمًا';

  @override
  String get home => 'الرئيسية';

  @override
  String hours_ago(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعات',
      one: 'قبل ساعة واحدة',
      zero: 'قبل 0 ساعات',
    );
    return '$_temp0';
  }

  @override
  String get howCanWeHelp => 'كيف يمكننا مساعدتك؟';

  @override
  String get in_progress => 'جاري';

  @override
  String get info => 'معلومات';

  @override
  String get initializing_service => 'جارٍ تهيئة الخدمة...';

  @override
  String get interiorWash => 'غسيل داخلي';

  @override
  String get interior_wash => 'غسيل داخلي';

  @override
  String get invalidOtp => 'رمز التحقق غير صالح';

  @override
  String get invalid_service_type => 'نوع الخدمة غير صالح';

  @override
  String get inviteFriend => 'دعوة صديق';

  @override
  String get job => 'الوظيفة';

  @override
  String get just_now => 'الآن';

  @override
  String get keyProgrammingDescription => 'برمجة أو استبدال مفاتيح السيارة في الموقع';

  @override
  String get keyProgrammingTitle => 'برمجة مفاتيح السيارة';

  @override
  String get km => 'كم';

  @override
  String get languageChanged => 'تم تغيير اللغة بنجاح';

  @override
  String get lat => 'خط العرض';

  @override
  String get learnMore => 'تعرف على المزيد';

  @override
  String get like => 'إعجاب';

  @override
  String get likeError => 'حدث خطأ أثناء تحديث حالة الإعجاب';

  @override
  String get liked => 'تم الإعجاب بنجاح';

  @override
  String get lng => 'خط الطول';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get loadingAddress => 'جارٍ تحميل العنوان...';

  @override
  String get loadingCarFixesTips => 'جارٍ تحميل إصلاحات السيارات والنصائح...';

  @override
  String get loadingPosts => 'جاري تحميل المنشورات...';

  @override
  String get loadingTutorials => 'جارٍ تحميل الدروس...';

  @override
  String get loading_address => 'جاري تحميل العنوان...';

  @override
  String get locating => 'جارٍ تحديد الموقع...';

  @override
  String get location => 'الموقع';

  @override
  String get locationDisabled => 'خدمات الموقع معطلة. يرجى تفعيلها لعرض مقدم الخدمةين.';

  @override
  String get locationError => 'معلومات الموقع غير متوفرة.';

  @override
  String get locationFetchError => 'فشل في الحصول على الموقع.';

  @override
  String get locationFetchFailed => 'فشل في تحديد الموقع، حاول مرة أخرى';

  @override
  String get locationPermission => 'يرجى تفعيل إذن الموقع';

  @override
  String get locationPermissionDenied => 'يجب منح إذن الموقع.';

  @override
  String get locationPermissionDeniedForever => 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله في الإعدادات.';

  @override
  String get locationPermissionError => 'خطأ في التحقق من إذن الموقع.';

  @override
  String get locationPermissionPermanentlyDenied => 'تم رفض إذن الموقع بشكل دائم.';

  @override
  String get locationPermissionRequired => 'مطلوب إذن الموقع لاستخدام الخدمة';

  @override
  String get locationServiceDisabled => 'خدمات الموقع معطلة. يرجى تفعيلها.';

  @override
  String get locationServicesDisabled => 'خدمات الموقع معطلة. يرجى تفعيلها.';

  @override
  String get location_denied => 'تم رفض إذن الموقع. يرجى السماح بالوصول.';

  @override
  String get location_denied_forever => 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله في الإعدادات.';

  @override
  String get location_disabled => 'خدمات الموقع معطلة. يرجى تفعيلها.';

  @override
  String get location_error => 'خطأ في جلب الموقع. يرجى المحاولة مرة أخرى.';

  @override
  String get location_fetch_failed => 'فشل في الحصول على الموقع';

  @override
  String get location_permission_denied => 'تم رفض إذن الموقع.';

  @override
  String get location_permission_denied_forever => 'تم رفض إذن الموقع بشكل دائم.';

  @override
  String get location_permission_denied_permanently => 'تم رفض إذن الموقع بشكل دائم';

  @override
  String get location_permission_error => 'خطأ في إذن الموقع';

  @override
  String get location_permission_required => 'إذن الموقع مطلوب';

  @override
  String get location_selection => 'اختيار الموقع';

  @override
  String get location_service_disabled => 'خدمات الموقع معطلة';

  @override
  String get location_services_disabled => 'يرجى تفعيل خدمات الموقع.';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loginRequired => 'يرجى تسجيل الدخول للاشتراك';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutError => 'خطأ في تسجيل الخروج: @error';

  @override
  String get luxury => 'فاخرة';

  @override
  String get maintenanceCategory => 'الصيانة';

  @override
  String get map => 'خريطة';

  @override
  String get mapThemeError => 'فشل في تحميل نمط الخريطة.';

  @override
  String get map_label => 'خريطة تُظهر موقعك ومقدمي الخدمة القريبين';

  @override
  String get max_retries_reached => 'تم الوصول إلى الحد الأقصى للمحاولات للبحث.';

  @override
  String get mechanicServices => 'خدمات الميكانيكي';

  @override
  String get menu => 'القائمة';

  @override
  String get messageComingSoon => 'ميزة المراسلة قيد التطوير حالياً وسوف تكون متاحة قريباً. شكراً لصبركم!';

  @override
  String get messageSent => 'تم إرسال الرسالة';

  @override
  String get messageSuccess => 'تم إرسال رسالتك بنجاح. سيتم التواصل معك قريبًا.';

  @override
  String minutes_ago(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقائق',
      one: 'قبل دقيقة واحدة',
      zero: 'قبل 0 دقائق',
    );
    return '$_temp0';
  }

  @override
  String get mobile_car_wash => 'غسيل متنقل';

  @override
  String get mobile_car_wash_provider => 'مقدم خدمة غسيل سيارات متنقل';

  @override
  String get more_info_hint => 'أضف المزيد من المعلومات';

  @override
  String get motorcycle => 'دراجة نارية';

  @override
  String get motorcycles => 'الدراجات النارية';

  @override
  String get rating_submitted => 'تم تقديم التقييم';

  @override
  String get rating_queued => 'تمت إضافة التقييم إلى قائمة الانتظار، سيتم المزامنة عند الاتصال بالإنترنت';

  @override
  String get no_ratings => 'لا تقييمات بعد';

  @override
  String get failed_to_submit_rating => 'فشل في إرسال التقييم';

  @override
  String get name => 'الاسم';

  @override
  String get checkingNetwork => 'جارٍ التحقق من الاتصال بالشبكة...';

  @override
  String get loadingCachedData => 'جارٍ تحميل البيانات المحفوظة...';

  @override
  String get noInternetConnectionWithCache => 'لا يوجد اتصال بالإنترنت. استخدم الوضع غير المتصل بالبيانات المحفوظة سابقًا أو حاول مرة أخرى عند الاتصال.';

  @override
  String get useOffline => 'استخدام وضع عدم متصل';

  @override
  String get dataSynced => 'تم تحديث بياناتك.';

  @override
  String get syncFailed => 'فشل تحديث البيانات. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get message => 'ارسال رسالة';

  @override
  String get nearby_gas_stations => 'محطات الوقود القريبة';

  @override
  String get new_message_body => 'رسالة جديدة من';

  @override
  String get new_message_title => 'رسالة جديدة';

  @override
  String get new_request_at => 'جديد';

  @override
  String get next => 'التالي';

  @override
  String get no => 'لا';

  @override
  String get noAddressFound => 'لا يوجد عنوان لهذا الموقع';

  @override
  String get noCarFixesTips => 'لا يوجد محتوى متاح لهذه الفئة.';

  @override
  String get noDriversAvailable => 'لا يوجد مزودي خدمة متاحين';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noMatchingDriver => 'لم يتم العثور على سائق مطابق';

  @override
  String get noMatchingProvider => 'لم يتم العثور على مزود مطابق.';

  @override
  String get noPhone => 'لا يوجد رقم هاتف';

  @override
  String get noPosts => 'لا توجد منشورات متاحة';

  @override
  String get noProviderAvailable => 'لا يوجد مزود خدمة متاح حالياً';

  @override
  String get noProvidersAvailable => 'لا يوجد مزود خدمة متاح حالياً';

  @override
  String get noProvidersNearby => 'لا يوجد مزودين متاحين بالقرب.';

  @override
  String get noServicesFound => 'لم يتم العثور على خدمات';

  @override
  String get noTutorials => 'لا توجد دروس متاحة لهذه الفئة.';

  @override
  String get noVehicles => 'لم يتم العثور على سيارات';

  @override
  String get no_address => 'لا يوجد عنوان مقدم';

  @override
  String get no_cached_providers => 'لم يتم العثور على مقدمي خدمة مخزنين لهذه الخدمة.';

  @override
  String get no_chats_available => 'لا توجد دردشات متاحة';

  @override
  String get no_driver_assigned => 'لم يتم تعيين سائق بعد';

  @override
  String get no_drivers_available => 'لا يوجد مزودو خدمات متاحون بالقرب منك';

  @override
  String get no_gas_stations_available => 'لا توجد محطات وقود متاحة';

  @override
  String get no_provider_found => 'لم يتم العثور على مقدم خدمة';

  @override
  String get no_providers_available => 'لا يوجد مقدمو خدمة متاحون';

  @override
  String get no_providers_available_offline => 'لا يوجد مقدمو خدمة متاحون في وضع عدم الاتصال';

  @override
  String get no_providers_for => 'لا يوجد مزودون متاحون لـ';

  @override
  String get no_providers_found => 'لم يتم العثور على مقدمي خدمة بعد الحد الأقصى للمحاولات.';

  @override
  String get no_providers_found_searching => 'لم يتم العثور على مقدمي خدمة. مواصلة البحث...';

  @override
  String get no_results_found => 'لم يتم العثور على نتائج للبحث';

  @override
  String get no_stores_available => 'لا توجد متاجر متاحة لهذه الخدمة';

  @override
  String get not_available => 'غير متوفر';

  @override
  String get not_specified => 'غير محدد';

  @override
  String get notificationSent => 'تم إرسال الإشعار إلى مزودي الخدمة القريبين';

  @override
  String get notification_failed => 'فشل في إرسال الإشعار إلى مقدم الخدمة';

  @override
  String get notification_next_provider => 'البحث عن مقدم خدمة آخر';

  @override
  String get notification_sent_success => 'جارٍ التواصل مع مقدم الخدمة';

  @override
  String get notification_unavailable => 'الإشعار غير متاح.';

  @override
  String get notifications_title => 'الإبلاغات';

  @override
  String get offline_mode => 'وضع عدم الاتصال';

  @override
  String get offline_providers_available => 'مقدمو الخدمة المتاحون (غير متصل)';

  @override
  String get oilChange => 'تغيير الزيت';

  @override
  String get ok => 'موافق';

  @override
  String get or => 'أو';

  @override
  String get originAddress => 'عنوان الموقع';

  @override
  String get otpRequestTooSoon => 'الرجاء الانتظار قبل طلب رمز OTP آخر';

  @override
  String get otpSendFailed => 'فشل إرسال رمز OTP';

  @override
  String get otpSentSuccessfully => 'تم إرسال رمز OTP بنجاح';

  @override
  String get otpVerificationFailed => 'فشل التحقق من رمز OTP';

  @override
  String get partName => 'اسم الجزء';

  @override
  String get partNameError => 'يرجى إدخال اسم الجزء';

  @override
  String get password => 'كلمة المرور';

  @override
  String get phone => 'الهاتف';

  @override
  String get phoneNotAvailable => 'رقم الهاتف غير متاح';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneVerifiedMessage => 'تم التحقق من رقم هاتفك بنجاح.';

  @override
  String get phoneVerifiedSuccessfully => 'تم التحقق من الهاتف بنجاح';

  @override
  String get phone_not_available => 'رقم الهاتف غير متاح';

  @override
  String get pickupDate => 'تاريخ الاستلام';

  @override
  String get pleaseEnterName => 'الرجاء إدخال اسمك';

  @override
  String get pleaseEnterValidPhone => 'الرجاء إدخال رقم هاتف صحيح';

  @override
  String get pleaseSelectRating => 'يرجى اختيار تقييم قبل الإرسال.';

  @override
  String get pleaseWait => 'يرجى الانتظار قليلاً';

  @override
  String get police => 'الشرطة';

  @override
  String get policeDescription => 'يهمنا سلامتك. فور حدوث أي طارئ، يمكنك الاتصال مباشرة أو إرسال تنبيه أو رسالة مع موقع تواجدك.';

  @override
  String get popularProducts => 'الخدمات الأساسية';

  @override
  String get popularServices => 'الخدمات الاساسية ';

  @override
  String get postDeleteError => 'حدث خطأ أثناء حذف المنشور';

  @override
  String get postDeleted => 'تم حذف المنشور بنجاح';

  @override
  String get postUpdateError => 'حدث خطأ أثناء تحديث المنشور';

  @override
  String get postUpdated => 'تم تحديث المنشور بنجاح';

  @override
  String get pothole_report_category => 'حفرة';

  @override
  String get pothole_report_description => 'الإبلاغ عن حفرة لتحسين سلامة الطرق';

  @override
  String get powerfulTruck => 'شاحنة قوية';

  @override
  String get priceHighToLow => 'السعر: من الأعلى إلى الأقل';

  @override
  String get priceLowToHigh => 'السعر: من الأقل إلى الأعلى';

  @override
  String get pricePerDay => 'السعر اليومي';

  @override
  String get primaryServices => 'الخدمات الأساسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get promotions => 'العروض الترويجية';

  @override
  String get provider => 'مقدم الخدمة';

  @override
  String get providerArrived => 'وصل مقدم الخدمة';

  @override
  String get providerOnWay => 'مقدم الخدمة في طريقه';

  @override
  String get provider_assigned => 'تم تعيين مقدم الخدمة';

  @override
  String get provider_assigned_body => 'مقدم الخدمة';

  @override
  String get provider_declined => 'رفض مزودو الخدمة الطلب. جارٍ المحاولة مع مزودين آخرين...';

  @override
  String get provider_details => 'تفاصيل مقدم الخدمة';

  @override
  String get provider_location => 'موقع مقدم الخدمة';

  @override
  String get provider_no_service => 'مقدم الخدمة لا يقدم هذه الخدمة';

  @override
  String get provider_not_found => 'لم يتم العثور على مقدم الخدمة في البيانات المخزنة';

  @override
  String get provider_notification_unavailable => 'مقدم الخدمة';

  @override
  String get provider_on_way => 'مقدم الخدمة في الطريق';

  @override
  String get provider_timeout => 'لم يستجب مزودو الخدمة. جارٍ المحاولة مع مزودين آخرين...';

  @override
  String get providers => 'مقدمي الخدمة';

  @override
  String get providers_declined => 'رفض مقدمو الخدمة. جاري المحاولة مع مقدمين آخرين...';

  @override
  String get providers_no_response => 'لم يستجب مقدمو الخدمة. جاري المحاولة مع مقدمين آخرين...';

  @override
  String get reachingTimeError => 'خطأ في تحديث وقت الوصول إلى الوجهة.';

  @override
  String get refresh => 'تحديث';

  @override
  String get register => 'تسجيل';

  @override
  String get rentVehicles => 'تأجير المركبات';

  @override
  String get repairCategory => 'الإصلاح';

  @override
  String get report_category => 'ساهم في تسريع اصلاح الطرقات بالتبيغ عنها';

  @override
  String get report_pothole => 'الإبلاغ عن حفرة';

  @override
  String get reports_label => 'تقارير';

  @override
  String get requestCarWash => 'طلب غسيل سيارة';

  @override
  String get requestDelivery => 'طلب التوصيل';

  @override
  String get requestError => 'فشل في حفظ الطلب.';

  @override
  String get requestPickup => 'طلب الاستلام';

  @override
  String get requestSent => 'تم إرسال الطلب إلى المزود.';

  @override
  String get requestService => 'طلب الخدمة';

  @override
  String get requestSubmitted => 'تم تقديم الطلب';

  @override
  String get request_accepted => 'تم قبول الطلب من قبل مزود الخدمة!';

  @override
  String get request_accepted_body => 'تم قبول طلبك من قبل';

  @override
  String get request_accepted_title => 'تم قبول الطلب';

  @override
  String get request_at => 'طلب في';

  @override
  String get request_cancelled => 'تم إلغاء الطلب.';

  @override
  String get request_cancelled_message => 'تم إلغاء طلب الخدمة';

  @override
  String get request_delivery => 'طلب التوصيل';

  @override
  String get request_details => 'تفاصيل الطلب';

  @override
  String get request_details_error => 'يرجى تقديم تفاصيل الطلب';

  @override
  String get request_pickup => 'طلب الاستلام';

  @override
  String get request_queued => 'تمت إضافة الطلب إلى قائمة الانتظار ليتم إرساله عند الاتصال بالإنترنت';

  @override
  String get request_service => 'طلب الخدمة';

  @override
  String get request_service_button => 'زر طلب الخدمة';

  @override
  String get request_stored => 'تم تخزين الطلب لـ';

  @override
  String get request_timeout => 'انتهت مهلة الطلب';

  @override
  String get request_type => 'نوع الطلب';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendInSeconds(Object seconds) {
    return 'إعادة الإرسال بعد $seconds ثانية';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get retry_connection_button => 'زر إعادة المحاولة للاتصال';

  @override
  String get retrying_location => 'جاري إعادة محاولة جلب الموقع...';

  @override
  String get returnDate => 'تاريخ التسليم';

  @override
  String get reviews => 'مراجعات';

  @override
  String get ride_cancelled_or_ended => 'تم إلغاء الرحلة أو انتهت';

  @override
  String get ride_info_not_found => 'بيانات الرحلة غير متوفرة';

  @override
  String get ride_status_updated => 'تم تحديث حالة الرحلة';

  @override
  String get road_issue_report_title => 'الإبلاغ عن حفرة';

  @override
  String get roadsideAssistance => 'المساعدة على الطريق';

  @override
  String get routineMaintenanceDescription => 'خدمات صيانة المركبة الدورية';

  @override
  String get routineMaintenanceTitle => 'الصيانة الروتينية';

  @override
  String get save => 'حفظ';

  @override
  String get saveData => 'حفظ التأجير';

  @override
  String get savedInformation => 'المعلومات المحفوظة';

  @override
  String get schedule_date => 'تاريخ الجدولة';

  @override
  String get schedule_date_error => 'يرجى اختيار تاريخ';

  @override
  String get schedule_time => 'وقت الجدولة';

  @override
  String get schedule_time_error => 'يرجى اختيار وقت';

  @override
  String get scheduled => 'مجدول';

  @override
  String get search => 'بحث';

  @override
  String get searchAgain => 'يرجى المحاولة مرة أخرى لاحقًا';

  @override
  String get searchServices => 'البحث عن الخدمات';

  @override
  String get searchVehicles => 'البحث عن السيارات';

  @override
  String get search_continued => 'مواصلة البحث عن مقدمي الخدمة...';

  @override
  String get search_error => 'خطأ في البحث عن مزودين';

  @override
  String get search_error_try_again => 'خطأ في البحث. الرجاء المحاولة مرة أخرى.';

  @override
  String get search_location => 'البحث عن موقع';

  @override
  String get searchingForProvider => 'البحث عن مقدم الخدمة';

  @override
  String get searching_for => 'البحث عن';

  @override
  String get searching_for_another_driver => 'جارٍ البحث عن سائق آخر...';

  @override
  String get searching_for_driver => 'جاري البحث عن مقدم الخدمة...';

  @override
  String get searching_for_provider => 'جاري البحث عن مقدم الخدمة';

  @override
  String get searching_offline => 'جارٍ البحث دون اتصال...';

  @override
  String get secondaryServices => 'الخدمات الثانوية';

  @override
  String get seeMore => 'عرض المزيد';

  @override
  String get select => 'اختر';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get selectLocationFirst => 'يرجى تحديد الموقع أولاً';

  @override
  String get selectNumber => 'اختر رقماً للاتصال:';

  @override
  String get selectService => 'يرجى اختيار خدمة.';

  @override
  String get selectServicePrompt => 'يرجى اختيار خدمة';

  @override
  String get selectVehicleType => 'اختر نوع المركبة';

  @override
  String get select_gas_station => 'اختر';

  @override
  String get select_location_first => 'يرجى اختيار الموقع أولاً.';

  @override
  String get select_provider_to_contact => 'اختر مقدم خدمة للتواصل معه مباشرة';

  @override
  String get selfDrive => 'قيادة ذاتية';

  @override
  String get send => 'إرسال';

  @override
  String get sendAlert => 'هل تريد فعلاً إرسال تنبيه؟';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String get service => 'الخدمة';

  @override
  String get serviceCategories => 'خدمات الطوارئ';

  @override
  String get serviceDescription => 'خدمة سحب السيارات إلى الموقع المطلوب';

  @override
  String get serviceTypeError => 'يرجى اختيار نوع الخدمة';

  @override
  String get service_description => 'اطلب هذه الخدمة في موقعك';

  @override
  String get service_not_available => 'الخدمة غير متوفرة';

  @override
  String get service_not_available_message => 'هذه الخدمة قيد الصيانة حاليًا. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get service_provider => 'مزود الخدمة';

  @override
  String get service_type => 'نوع الخدمة';

  @override
  String get services => 'الخدمات';

  @override
  String servicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متاح $count خدمة',
      many: 'متاح $count خدمة',
      few: 'متاح $count خدمات',
      two: 'خدمتان متاحتان',
      one: 'خدمة واحدة متاحة',
      zero: 'لا توجد خدمات متاحة',
    );
    return '$_temp0';
  }

  @override
  String get setLocationButton => 'تحديد الموقع';

  @override
  String get settings => 'الاعدادات';

  @override
  String get severity_high => 'عالية';

  @override
  String get trip_ended => 'انتهت الرحلة';

  @override
  String get trip_ended_message => 'لقد انتهت رحلتك. يرجى تقييم الخدمة.';

  @override
  String get rate_service => 'تقييم الخدمة';

  @override
  String get error_invalid_coordinates => 'الإحداثيات المقدمة غير صالحة';

  @override
  String get error_api_key_missing => 'مفتاح واجهة برمجة التطبيقات غير موجود';

  @override
  String get switch_to_stationary => 'switch_to_stationary';

  @override
  String get switch_to_mobile => 'switch_to_mobile';

  @override
  String get error_fetching_directions => 'فشل في جلب الاتجاهات';

  @override
  String get comments_optional => 'التعليقات (اختيارية)';

  @override
  String get enter_comments => 'أدخل تعليقاتك هنا';

  @override
  String get rating_submitted_message => 'شكرًا على ملاحظاتك!';

  @override
  String get error_submitting_rating => 'فشل في تقديم التقييم. حاول مرة أخرى.';

  @override
  String get chat_synced => 'تم مزامنة الدردشة';

  @override
  String get chat_synced_message => 'تمت مزامنة الدردشة بنجاح.';

  @override
  String get trip_cancelled => 'تم إلغاء الرحلة';

  @override
  String get trip_cancelled_message => 'لقد تم إلغاء رحلتك.';

  @override
  String get call_initiated => 'تم بدء المكالمة';

  @override
  String get call_initiated_message => 'جارٍ الاتصال بالمزود.';

  @override
  String get share => 'مشاركة';

  @override
  String get shareError => 'حدث خطأ أثناء مشاركة المنشور';

  @override
  String get sharePostText => 'تحقق من هذا المنشور الرائع!';

  @override
  String get shopNow => 'تسوق الآن';

  @override
  String get show_stores => 'إظهار المتاجر';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get sort_by_distance => 'الفرز حسب المسافة';

  @override
  String get sort_by_name => 'الفرز حسب الاسم';

  @override
  String get sort_providers => 'فرز مقدمي الخدمة';

  @override
  String get sparePartsDescription => 'قطع غيار عالية الجودة لمركبتك';

  @override
  String get sparePartsTitle => 'قطع الغيار';

  @override
  String get sparePartsType => 'بيع قطع غيار';

  @override
  String get sportyMotorcycle => 'دراجة نارية رياضية';

  @override
  String get stationary_car_wash => 'غسيل ثابت';

  @override
  String get status => 'الحالة';

  @override
  String get store => 'المتجر';

  @override
  String get store_service_description => 'اختر متجرًا أو اختر التوصيل لاحتياجات خدمتك';

  @override
  String get subscribe => 'اشتراك';

  @override
  String get subscribed => 'تم الاشتراك بنجاح';

  @override
  String get subscriptionError => 'حدث خطأ أثناء تحديث حالة الاشتراك';

  @override
  String get success => 'نجاح!';

  @override
  String get support => 'الدعم';

  @override
  String get suv => 'دفع رباعي';

  @override
  String get tags => 'الوسوم';

  @override
  String get tags_hint => 'أدخل الوسوم، مفصولة بفواصل (مثال: #إصلاح_سيارات، #صيانة)';

  @override
  String get take_photo => 'التقاط صورة';

  @override
  String get taxDisclaimer => 'الأسعار قد لا تشمل الضرائب والرسوم';

  @override
  String get termsAndConditions => 'بالمتابعة، فإنك توافق على الشروط والأحكام الخاصة بنا.';

  @override
  String get testimonial1 => 'خدمة مذهلة! تم إصلاح سيارتي في وقت قصير.';

  @override
  String get testimonial2 => 'موثوق وميسور التكلفة. أوصي به بشدة!';

  @override
  String get testimonials => 'الشهادات';

  @override
  String get text => 'الرسالة';

  @override
  String get thankYou => 'شكرًا';

  @override
  String get thankYouPatience => 'شكراً لصبرك!';

  @override
  String get time => 'الوقت';

  @override
  String get timeoutError => 'انتهت مهلة الطلب. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';

  @override
  String get tireRepair => 'إصلاح الإطارات';

  @override
  String get tireRepairDescription => 'خدمة إصلاح الإطارات في الموقع';

  @override
  String get tireRepairTitle => 'إصلاح الإطارات';

  @override
  String get title => 'عنوان';

  @override
  String get totalFor => 'الإجمالي لـ';

  @override
  String get towTruckDescription => 'سحب السيارة إلى الموقع المطلوب';

  @override
  String get towTruckTitle => 'خدمة سحب السيارات';

  @override
  String get towTruckType => 'حاملة';

  @override
  String get towingService => 'خدمة السحب';

  @override
  String get trip_cancelled_or_ended => 'تم إلغاء الرحلة أو انتهت';

  @override
  String get trip_in_progress => 'الخدمة قيد التنفيذ';

  @override
  String get truck => 'شاحنة';

  @override
  String get trucks => 'شاحنات';

  @override
  String get tryDifferentCityOrDate => 'جرب مدينة أو تاريخ آخر!';

  @override
  String get tryDifferentDate => 'جرب تاريخ آخر';

  @override
  String get tutorials => 'الدروس';

  @override
  String get type_message => 'ارسل رسالة';

  @override
  String get unable_to_create_request => 'غير قادر على إنشاء الطلب. يرجى المحاولة لاحقًا.';

  @override
  String get unable_to_get_location => 'غير قادر على جلب الموقع. استخدام الموقع الافتراضي.';

  @override
  String get understood => 'فهمت';

  @override
  String get unknown => 'غير معروف';

  @override
  String get unknownAddress => 'عنوان غير معروف';

  @override
  String get unknownLocation => 'غير معروف';

  @override
  String get unknownNumber => 'رقم غير معروف';

  @override
  String get unknownService => 'خدمة غير معروفة';

  @override
  String get unknown_location => 'موقع غير معروف';

  @override
  String get unlike => 'إلغاء الإعجاب';

  @override
  String get unliked => 'تم إلغاء الإعجاب بنجاح';

  @override
  String get unspecified => 'غير محدد';

  @override
  String get unsubscribe => 'إلغاء الاشتراك';

  @override
  String get unsubscribed => 'تم إلغاء الاشتراك بنجاح';

  @override
  String get upload_failed => 'فشل في رفع الصورة';

  @override
  String get urgent => 'عاجل';

  @override
  String get urgent_request => 'طلب عاجل';

  @override
  String get urlError => 'غير قادر على فتح المحتوى. يرجى المحاولة مرة أخرى.';

  @override
  String get user1 => 'جون دو';

  @override
  String get user2 => 'جين سميث';

  @override
  String get userInfoError => 'فشل في الحصول على معلومات المستخدم.';

  @override
  String get userLocationFetchFailed => 'فشل في جلب بيانات المستخدم أو الموقع';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get vehicle => 'السيارة';

  @override
  String get vehicleBrand => 'ماركة السيارة';

  @override
  String get vehicleBrandError => 'يرجى إدخال ماركة السيارة';

  @override
  String get vehicleType => 'نوع المركبة';

  @override
  String get vehicleTypeError => 'يرجى اختيار نوع المركبة';

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String verificationFailed(Object error) {
    return 'فشل التحقق: $error';
  }

  @override
  String get videos => 'فيديوهات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String views(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشاهدات',
      one: 'مشاهدة واحدة',
      zero: '0 مشاهدات',
    );
    return '$_temp0';
  }

  @override
  String get waiting => 'في انتظار';

  @override
  String get waiting_for_confirmation => 'تم إرسال طلبك، يرجى الانتظار لتأكيد مقدم الخدمة';

  @override
  String get washType => 'نوع الغسيل';

  @override
  String get washTypeError => 'يرجى اختيار نوع الغسيل';

  @override
  String get wash_type => 'نوع الغسيل';

  @override
  String get wash_type_error => 'يرجى تحديد نوع الغسيل';

  @override
  String get weAreComing => 'رانا جايين';

  @override
  String get weAreHereToHelp => 'نحن هنا للمساعدة';

  @override
  String get welcome => 'مرحباً';

  @override
  String get wheelChangeDescription => 'إصلاح أو استبدال الإطارات في موقعك';

  @override
  String get wheelChangeTitle => 'تغيير أو إصلاح الإطارات';

  @override
  String get wheelChangeType => 'تغيير عجلات';

  @override
  String get whoWeAre => 'من نحن';

  @override
  String get willContact => 'سنتصل بك قريبًا بتفاصيل الخدمة';

  @override
  String get withDriver => 'مع سائق';

  @override
  String get writeHere => 'اكتب هنا';

  @override
  String get year => 'السنة';

  @override
  String get yes => 'نعم';

  @override
  String get yourLocation => 'موقعك الحالي';

  @override
  String get yourOpinionMatters => 'رأيك يهمنا لذا عبر بكل راحة.';

  @override
  String get your_location => 'موقعك';

  @override
  String get zoom_in => 'تكبير';

  @override
  String get zoom_out => 'تصغير';

  @override
  String get openMenu => 'ⴰⵣⵎⵎⴰⵎ';

  @override
  String get view_providers => 'عرض المزودين المخزنين';

  @override
  String get cached_providers => 'المزودين المخزنين';

  @override
  String get offline_request_not_allowed => 'لا يمكن إرسال الطلب في الوضع غير المتصل. عرض المزودين المخزنين بدلاً من ذلك.';

  @override
  String get no_cached_providers_available => 'لا توجد مزودات مخزنة متاحة.';

  @override
  String greetingPersonal(Object userName) {
    return 'مرحبًا $userName';
  }

  @override
  String get noVideosFound => 'No videos found. Try again later.';

  @override
  String get videoLoadError => 'Unable to load video. Please try again.';

  @override
  String get invalidPhoneNumber => 'رقم الهاتف غير صالح. يرجى التحقق وإعادة المحاولة.';

  @override
  String get tooManyRequests => 'طلبات كثيرة جدًا. يرجى الانتظار قبل المحاولة مرة أخرى.';

  @override
  String get otpExpired => 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.';

  @override
  String nearby_stores(Object serviceTitle) {
    return '$serviceTitle القريبة';
  }

  @override
  String get quotaExceededError => 'طلبات OTP كثيرة جدًا. حاول لاحقًا أو استخدم طريقة أخرى.';

  @override
  String get greetingAvailability => 'وين ما كنتو رانا كاينين';

  @override
  String get greetingSupport => 'ادعمنا لنتطور و نتوسع اكثر';

  @override
  String get marketingSlogan => 'تعطلت في أي مكان؟ رنا جايين تجلب المساعدة بسرعة.';
}
