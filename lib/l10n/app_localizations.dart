import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_kab.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('kab')
  ];

  /// Message requesting location access permission
  ///
  /// In en, this message translates to:
  /// **'Please allow location access to find nearby service providers'**
  String get locationPermissionMessage;

  /// Text for the allow permission button
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Text for the button to navigate to the login screen after maximum attempts
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// Error message for server timeout during authentication check
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get serverTimeout;

  /// Generic error message for authentication failure
  ///
  /// In en, this message translates to:
  /// **'Failed to verify login. Try again.'**
  String get authError;

  /// Text displayed on the loading screen during authentication check
  ///
  /// In en, this message translates to:
  /// **'Checking login status...'**
  String get checkingLoginStatus;

  /// Title for the first screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'Smart Assistance'**
  String get welcome1Title;

  /// Description for the first screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'A smart app that helps you fix \nvehicle breakdowns'**
  String get welcome1Desc;

  /// Title for the second screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'Expert Technicians'**
  String get welcome2Title;

  /// Description for the second screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'We provide the most experienced \nand nearest technicians to get you out of trouble'**
  String get welcome2Desc;

  /// Title for the third screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'Additional Services'**
  String get welcome3Title;

  /// Description for the third screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'You can also benefit from our additional services \nlike reporting and car rental...'**
  String get welcome3Desc;

  /// Title for the fourth screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get welcome4Title;

  /// Description for the fourth screen in the app introduction
  ///
  /// In en, this message translates to:
  /// **'We are with you wherever you are \nIf you want to save time and money, choose us'**
  String get welcome4Desc;

  /// Text for the continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Text for the next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Text for the skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// Label for an anonymous user
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymous_user;

  /// Message when no chats are found
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get no_chats_found;

  /// Message when a message is queued
  ///
  /// In en, this message translates to:
  /// **'Message queued'**
  String get message_queued;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutUsDesc.
  ///
  /// In en, this message translates to:
  /// **'We connect you with trusted car repair professionals to get you back on the road quickly.'**
  String get aboutUsDesc;

  /// No description provided for @acRepair.
  ///
  /// In en, this message translates to:
  /// **'AC Repair'**
  String get acRepair;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a Comment'**
  String get addComment;

  /// No description provided for @add_content.
  ///
  /// In en, this message translates to:
  /// **'Add Content'**
  String get add_content;

  /// Button label for adding image from gallery
  ///
  /// In en, this message translates to:
  /// **'Add from Gallery'**
  String get add_from_gallery;

  /// No description provided for @additionalFeedback.
  ///
  /// In en, this message translates to:
  /// **'Additional Feedback'**
  String get additionalFeedback;

  /// Label for additional information input field
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additional_info;

  /// No description provided for @addressError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch address'**
  String get addressError;

  /// No description provided for @addressFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve address.'**
  String get addressFetchError;

  /// No description provided for @addressFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch address, please try again'**
  String get addressFetchFailed;

  /// Error message for address fetching failure
  ///
  /// In en, this message translates to:
  /// **'Error fetching address. Please try again.'**
  String get address_error;

  /// No description provided for @advice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get advice;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @alertComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The emergency alert feature is currently under development and will be available in an upcoming update. Thank you for your understanding!'**
  String get alertComingSoon;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Title for all services page
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @all_providers_busy.
  ///
  /// In en, this message translates to:
  /// **'All available providers are busy'**
  String get all_providers_busy;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// No description provided for @ambulanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Your safety matters. In case of an emergency, you can call directly or send an alert or message with your location.'**
  String get ambulanceDescription;

  /// No description provided for @apiBlockedError.
  ///
  /// In en, this message translates to:
  /// **'YouTube API is currently blocked. Please try again later or contact support.'**
  String get apiBlockedError;

  /// No description provided for @apiInvalidError.
  ///
  /// In en, this message translates to:
  /// **'YouTube API key is invalid. Please contact support.'**
  String get apiInvalidError;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'An app offering a range of services for all road users and car owners.'**
  String get appDescription;

  /// Accessibility label for the app logo image
  ///
  /// In en, this message translates to:
  /// **'We Are Coming Logo'**
  String get appLogo;

  /// No description provided for @appRating.
  ///
  /// In en, this message translates to:
  /// **'Rate Our App'**
  String get appRating;

  /// Label for the appointment time selection
  ///
  /// In en, this message translates to:
  /// **'Appointment Time'**
  String get appointmentTime;

  /// Error message for missing appointment time selection
  ///
  /// In en, this message translates to:
  /// **'Please select an appointment time'**
  String get appointmentTimeError;

  /// Message shown when an appointment is booked
  ///
  /// In en, this message translates to:
  /// **'Appointment Booked'**
  String get appointment_booked;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @arrivalTimeError.
  ///
  /// In en, this message translates to:
  /// **'Error updating arrival time.'**
  String get arrivalTimeError;

  /// No description provided for @articles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @assigned_provider_info.
  ///
  /// In en, this message translates to:
  /// **'Assigned Provider Information'**
  String get assigned_provider_info;

  /// No description provided for @assigned_to_request.
  ///
  /// In en, this message translates to:
  /// **'Assigned to your request!'**
  String get assigned_to_request;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed: {error}'**
  String authenticationFailed(Object error);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available Providers'**
  String get available;

  /// Label for back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Description for battery charge service
  ///
  /// In en, this message translates to:
  /// **'On-site car battery charging or replacement'**
  String get batteryChargeDescription;

  /// Title for battery charge service
  ///
  /// In en, this message translates to:
  /// **'Battery Charge or Replacement'**
  String get batteryChargeTitle;

  /// No description provided for @batteryChargeType.
  ///
  /// In en, this message translates to:
  /// **'Battery Charge'**
  String get batteryChargeType;

  /// No description provided for @batteryReplacement.
  ///
  /// In en, this message translates to:
  /// **'Battery Replacement'**
  String get batteryReplacement;

  /// No description provided for @becauseWeCome.
  ///
  /// In en, this message translates to:
  /// **'Because we come to you with what you need, anytime, anywhere.'**
  String get becauseWeCome;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// Message shown when a booking is confirmed
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// Title for booking summary section
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get bookingSummary;

  /// No description provided for @brakeRepair.
  ///
  /// In en, this message translates to:
  /// **'Brake Repair'**
  String get brakeRepair;

  /// No description provided for @brakeServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Brake system repair and maintenance for safety.'**
  String get brakeServiceDescription;

  /// No description provided for @brakeServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Brake Repair'**
  String get brakeServiceTitle;

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @browse_posts.
  ///
  /// In en, this message translates to:
  /// **'Browse Posts'**
  String get browse_posts;

  /// Label for the call button
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call Provider'**
  String get callDriver;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Failed to make phone call.'**
  String get callError;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to make call'**
  String get callFailed;

  /// No description provided for @callProvider.
  ///
  /// In en, this message translates to:
  /// **'Call Provider'**
  String get callProvider;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @call_now.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get call_now;

  /// No description provided for @call_provider.
  ///
  /// In en, this message translates to:
  /// **'Call Provider'**
  String get call_provider;

  /// No description provided for @call_provider_button.
  ///
  /// In en, this message translates to:
  /// **'Call Provider Button'**
  String get call_provider_button;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @cancelService.
  ///
  /// In en, this message translates to:
  /// **'Cancel Service'**
  String get cancelService;

  /// No description provided for @cancel_request.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancel_request;

  /// No description provided for @cancel_request_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request Button'**
  String get cancel_request_button;

  /// No description provided for @cannot_make_call.
  ///
  /// In en, this message translates to:
  /// **'Unable to make a call to'**
  String get cannot_make_call;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// Description for car AC service
  ///
  /// In en, this message translates to:
  /// **'Car AC system repair or recharge'**
  String get carACServiceDescription;

  /// Title for car AC service
  ///
  /// In en, this message translates to:
  /// **'Car AC Service'**
  String get carACServiceTitle;

  /// Description for car electrician service
  ///
  /// In en, this message translates to:
  /// **'Diagnosis and repair of car electrical systems'**
  String get carElectricianDescription;

  /// Title for car electrician service
  ///
  /// In en, this message translates to:
  /// **'Car Electrician'**
  String get carElectricianTitle;

  /// No description provided for @carFixesTips.
  ///
  /// In en, this message translates to:
  /// **'Car Fixes & Tips'**
  String get carFixesTips;

  /// Description for car inspection service
  ///
  /// In en, this message translates to:
  /// **'Comprehensive car inspection before purchase or periodically'**
  String get carInspectionDescription;

  /// Title for car inspection service
  ///
  /// In en, this message translates to:
  /// **'Car Inspection'**
  String get carInspectionTitle;

  /// Description for car mechanic service
  ///
  /// In en, this message translates to:
  /// **'General car mechanical repairs at your location'**
  String get carMechanicDescription;

  /// Title for car mechanic service
  ///
  /// In en, this message translates to:
  /// **'Car Mechanic'**
  String get carMechanicTitle;

  /// No description provided for @carRental.
  ///
  /// In en, this message translates to:
  /// **'Car Rental'**
  String get carRental;

  /// No description provided for @carRentalDescription.
  ///
  /// In en, this message translates to:
  /// **'Convenient car rental services'**
  String get carRentalDescription;

  /// No description provided for @carRentalTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Rental'**
  String get carRentalTitle;

  /// No description provided for @carUnlock.
  ///
  /// In en, this message translates to:
  /// **'Car Unlock'**
  String get carUnlock;

  /// Title for the car wash service page
  ///
  /// In en, this message translates to:
  /// **'Car Wash'**
  String get carWash;

  /// No description provided for @carWashDescription.
  ///
  /// In en, this message translates to:
  /// **'Professional car cleaning services'**
  String get carWashDescription;

  /// No description provided for @carWashTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Wash'**
  String get carWashTitle;

  /// No description provided for @cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get cars;

  /// No description provided for @cashback.
  ///
  /// In en, this message translates to:
  /// **'20% Cashback'**
  String get cashback;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @center_map.
  ///
  /// In en, this message translates to:
  /// **'Center Map on My Location'**
  String get center_map;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change Address'**
  String get changeAddress;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @changeLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocationTitle;

  /// Label for change phone number button
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhoneNumber;

  /// Label for the change address button
  ///
  /// In en, this message translates to:
  /// **'Change Address'**
  String get change_address;

  /// No description provided for @change_location.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get change_location;

  /// No description provided for @change_location_button.
  ///
  /// In en, this message translates to:
  /// **'Change Location Button'**
  String get change_location_button;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat Now'**
  String get chatNow;

  /// Message shown when a chat is initiated for a specific service
  ///
  /// In en, this message translates to:
  /// **'Chat initiated for {serviceTitle}'**
  String chat_initiated(Object serviceTitle);

  /// No description provided for @chat_queued.
  ///
  /// In en, this message translates to:
  /// **'Chat queued to be sent when internet is available'**
  String get chat_queued;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @civilProtection.
  ///
  /// In en, this message translates to:
  /// **'Civil Protection'**
  String get civilProtection;

  /// No description provided for @civilProtectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Your safety matters. In case of an emergency, you can call directly or send an alert or message with your location.'**
  String get civilProtectionDescription;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @comfortableSedan.
  ///
  /// In en, this message translates to:
  /// **'Comfortable Sedan'**
  String get comfortableSedan;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @commentError.
  ///
  /// In en, this message translates to:
  /// **'Error posting comment'**
  String get commentError;

  /// No description provided for @commentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted successfully'**
  String get commentPosted;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Message for complete registration screen
  ///
  /// In en, this message translates to:
  /// **'Enter your details to get started.'**
  String get completeRegistrationMessage;

  /// Label for confirm OTP button
  ///
  /// In en, this message translates to:
  /// **'Confirm Code'**
  String get confirmCode;

  /// No description provided for @confirmDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Post'**
  String get confirmDeletePost;

  /// No description provided for @confirmDeletePostMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post? This action cannot be undone.'**
  String get confirmDeletePostMessage;

  /// No description provided for @confirmSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Confirm Subscribe'**
  String get confirmSubscribe;

  /// No description provided for @confirmSubscribeMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to subscribe to this user\'s content?'**
  String get confirmSubscribeMessage;

  /// No description provided for @confirmUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Confirm Unsubscribe'**
  String get confirmUnsubscribe;

  /// No description provided for @confirmUnsubscribeMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to unsubscribe from this user\'s content?'**
  String get confirmUnsubscribeMessage;

  /// Title for OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Confirm Verification Code'**
  String get confirmVerificationCode;

  /// No description provided for @connection_restored.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get connection_restored;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactProvider.
  ///
  /// In en, this message translates to:
  /// **'Contacting'**
  String get contactProvider;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @contact_provider_button.
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get contact_provider_button;

  /// No description provided for @contacting_driver.
  ///
  /// In en, this message translates to:
  /// **'Contacting driver'**
  String get contacting_driver;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'dz'**
  String get currency;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dataError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data.'**
  String get dataError;

  /// No description provided for @dataSavedError.
  ///
  /// In en, this message translates to:
  /// **'Error saving data: {error}'**
  String dataSavedError(Object error);

  /// No description provided for @dataSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully'**
  String get dataSavedSuccess;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Error message for missing date selection
  ///
  /// In en, this message translates to:
  /// **'Please select a wash date'**
  String get dateError;

  /// Label for the date of wash selection
  ///
  /// In en, this message translates to:
  /// **'Date of Wash'**
  String get dateOfWash;

  /// Label for number of days in booking
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Format for days ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{0 days ago} one{1 day ago} other{{count} days ago}}'**
  String days_ago(num count);

  /// No description provided for @defaultSort.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultSort;

  /// No description provided for @default_location.
  ///
  /// In en, this message translates to:
  /// **'Default Location (Algeria)'**
  String get default_location;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @delivery_option.
  ///
  /// In en, this message translates to:
  /// **'Delivery Option'**
  String get delivery_option;

  /// No description provided for @delivery_option_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether you want the service delivered to you'**
  String get delivery_option_subtitle;

  /// No description provided for @desc_bmw_r1250gs.
  ///
  /// In en, this message translates to:
  /// **'Touring motorcycle with luxury features'**
  String get desc_bmw_r1250gs;

  /// No description provided for @desc_chevrolet_silverado.
  ///
  /// In en, this message translates to:
  /// **'Large truck with strong towing capacity'**
  String get desc_chevrolet_silverado;

  /// No description provided for @desc_ford_f150.
  ///
  /// In en, this message translates to:
  /// **'Pickup truck with robust capabilities'**
  String get desc_ford_f150;

  /// No description provided for @desc_ford_mustang.
  ///
  /// In en, this message translates to:
  /// **'Powerful American car with outstanding performance'**
  String get desc_ford_mustang;

  /// No description provided for @desc_harley_sportster.
  ///
  /// In en, this message translates to:
  /// **'Classic motorcycle with timeless design'**
  String get desc_harley_sportster;

  /// No description provided for @desc_honda_cbr600rr.
  ///
  /// In en, this message translates to:
  /// **'High-performance sports bike for enthusiasts'**
  String get desc_honda_cbr600rr;

  /// No description provided for @desc_honda_civic.
  ///
  /// In en, this message translates to:
  /// **'Compact sports car with excellent handling'**
  String get desc_honda_civic;

  /// No description provided for @desc_toyota_corolla.
  ///
  /// In en, this message translates to:
  /// **'Reliable, fuel-efficient sedan with modern features'**
  String get desc_toyota_corolla;

  /// No description provided for @desc_toyota_tacoma.
  ///
  /// In en, this message translates to:
  /// **'Mid-size truck known for durability and off-road performance'**
  String get desc_toyota_tacoma;

  /// Label for the description input field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @determining_provider_location.
  ///
  /// In en, this message translates to:
  /// **'Determining provider location...'**
  String get determining_provider_location;

  /// No description provided for @diagnostic.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic'**
  String get diagnostic;

  /// No description provided for @discountBanner.
  ///
  /// In en, this message translates to:
  /// **'Summer Surprise'**
  String get discountBanner;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @driverArrived.
  ///
  /// In en, this message translates to:
  /// **'Provider Arrived'**
  String get driverArrived;

  /// No description provided for @driverComing.
  ///
  /// In en, this message translates to:
  /// **'Provider arriving in'**
  String get driverComing;

  /// No description provided for @driverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Provider has arrived'**
  String get driverHasArrived;

  /// No description provided for @driverIconLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load provider icon'**
  String get driverIconLoadFailed;

  /// Subtitle when with driver is selected
  ///
  /// In en, this message translates to:
  /// **'Includes Driver'**
  String get driverIncluded;

  /// No description provided for @driverInfo.
  ///
  /// In en, this message translates to:
  /// **'Provider Information'**
  String get driverInfo;

  /// No description provided for @driverInfoError.
  ///
  /// In en, this message translates to:
  /// **'Error retrieving provider information.'**
  String get driverInfoError;

  /// No description provided for @driverIsComing.
  ///
  /// In en, this message translates to:
  /// **'Provider is coming - Arrival time: '**
  String get driverIsComing;

  /// No description provided for @driverOnWay.
  ///
  /// In en, this message translates to:
  /// **'Provider on the Way'**
  String get driverOnWay;

  /// No description provided for @driverSearchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to find providers.'**
  String get driverSearchError;

  /// No description provided for @driverToDestination.
  ///
  /// In en, this message translates to:
  /// **'On the way to destination'**
  String get driverToDestination;

  /// No description provided for @driver_info_not_found.
  ///
  /// In en, this message translates to:
  /// **'Driver data not available'**
  String get driver_info_not_found;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @emergencies.
  ///
  /// In en, this message translates to:
  /// **'Emergencies'**
  String get emergencies;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequired;

  /// No description provided for @videoRequired.
  ///
  /// In en, this message translates to:
  /// **'Video is required'**
  String get videoRequired;

  /// No description provided for @postCreated.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully'**
  String get postCreated;

  /// No description provided for @postCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post'**
  String get postCreateError;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @videoSelected.
  ///
  /// In en, this message translates to:
  /// **'Video selected'**
  String get videoSelected;

  /// Button label for submitting the report
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submit;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @emergencyRepair.
  ///
  /// In en, this message translates to:
  /// **'Emergency Repair'**
  String get emergencyRepair;

  /// No description provided for @emergencyRepairMessage.
  ///
  /// In en, this message translates to:
  /// **'Need urgent car repair? Find a mechanic now!'**
  String get emergencyRepairMessage;

  /// No description provided for @searchMechanics.
  ///
  /// In en, this message translates to:
  /// **'Search mechanics...'**
  String get searchMechanics;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @welcomeToRanaJayeen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rana Jayeen'**
  String get welcomeToRanaJayeen;

  /// No description provided for @findMechanicsFast.
  ///
  /// In en, this message translates to:
  /// **'Find trusted mechanics fast'**
  String get findMechanicsFast;

  /// No description provided for @emergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'In case of emergency, don\'t hesitate to call immediately. Your safety is our priority.'**
  String get emergencyInfo;

  /// No description provided for @emergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency Numbers'**
  String get emergencyNumbers;

  /// No description provided for @emptyComment.
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty'**
  String get emptyComment;

  /// Error message for empty form field
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get empty_field_error;

  /// No description provided for @enRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route:'**
  String get enRoute;

  /// No description provided for @enable_notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get enable_notifications;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Message for OTP input, showing phone number
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phoneNumber}'**
  String enterCodeSentTo(Object phoneNumber);

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter a description (optional)'**
  String get enterDescription;

  /// No description provided for @enterFeedback.
  ///
  /// In en, this message translates to:
  /// **'Enter your feedback (optional)...'**
  String get enterFeedback;

  /// No description provided for @enterPartName.
  ///
  /// In en, this message translates to:
  /// **'Enter part name'**
  String get enterPartName;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter text'**
  String get enterText;

  /// Error message for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get enterValidOtp;

  /// No description provided for @enterVehicleBrand.
  ///
  /// In en, this message translates to:
  /// **'Enter vehicle brand'**
  String get enterVehicleBrand;

  /// Hint for name input
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorAddress.
  ///
  /// In en, this message translates to:
  /// **'Error getting address'**
  String get errorAddress;

  /// No description provided for @errorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get errorLoadingServices;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get errorLocation;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorMessage;

  /// No description provided for @errorRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to process your request'**
  String get errorRequest;

  /// No description provided for @errorSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code: {error}'**
  String errorSendingOtp(Object error);

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get errorUnexpected;

  /// No description provided for @error_checking_location_permission.
  ///
  /// In en, this message translates to:
  /// **'Error checking location permission'**
  String get error_checking_location_permission;

  /// No description provided for @error_fetching_chats.
  ///
  /// In en, this message translates to:
  /// **'Error fetching chats'**
  String get error_fetching_chats;

  /// No description provided for @error_fetching_driver_details.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch provider details'**
  String get error_fetching_driver_details;

  /// No description provided for @error_fetching_gas_stations.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch gas stations'**
  String get error_fetching_gas_stations;

  /// Error message when fetching provider details fails
  ///
  /// In en, this message translates to:
  /// **'Error fetching provider details'**
  String get error_fetching_provider;

  /// Error message when fetching stores fails
  ///
  /// In en, this message translates to:
  /// **'Error fetching stores'**
  String get error_fetching_stores;

  /// Error message when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get error_location_denied;

  /// Error message when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get error_location_denied_forever;

  /// Error message when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get error_location_disabled;

  /// Error message when location retrieval fails
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve location'**
  String error_location_failed(Object error);

  /// Error message when fetching messages from the database fails
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch messages: %s'**
  String get error_message_fetch_failed;

  /// Error message when sending a message to the database fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: %s'**
  String get error_message_send_failed;

  /// Error message when making a phone call fails
  ///
  /// In en, this message translates to:
  /// **'Failed to make phone call'**
  String get error_phone_call;

  /// Error message when request submission fails
  ///
  /// In en, this message translates to:
  /// **'Request submission failed: {error}'**
  String error_request_failed(Object error);

  /// No description provided for @error_request_save.
  ///
  /// In en, this message translates to:
  /// **'Failed to save request'**
  String get error_request_save;

  /// Error message when listening to request status fails
  ///
  /// In en, this message translates to:
  /// **'Error listening to request status: {error}'**
  String error_request_status(Object error);

  /// Error message when provider search fails
  ///
  /// In en, this message translates to:
  /// **'Provider search failed: {error}'**
  String error_search_failed(Object error);

  /// No description provided for @error_tracking_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to track request'**
  String get error_tracking_request;

  /// Error message when user location is unavailable
  ///
  /// In en, this message translates to:
  /// **'Failed to get user or location information'**
  String get error_user_location;

  /// No description provided for @expand_search.
  ///
  /// In en, this message translates to:
  /// **'Expand Search'**
  String get expand_search;

  /// No description provided for @expanding_search.
  ///
  /// In en, this message translates to:
  /// **'Expanding search radius to'**
  String get expanding_search;

  /// Option for exterior car wash
  ///
  /// In en, this message translates to:
  /// **'Exterior Wash'**
  String get exteriorWash;

  /// No description provided for @exterior_wash.
  ///
  /// In en, this message translates to:
  /// **'Exterior Wash'**
  String get exterior_wash;

  /// No description provided for @failed_phone_call.
  ///
  /// In en, this message translates to:
  /// **'Failed to make phone call'**
  String get failed_phone_call;

  /// No description provided for @failed_to_book_store.
  ///
  /// In en, this message translates to:
  /// **'Failed to book store'**
  String get failed_to_book_store;

  /// No description provided for @failed_to_cancel_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request.'**
  String get failed_to_cancel_request;

  /// No description provided for @failed_to_create_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to create request. Retrying...'**
  String get failed_to_create_request;

  /// No description provided for @failed_to_fetch_driver_details.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch driver details'**
  String get failed_to_fetch_driver_details;

  /// No description provided for @failed_to_get_address.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch address.'**
  String get failed_to_get_address;

  /// No description provided for @failed_to_get_location.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get failed_to_get_location;

  /// No description provided for @failed_to_initialize.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize app'**
  String get failed_to_initialize;

  /// No description provided for @failed_to_initialize_provider_search.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize provider search.'**
  String get failed_to_initialize_provider_search;

  /// No description provided for @failed_to_load_messages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat messages'**
  String get failed_to_load_messages;

  /// No description provided for @failed_to_load_providers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load providers.'**
  String get failed_to_load_providers;

  /// No description provided for @failed_to_make_call.
  ///
  /// In en, this message translates to:
  /// **'Failed to make call'**
  String get failed_to_make_call;

  /// No description provided for @failed_to_monitor_status.
  ///
  /// In en, this message translates to:
  /// **'Failed to monitor request status'**
  String get failed_to_monitor_status;

  /// No description provided for @failed_to_notify_provider.
  ///
  /// In en, this message translates to:
  /// **'Failed to notify provider'**
  String get failed_to_notify_provider;

  /// No description provided for @failed_to_open_chat.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get failed_to_open_chat;

  /// No description provided for @failed_to_receive_ride_updates.
  ///
  /// In en, this message translates to:
  /// **'Failed to receive ride updates'**
  String get failed_to_receive_ride_updates;

  /// No description provided for @failed_to_restore_state.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore state'**
  String get failed_to_restore_state;

  /// No description provided for @failed_to_search_providers.
  ///
  /// In en, this message translates to:
  /// **'Failed to search for providers.'**
  String get failed_to_search_providers;

  /// No description provided for @failed_to_send_notification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification'**
  String get failed_to_send_notification;

  /// No description provided for @failed_to_send_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request to provider.'**
  String get failed_to_send_request;

  /// No description provided for @failed_to_start_chat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat'**
  String get failed_to_start_chat;

  /// No description provided for @failed_to_submit_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get failed_to_submit_request;

  /// No description provided for @failed_to_sync.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync data'**
  String get failed_to_sync;

  /// No description provided for @failed_to_sync_driver_data.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync provider data'**
  String get failed_to_sync_driver_data;

  /// No description provided for @failed_to_update_location.
  ///
  /// In en, this message translates to:
  /// **'Failed to update location'**
  String get failed_to_update_location;

  /// No description provided for @featureNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Feature currently under development. We\'re working hard to make it available soon!'**
  String get featureNotAvailable;

  /// No description provided for @featuredOffer.
  ///
  /// In en, this message translates to:
  /// **'Featured Offer'**
  String get featuredOffer;

  /// Label for vehicle features section
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your feedback was sent successfully. Thank you for your input!'**
  String get feedbackSuccess;

  /// No description provided for @fetching_location.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get fetching_location;

  /// Header for search card
  ///
  /// In en, this message translates to:
  /// **'Find Your Ride'**
  String get findYourRide;

  /// No description provided for @findingProvider.
  ///
  /// In en, this message translates to:
  /// **'Finding Provider'**
  String get findingProvider;

  /// No description provided for @firstname.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstname;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @freeDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Free Diagnostic'**
  String get freeDiagnostic;

  /// No description provided for @freeDiagnosticDesc.
  ///
  /// In en, this message translates to:
  /// **'Get a free car diagnostic this week only!'**
  String get freeDiagnosticDesc;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// Label for full name field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Label for full name input
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameOptional;

  /// No description provided for @fullRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Repair'**
  String get fullRepairTitle;

  /// No description provided for @fullRepairType.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Repair'**
  String get fullRepairType;

  /// Option for full car wash (exterior and interior)
  ///
  /// In en, this message translates to:
  /// **'Full Wash'**
  String get fullWash;

  /// No description provided for @full_wash.
  ///
  /// In en, this message translates to:
  /// **'Full Wash'**
  String get full_wash;

  /// No description provided for @gasStation.
  ///
  /// In en, this message translates to:
  /// **'Gas Station'**
  String get gasStation;

  /// No description provided for @gasStationDescription.
  ///
  /// In en, this message translates to:
  /// **'Fuel and convenience services'**
  String get gasStationDescription;

  /// No description provided for @gasStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Gas Station'**
  String get gasStationTitle;

  /// No description provided for @gas_station_selected.
  ///
  /// In en, this message translates to:
  /// **'Gas station selected'**
  String get gas_station_selected;

  /// No description provided for @gendarmerie.
  ///
  /// In en, this message translates to:
  /// **'National Gendarmerie'**
  String get gendarmerie;

  /// No description provided for @gendarmerieDescription.
  ///
  /// In en, this message translates to:
  /// **'Your safety matters. In case of an emergency, you can call directly or send an alert or message with your location.'**
  String get gendarmerieDescription;

  /// No description provided for @geoFireError.
  ///
  /// In en, this message translates to:
  /// **'Error initializing GeoFire.'**
  String get geoFireError;

  /// No description provided for @glassRepairDescription.
  ///
  /// In en, this message translates to:
  /// **'Windshield and glass repair services'**
  String get glassRepairDescription;

  /// No description provided for @glassRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Glass Repair'**
  String get glassRepairTitle;

  /// No description provided for @go_back.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get go_back;

  /// No description provided for @goingToDestination.
  ///
  /// In en, this message translates to:
  /// **'On the way to destination - Arrival time: '**
  String get goingToDestination;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guides;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'re having an issue. We\'re here to help!\nFeel free to reach out via message or call.'**
  String get helpDescription;

  /// No description provided for @helpText.
  ///
  /// In en, this message translates to:
  /// **'Help Text'**
  String get helpText;

  /// No description provided for @hide_stores.
  ///
  /// In en, this message translates to:
  /// **'Hide Stores'**
  String get hide_stores;

  /// No description provided for @highestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get highestRated;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Format for hours ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{0 hours ago} one{1 hour ago} other{{count} hours ago}}'**
  String hours_ago(num count);

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How Can We Help You?'**
  String get howCanWeHelp;

  /// No description provided for @in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get in_progress;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @initializing_service.
  ///
  /// In en, this message translates to:
  /// **'Initializing service...'**
  String get initializing_service;

  /// Option for interior car wash
  ///
  /// In en, this message translates to:
  /// **'Interior Wash'**
  String get interiorWash;

  /// No description provided for @interior_wash.
  ///
  /// In en, this message translates to:
  /// **'Interior Wash'**
  String get interior_wash;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidOtp;

  /// No description provided for @invalid_service_type.
  ///
  /// In en, this message translates to:
  /// **'Invalid service type'**
  String get invalid_service_type;

  /// No description provided for @inviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite a Friend'**
  String get inviteFriend;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @just_now.
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get just_now;

  /// Description for key programming service
  ///
  /// In en, this message translates to:
  /// **'On-site car key programming or replacement'**
  String get keyProgrammingDescription;

  /// Title for key programming service
  ///
  /// In en, this message translates to:
  /// **'Key Programming'**
  String get keyProgrammingTitle;

  /// Unit for kilometers
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// Confirmation message shown when language is changed
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get lat;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @likeError.
  ///
  /// In en, this message translates to:
  /// **'Error updating like status'**
  String get likeError;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked successfully'**
  String get liked;

  /// No description provided for @lng.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get lng;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get loadingAddress;

  /// No description provided for @loadingCarFixesTips.
  ///
  /// In en, this message translates to:
  /// **'Loading car fixes and tips...'**
  String get loadingCarFixesTips;

  /// No description provided for @loadingPosts.
  ///
  /// In en, this message translates to:
  /// **'Loading posts...'**
  String get loadingPosts;

  /// No description provided for @loadingTutorials.
  ///
  /// In en, this message translates to:
  /// **'Loading tutorials...'**
  String get loadingTutorials;

  /// Message shown while loading the user's address
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get loading_address;

  /// Message shown while fetching location
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them to view providers.'**
  String get locationDisabled;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location information unavailable.'**
  String get locationError;

  /// No description provided for @locationFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch location.'**
  String get locationFetchError;

  /// No description provided for @locationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to locate, please try again'**
  String get locationFetchFailed;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please enable location permission'**
  String get locationPermission;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission must be granted.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable it in settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Error checking location permission.'**
  String get locationPermissionError;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required to use the service'**
  String get locationPermissionRequired;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled. Please enable them.'**
  String get locationServiceDisabled;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get locationServicesDisabled;

  /// Error message when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please allow access.'**
  String get location_denied;

  /// Error message when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable it in settings.'**
  String get location_denied_forever;

  /// Error message when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services disabled. Please enable them.'**
  String get location_disabled;

  /// Error message for location fetching failure
  ///
  /// In en, this message translates to:
  /// **'Error fetching location. Please try again.'**
  String get location_error;

  /// No description provided for @location_fetch_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch location'**
  String get location_fetch_failed;

  /// No description provided for @location_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get location_permission_denied;

  /// No description provided for @location_permission_denied_forever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.'**
  String get location_permission_denied_forever;

  /// No description provided for @location_permission_denied_permanently.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get location_permission_denied_permanently;

  /// No description provided for @location_permission_error.
  ///
  /// In en, this message translates to:
  /// **'Location permission error'**
  String get location_permission_error;

  /// No description provided for @location_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get location_permission_required;

  /// No description provided for @location_selection.
  ///
  /// In en, this message translates to:
  /// **'Location Selection'**
  String get location_selection;

  /// No description provided for @location_service_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get location_service_disabled;

  /// No description provided for @location_services_disabled.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services.'**
  String get location_services_disabled;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to subscribe'**
  String get loginRequired;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Error logging out: @error'**
  String get logoutError;

  /// Label for luxury category
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get luxury;

  /// No description provided for @maintenanceCategory.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceCategory;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapThemeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load map theme.'**
  String get mapThemeError;

  /// No description provided for @map_label.
  ///
  /// In en, this message translates to:
  /// **'Map showing your location and nearby providers'**
  String get map_label;

  /// No description provided for @max_retries_reached.
  ///
  /// In en, this message translates to:
  /// **'Maximum retry attempts reached for search.'**
  String get max_retries_reached;

  /// No description provided for @mechanicServices.
  ///
  /// In en, this message translates to:
  /// **'Mechanic Services'**
  String get mechanicServices;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @messageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The messaging feature is currently under development and will be available soon. Thank you for your patience!'**
  String get messageComingSoon;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message Sent'**
  String get messageSent;

  /// No description provided for @messageSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent successfully. We\'ll reach out soon.'**
  String get messageSuccess;

  /// Format for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{0 minutes ago} one{1 minute ago} other{{count} minutes ago}}'**
  String minutes_ago(num count);

  /// Option for mobile car wash service
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile_car_wash;

  /// Label for mobile car wash provider
  ///
  /// In en, this message translates to:
  /// **'Mobile Car Wash Provider'**
  String get mobile_car_wash_provider;

  /// No description provided for @more_info_hint.
  ///
  /// In en, this message translates to:
  /// **'Add more information'**
  String get more_info_hint;

  /// No description provided for @motorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// No description provided for @motorcycles.
  ///
  /// In en, this message translates to:
  /// **'Motorcycles'**
  String get motorcycles;

  /// Title for the success toast after submitting a rating.
  ///
  /// In en, this message translates to:
  /// **'Rating Submitted'**
  String get rating_submitted;

  /// No description provided for @rating_queued.
  ///
  /// In en, this message translates to:
  /// **'Rating queued, will sync when online'**
  String get rating_queued;

  /// No description provided for @no_ratings.
  ///
  /// In en, this message translates to:
  /// **'No ratings'**
  String get no_ratings;

  /// No description provided for @failed_to_submit_rating.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating'**
  String get failed_to_submit_rating;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @checkingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Checking network connection...'**
  String get checkingNetwork;

  /// No description provided for @loadingCachedData.
  ///
  /// In en, this message translates to:
  /// **'Loading cached data...'**
  String get loadingCachedData;

  /// No description provided for @noInternetConnectionWithCache.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Use offline mode with last saved data or try again when connected.'**
  String get noInternetConnectionWithCache;

  /// No description provided for @useOffline.
  ///
  /// In en, this message translates to:
  /// **'Use Offline'**
  String get useOffline;

  /// No description provided for @dataSynced.
  ///
  /// In en, this message translates to:
  /// **'Your data has been updated.'**
  String get dataSynced;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update data. Please try again later.'**
  String get syncFailed;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'send message'**
  String get message;

  /// No description provided for @nearby_gas_stations.
  ///
  /// In en, this message translates to:
  /// **'Nearby Gas Stations'**
  String get nearby_gas_stations;

  /// No description provided for @new_message_body.
  ///
  /// In en, this message translates to:
  /// **'New message from'**
  String get new_message_body;

  /// No description provided for @new_message_title.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get new_message_title;

  /// No description provided for @new_request_at.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get new_request_at;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Negative response for with driver toggle
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No address found for this location'**
  String get noAddressFound;

  /// No description provided for @noCarFixesTips.
  ///
  /// In en, this message translates to:
  /// **'No content available for this category.'**
  String get noCarFixesTips;

  /// No description provided for @noDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get noDriversAvailable;

  /// Error message for no internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @noMatchingDriver.
  ///
  /// In en, this message translates to:
  /// **'No matching driver found'**
  String get noMatchingDriver;

  /// No description provided for @noMatchingProvider.
  ///
  /// In en, this message translates to:
  /// **'No matching provider found.'**
  String get noMatchingProvider;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhone;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts available'**
  String get noPosts;

  /// No description provided for @noProviderAvailable.
  ///
  /// In en, this message translates to:
  /// **'No provider available at the moment'**
  String get noProviderAvailable;

  /// No description provided for @noProvidersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No providers available at the moment'**
  String get noProvidersAvailable;

  /// No description provided for @noProvidersNearby.
  ///
  /// In en, this message translates to:
  /// **'No providers available nearby.'**
  String get noProvidersNearby;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noServicesFound;

  /// No description provided for @noTutorials.
  ///
  /// In en, this message translates to:
  /// **'No tutorials available for this category.'**
  String get noTutorials;

  /// No description provided for @noVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles found'**
  String get noVehicles;

  /// No description provided for @no_address.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get no_address;

  /// No description provided for @no_cached_providers.
  ///
  /// In en, this message translates to:
  /// **'No cached providers found for this service.'**
  String get no_cached_providers;

  /// No description provided for @no_chats_available.
  ///
  /// In en, this message translates to:
  /// **'No chats available'**
  String get no_chats_available;

  /// No description provided for @no_driver_assigned.
  ///
  /// In en, this message translates to:
  /// **'No driver assigned yet'**
  String get no_driver_assigned;

  /// No description provided for @no_drivers_available.
  ///
  /// In en, this message translates to:
  /// **'No providers available near you'**
  String get no_drivers_available;

  /// No description provided for @no_gas_stations_available.
  ///
  /// In en, this message translates to:
  /// **'No gas stations available'**
  String get no_gas_stations_available;

  /// Message shown when no provider is found
  ///
  /// In en, this message translates to:
  /// **'No provider found'**
  String get no_provider_found;

  /// Message shown when no providers are available
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get no_providers_available;

  /// No description provided for @no_providers_available_offline.
  ///
  /// In en, this message translates to:
  /// **'No providers available in offline mode'**
  String get no_providers_available_offline;

  /// No description provided for @no_providers_for.
  ///
  /// In en, this message translates to:
  /// **'No providers available for'**
  String get no_providers_for;

  /// No description provided for @no_providers_found.
  ///
  /// In en, this message translates to:
  /// **'No providers found after maximum retries.'**
  String get no_providers_found;

  /// No description provided for @no_providers_found_searching.
  ///
  /// In en, this message translates to:
  /// **'No providers found. Continuing search...'**
  String get no_providers_found_searching;

  /// No description provided for @no_results_found.
  ///
  /// In en, this message translates to:
  /// **'No results found for search'**
  String get no_results_found;

  /// Message shown when no stores are available
  ///
  /// In en, this message translates to:
  /// **'No stores available for this service'**
  String get no_stores_available;

  /// No description provided for @not_available.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get not_available;

  /// No description provided for @not_specified.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get not_specified;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to nearby providers'**
  String get notificationSent;

  /// No description provided for @notification_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification to provider'**
  String get notification_failed;

  /// No description provided for @notification_next_provider.
  ///
  /// In en, this message translates to:
  /// **'Searching for another provider'**
  String get notification_next_provider;

  /// No description provided for @notification_sent_success.
  ///
  /// In en, this message translates to:
  /// **'Contacting provider'**
  String get notification_sent_success;

  /// No description provided for @notification_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Notification unavailable.'**
  String get notification_unavailable;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @offline_mode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offline_mode;

  /// No description provided for @offline_providers_available.
  ///
  /// In en, this message translates to:
  /// **'Available Providers (Offline)'**
  String get offline_providers_available;

  /// No description provided for @oilChange.
  ///
  /// In en, this message translates to:
  /// **'Oil Change'**
  String get oilChange;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @originAddress.
  ///
  /// In en, this message translates to:
  /// **'Location Address'**
  String get originAddress;

  /// Error message for OTP request too soon
  ///
  /// In en, this message translates to:
  /// **'Please wait before requesting another OTP'**
  String get otpRequestTooSoon;

  /// Error message for OTP send failure
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP'**
  String get otpSendFailed;

  /// Success message for OTP sent
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// Error message for OTP verification failure
  ///
  /// In en, this message translates to:
  /// **'OTP verification failed'**
  String get otpVerificationFailed;

  /// No description provided for @partName.
  ///
  /// In en, this message translates to:
  /// **'Part Name'**
  String get partName;

  /// No description provided for @partNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter part name'**
  String get partNameError;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number not available'**
  String get phoneNotAvailable;

  /// Label for phone number input
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone number has been verified successfully.'**
  String get phoneVerifiedMessage;

  /// Success message for phone verification
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully'**
  String get phoneVerifiedSuccessfully;

  /// Message shown when provider phone number is not available
  ///
  /// In en, this message translates to:
  /// **'Phone number not available'**
  String get phone_not_available;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get pickupDate;

  /// Error message for empty name
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Error message for invalid phone number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhone;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating before submitting.'**
  String get pleaseSelectRating;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment'**
  String get pleaseWait;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @policeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your safety matters. In case of an emergency, you can call directly or send an alert or message with your location.'**
  String get policeDescription;

  /// No description provided for @popularProducts.
  ///
  /// In en, this message translates to:
  /// **'Our Core Services'**
  String get popularProducts;

  /// Title for popular services section
  ///
  /// In en, this message translates to:
  /// **'Our Core Services'**
  String get popularServices;

  /// No description provided for @postDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting post'**
  String get postDeleteError;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully'**
  String get postDeleted;

  /// No description provided for @postUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating post'**
  String get postUpdateError;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully'**
  String get postUpdated;

  /// Category name for pothole reports
  ///
  /// In en, this message translates to:
  /// **'Pothole'**
  String get pothole_report_category;

  /// Description for pothole reporting card
  ///
  /// In en, this message translates to:
  /// **'Report a pothole to improve road safety'**
  String get pothole_report_description;

  /// No description provided for @powerfulTruck.
  ///
  /// In en, this message translates to:
  /// **'Powerful Truck'**
  String get powerfulTruck;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'Daily Price'**
  String get pricePerDay;

  /// No description provided for @primaryServices.
  ///
  /// In en, this message translates to:
  /// **'Primary Services'**
  String get primaryServices;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// Label for provider in booking summary
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @providerArrived.
  ///
  /// In en, this message translates to:
  /// **'Provider Arrived'**
  String get providerArrived;

  /// No description provided for @providerOnWay.
  ///
  /// In en, this message translates to:
  /// **'Provider on the Way'**
  String get providerOnWay;

  /// No description provided for @provider_assigned.
  ///
  /// In en, this message translates to:
  /// **'Provider Assigned'**
  String get provider_assigned;

  /// No description provided for @provider_assigned_body.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider_assigned_body;

  /// No description provided for @provider_declined.
  ///
  /// In en, this message translates to:
  /// **'Providers declined the request. Trying other providers...'**
  String get provider_declined;

  /// No description provided for @provider_details.
  ///
  /// In en, this message translates to:
  /// **'Provider Details'**
  String get provider_details;

  /// No description provided for @provider_location.
  ///
  /// In en, this message translates to:
  /// **'Provider Location'**
  String get provider_location;

  /// No description provided for @provider_no_service.
  ///
  /// In en, this message translates to:
  /// **'Provider does not offer this service'**
  String get provider_no_service;

  /// No description provided for @provider_not_found.
  ///
  /// In en, this message translates to:
  /// **'Provider not found in cached data'**
  String get provider_not_found;

  /// No description provided for @provider_notification_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider_notification_unavailable;

  /// No description provided for @provider_on_way.
  ///
  /// In en, this message translates to:
  /// **'Provider on the way'**
  String get provider_on_way;

  /// No description provided for @provider_timeout.
  ///
  /// In en, this message translates to:
  /// **'Providers did not respond. Trying other providers...'**
  String get provider_timeout;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @providers_declined.
  ///
  /// In en, this message translates to:
  /// **'Providers declined. Trying other providers...'**
  String get providers_declined;

  /// No description provided for @providers_no_response.
  ///
  /// In en, this message translates to:
  /// **'Providers did not respond. Trying other providers...'**
  String get providers_no_response;

  /// No description provided for @reachingTimeError.
  ///
  /// In en, this message translates to:
  /// **'Error updating destination arrival time.'**
  String get reachingTimeError;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @rentVehicles.
  ///
  /// In en, this message translates to:
  /// **'Rent Vehicles'**
  String get rentVehicles;

  /// No description provided for @repairCategory.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repairCategory;

  /// No description provided for @report_category.
  ///
  /// In en, this message translates to:
  /// **'Contribute to faster road repairs by reporting issues'**
  String get report_category;

  /// Title for the pothole reporting screen
  ///
  /// In en, this message translates to:
  /// **'Report Pothole'**
  String get report_pothole;

  /// Label for the number of reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports_label;

  /// No description provided for @requestCarWash.
  ///
  /// In en, this message translates to:
  /// **'Request Car Wash'**
  String get requestCarWash;

  /// No description provided for @requestDelivery.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get requestDelivery;

  /// No description provided for @requestError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save request.'**
  String get requestError;

  /// No description provided for @requestPickup.
  ///
  /// In en, this message translates to:
  /// **'Request Pickup'**
  String get requestPickup;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to provider.'**
  String get requestSent;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get requestService;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get requestSubmitted;

  /// Message shown when the request is accepted
  ///
  /// In en, this message translates to:
  /// **'Request accepted by provider!'**
  String get request_accepted;

  /// No description provided for @request_accepted_body.
  ///
  /// In en, this message translates to:
  /// **'Your request was accepted by'**
  String get request_accepted_body;

  /// No description provided for @request_accepted_title.
  ///
  /// In en, this message translates to:
  /// **'Request Accepted'**
  String get request_accepted_title;

  /// No description provided for @request_at.
  ///
  /// In en, this message translates to:
  /// **'Requested at'**
  String get request_at;

  /// No description provided for @request_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled.'**
  String get request_cancelled;

  /// No description provided for @request_cancelled_message.
  ///
  /// In en, this message translates to:
  /// **'Service request cancelled'**
  String get request_cancelled_message;

  /// No description provided for @request_delivery.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get request_delivery;

  /// No description provided for @request_details.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get request_details;

  /// No description provided for @request_details_error.
  ///
  /// In en, this message translates to:
  /// **'Please provide request details'**
  String get request_details_error;

  /// No description provided for @request_pickup.
  ///
  /// In en, this message translates to:
  /// **'Request Pickup'**
  String get request_pickup;

  /// No description provided for @request_queued.
  ///
  /// In en, this message translates to:
  /// **'Request queued to be sent when internet is available'**
  String get request_queued;

  /// No description provided for @request_service.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get request_service;

  /// No description provided for @request_service_button.
  ///
  /// In en, this message translates to:
  /// **'Request Service Button'**
  String get request_service_button;

  /// No description provided for @request_stored.
  ///
  /// In en, this message translates to:
  /// **'Request stored for'**
  String get request_stored;

  /// Message shown when the request times out
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get request_timeout;

  /// No description provided for @request_type.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get request_type;

  /// Label for resend OTP button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Label for resend OTP timer
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} seconds'**
  String resendInSeconds(Object seconds);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retry_connection_button.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection Button'**
  String get retry_connection_button;

  /// No description provided for @retrying_location.
  ///
  /// In en, this message translates to:
  /// **'Retrying to fetch location...'**
  String get retrying_location;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return Date'**
  String get returnDate;

  /// Label for review count
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @ride_cancelled_or_ended.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled or ended'**
  String get ride_cancelled_or_ended;

  /// No description provided for @ride_info_not_found.
  ///
  /// In en, this message translates to:
  /// **'Ride data not available'**
  String get ride_info_not_found;

  /// No description provided for @ride_status_updated.
  ///
  /// In en, this message translates to:
  /// **'Ride status updated'**
  String get ride_status_updated;

  /// Title for the pothole reporting section
  ///
  /// In en, this message translates to:
  /// **'Report Pothole'**
  String get road_issue_report_title;

  /// No description provided for @roadsideAssistance.
  ///
  /// In en, this message translates to:
  /// **'Roadside Assistance'**
  String get roadsideAssistance;

  /// No description provided for @routineMaintenanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodic vehicle maintenance services'**
  String get routineMaintenanceDescription;

  /// No description provided for @routineMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Routine Maintenance'**
  String get routineMaintenanceTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveData.
  ///
  /// In en, this message translates to:
  /// **'Save Rental'**
  String get saveData;

  /// No description provided for @savedInformation.
  ///
  /// In en, this message translates to:
  /// **'Saved Information'**
  String get savedInformation;

  /// No description provided for @schedule_date.
  ///
  /// In en, this message translates to:
  /// **'Schedule Date'**
  String get schedule_date;

  /// No description provided for @schedule_date_error.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get schedule_date_error;

  /// No description provided for @schedule_time.
  ///
  /// In en, this message translates to:
  /// **'Schedule Time'**
  String get schedule_time;

  /// No description provided for @schedule_time_error.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get schedule_time_error;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get searchAgain;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search Services'**
  String get searchServices;

  /// No description provided for @searchVehicles.
  ///
  /// In en, this message translates to:
  /// **'Search Vehicles'**
  String get searchVehicles;

  /// No description provided for @search_continued.
  ///
  /// In en, this message translates to:
  /// **'Continuing search for providers...'**
  String get search_continued;

  /// No description provided for @search_error.
  ///
  /// In en, this message translates to:
  /// **'Error searching for providers'**
  String get search_error;

  /// No description provided for @search_error_try_again.
  ///
  /// In en, this message translates to:
  /// **'Search error. Please try again.'**
  String get search_error_try_again;

  /// No description provided for @search_location.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get search_location;

  /// No description provided for @searchingForProvider.
  ///
  /// In en, this message translates to:
  /// **'Searching for Provider'**
  String get searchingForProvider;

  /// No description provided for @searching_for.
  ///
  /// In en, this message translates to:
  /// **'Searching for'**
  String get searching_for;

  /// No description provided for @searching_for_another_driver.
  ///
  /// In en, this message translates to:
  /// **'Searching for another driver...'**
  String get searching_for_another_driver;

  /// No description provided for @searching_for_driver.
  ///
  /// In en, this message translates to:
  /// **'Searching for provider...'**
  String get searching_for_driver;

  /// Message shown while searching for a service provider
  ///
  /// In en, this message translates to:
  /// **'Searching for provider'**
  String get searching_for_provider;

  /// No description provided for @searching_offline.
  ///
  /// In en, this message translates to:
  /// **'Searching offline...'**
  String get searching_offline;

  /// No description provided for @secondaryServices.
  ///
  /// In en, this message translates to:
  /// **'Secondary Services'**
  String get secondaryServices;

  /// Button text to see more services
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a location first'**
  String get selectLocationFirst;

  /// No description provided for @selectNumber.
  ///
  /// In en, this message translates to:
  /// **'Select a number to call:'**
  String get selectNumber;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Please select a service.'**
  String get selectService;

  /// No description provided for @selectServicePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a service'**
  String get selectServicePrompt;

  /// No description provided for @selectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// No description provided for @select_gas_station.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select_gas_station;

  /// No description provided for @select_location_first.
  ///
  /// In en, this message translates to:
  /// **'Please select a location first.'**
  String get select_location_first;

  /// No description provided for @select_provider_to_contact.
  ///
  /// In en, this message translates to:
  /// **'Select a provider to contact directly'**
  String get select_provider_to_contact;

  /// Subtitle when with driver is not selected
  ///
  /// In en, this message translates to:
  /// **'Self Drive'**
  String get selfDrive;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendAlert.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to send an alert?'**
  String get sendAlert;

  /// Label for send OTP button
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceCategories.
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get serviceCategories;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Car towing to your desired location'**
  String get serviceDescription;

  /// Error message for missing service type selection
  ///
  /// In en, this message translates to:
  /// **'Please select a service type'**
  String get serviceTypeError;

  /// No description provided for @service_description.
  ///
  /// In en, this message translates to:
  /// **'Request this service at your location'**
  String get service_description;

  /// Message shown when the service is unavailable
  ///
  /// In en, this message translates to:
  /// **'Service Unavailable'**
  String get service_not_available;

  /// Additional message explaining service unavailability
  ///
  /// In en, this message translates to:
  /// **'This service is currently under maintenance. Please try again later.'**
  String get service_not_available_message;

  /// No description provided for @service_provider.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get service_provider;

  /// Label for the service type selection
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get service_type;

  /// Label for services offered by a store or provider
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @servicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{No services available} one{1 service available} other{{count} services available}}'**
  String servicesCount(num count);

  /// No description provided for @setLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get setLocationButton;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for high severity level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severity_high;

  /// Title for the toast notification when the trip ends.
  ///
  /// In en, this message translates to:
  /// **'Trip Ended'**
  String get trip_ended;

  /// Description for the toast notification when the trip ends.
  ///
  /// In en, this message translates to:
  /// **'Your trip has concluded. Please rate the service.'**
  String get trip_ended_message;

  /// Title of the rating dialog for the trip.
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get rate_service;

  /// Error message when invalid coordinates are provided.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates provided'**
  String get error_invalid_coordinates;

  /// Error message when the Google Maps API key is not configured.
  ///
  /// In en, this message translates to:
  /// **'API key is missing'**
  String get error_api_key_missing;

  /// No description provided for @switch_to_stationary.
  ///
  /// In en, this message translates to:
  /// **'switch_to_stationary'**
  String get switch_to_stationary;

  /// No description provided for @switch_to_mobile.
  ///
  /// In en, this message translates to:
  /// **'switch_to_mobile'**
  String get switch_to_mobile;

  /// Error message when fetching directions fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch directions'**
  String get error_fetching_directions;

  /// Label indicating that comments are optional in the rating dialog.
  ///
  /// In en, this message translates to:
  /// **'Comments (Optional)'**
  String get comments_optional;

  /// Placeholder text for the comment input field in the rating dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter your comments here'**
  String get enter_comments;

  /// Description for the success toast after submitting a rating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get rating_submitted_message;

  /// Error message when rating submission fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating. Please try again.'**
  String get error_submitting_rating;

  /// Title for the success toast when a pending chat is synced.
  ///
  /// In en, this message translates to:
  /// **'Chat Synced'**
  String get chat_synced;

  /// Description for the success toast when a pending chat is synced.
  ///
  /// In en, this message translates to:
  /// **'Your chat has been successfully synced.'**
  String get chat_synced_message;

  /// Title for the toast when the trip is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip Cancelled'**
  String get trip_cancelled;

  /// Description for the toast when the trip is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Your trip has been cancelled.'**
  String get trip_cancelled_message;

  /// Title for the success toast when a phone call is initiated.
  ///
  /// In en, this message translates to:
  /// **'Call Initiated'**
  String get call_initiated;

  /// Description for the success toast when a phone call is initiated.
  ///
  /// In en, this message translates to:
  /// **'Connecting you to the provider.'**
  String get call_initiated_message;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Error sharing post'**
  String get shareError;

  /// No description provided for @sharePostText.
  ///
  /// In en, this message translates to:
  /// **'Check out this awesome post!'**
  String get sharePostText;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get shopNow;

  /// No description provided for @show_stores.
  ///
  /// In en, this message translates to:
  /// **'Show Stores'**
  String get show_stores;

  /// Title for sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @sort_by_distance.
  ///
  /// In en, this message translates to:
  /// **'Sort by Distance'**
  String get sort_by_distance;

  /// No description provided for @sort_by_name.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sort_by_name;

  /// No description provided for @sort_providers.
  ///
  /// In en, this message translates to:
  /// **'Sort Providers'**
  String get sort_providers;

  /// No description provided for @sparePartsDescription.
  ///
  /// In en, this message translates to:
  /// **'High-quality spare parts for your vehicle'**
  String get sparePartsDescription;

  /// No description provided for @sparePartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spare Parts'**
  String get sparePartsTitle;

  /// No description provided for @sparePartsType.
  ///
  /// In en, this message translates to:
  /// **'Spare Parts Sales'**
  String get sparePartsType;

  /// No description provided for @sportyMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Sporty Motorcycle'**
  String get sportyMotorcycle;

  /// Option for stationary car wash service
  ///
  /// In en, this message translates to:
  /// **'Stationary'**
  String get stationary_car_wash;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Label for a car wash store
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @store_service_description.
  ///
  /// In en, this message translates to:
  /// **'Choose a store or select delivery for your service needs'**
  String get store_service_description;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed successfully'**
  String get subscribed;

  /// No description provided for @subscriptionError.
  ///
  /// In en, this message translates to:
  /// **'Error updating subscription status'**
  String get subscriptionError;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Label for SUV category
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get suv;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tags_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter tags, separated by commas (e.g., #car_repair, #maintenance)'**
  String get tags_hint;

  /// Button label for taking a photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get take_photo;

  /// Disclaimer about taxes for bookings
  ///
  /// In en, this message translates to:
  /// **'Prices may not include taxes and fees'**
  String get taxDisclaimer;

  /// Text for terms and conditions agreement
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our terms and conditions.'**
  String get termsAndConditions;

  /// No description provided for @testimonial1.
  ///
  /// In en, this message translates to:
  /// **'Amazing service! My car was fixed in no time.'**
  String get testimonial1;

  /// No description provided for @testimonial2.
  ///
  /// In en, this message translates to:
  /// **'Reliable and affordable. Highly recommend!'**
  String get testimonial2;

  /// No description provided for @testimonials.
  ///
  /// In en, this message translates to:
  /// **'Testimonials'**
  String get testimonials;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get text;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You'**
  String get thankYou;

  /// No description provided for @thankYouPatience.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your patience!'**
  String get thankYouPatience;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please check connection and try again.'**
  String get timeoutError;

  /// No description provided for @tireRepair.
  ///
  /// In en, this message translates to:
  /// **'Tire Repair'**
  String get tireRepair;

  /// No description provided for @tireRepairDescription.
  ///
  /// In en, this message translates to:
  /// **'On-site tire repair service'**
  String get tireRepairDescription;

  /// No description provided for @tireRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Tire Repair'**
  String get tireRepairTitle;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Label for total price duration
  ///
  /// In en, this message translates to:
  /// **'Total for'**
  String get totalFor;

  /// Description for towing service
  ///
  /// In en, this message translates to:
  /// **'Car towing to your desired location'**
  String get towTruckDescription;

  /// Title for towing service
  ///
  /// In en, this message translates to:
  /// **'Towing Service'**
  String get towTruckTitle;

  /// No description provided for @towTruckType.
  ///
  /// In en, this message translates to:
  /// **'Tow Truck'**
  String get towTruckType;

  /// No description provided for @towingService.
  ///
  /// In en, this message translates to:
  /// **'Towing Service'**
  String get towingService;

  /// No description provided for @trip_cancelled_or_ended.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled or ended'**
  String get trip_cancelled_or_ended;

  /// No description provided for @trip_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Service in progress'**
  String get trip_in_progress;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @trucks.
  ///
  /// In en, this message translates to:
  /// **'Trucks'**
  String get trucks;

  /// No description provided for @tryDifferentCityOrDate.
  ///
  /// In en, this message translates to:
  /// **'Try a different city or date!'**
  String get tryDifferentCityOrDate;

  /// No description provided for @tryDifferentDate.
  ///
  /// In en, this message translates to:
  /// **'Try a different date'**
  String get tryDifferentDate;

  /// No description provided for @tutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutorials;

  /// No description provided for @type_message.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get type_message;

  /// No description provided for @unable_to_create_request.
  ///
  /// In en, this message translates to:
  /// **'Unable to create request. Please try again later.'**
  String get unable_to_create_request;

  /// No description provided for @unable_to_get_location.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch location. Using default location.'**
  String get unable_to_get_location;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// Fallback for unknown values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownAddress.
  ///
  /// In en, this message translates to:
  /// **'Unknown Address'**
  String get unknownAddress;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLocation;

  /// Fallback text when phone number is unavailable
  ///
  /// In en, this message translates to:
  /// **'Unknown Number'**
  String get unknownNumber;

  /// No description provided for @unknownService.
  ///
  /// In en, this message translates to:
  /// **'Unknown Service'**
  String get unknownService;

  /// Fallback for unknown location
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknown_location;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// No description provided for @unliked.
  ///
  /// In en, this message translates to:
  /// **'Unliked successfully'**
  String get unliked;

  /// Fallback for unspecified values
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @unsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribe;

  /// No description provided for @unsubscribed.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed successfully'**
  String get unsubscribed;

  /// No description provided for @upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get upload_failed;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// Label for urgent request checkbox
  ///
  /// In en, this message translates to:
  /// **'Urgent Request'**
  String get urgent_request;

  /// No description provided for @urlError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open content. Please try again.'**
  String get urlError;

  /// No description provided for @user1.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get user1;

  /// No description provided for @user2.
  ///
  /// In en, this message translates to:
  /// **'Jane Smith'**
  String get user2;

  /// No description provided for @userInfoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get user information.'**
  String get userInfoError;

  /// No description provided for @userLocationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch user or location data'**
  String get userLocationFetchFailed;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Label for vehicle in booking summary
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// Label for the vehicle brand input field
  ///
  /// In en, this message translates to:
  /// **'Vehicle Brand'**
  String get vehicleBrand;

  /// Error message for missing vehicle brand
  ///
  /// In en, this message translates to:
  /// **'Please enter vehicle brand'**
  String get vehicleBrandError;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @vehicleTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle type'**
  String get vehicleTypeError;

  /// Label for OTP input
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get verificationCode;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String verificationFailed(Object error);

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Format for view count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{0 views} one{1 view} other{{count} views}}'**
  String views(num count);

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// Message shown while waiting for provider confirmation
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent, please wait for provider confirmation'**
  String get waiting_for_confirmation;

  /// Label for the car wash type selection
  ///
  /// In en, this message translates to:
  /// **'Wash Type'**
  String get washType;

  /// Error message for missing wash type selection
  ///
  /// In en, this message translates to:
  /// **'Please select a wash type'**
  String get washTypeError;

  /// No description provided for @wash_type.
  ///
  /// In en, this message translates to:
  /// **'Wash Type'**
  String get wash_type;

  /// No description provided for @wash_type_error.
  ///
  /// In en, this message translates to:
  /// **'Please select a wash type'**
  String get wash_type_error;

  /// No description provided for @weAreComing.
  ///
  /// In en, this message translates to:
  /// **'We Are Coming'**
  String get weAreComing;

  /// No description provided for @weAreHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We Are Here to Help'**
  String get weAreHereToHelp;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Description for wheel change service
  ///
  /// In en, this message translates to:
  /// **'On-site tire repair or replacement'**
  String get wheelChangeDescription;

  /// Title for wheel change service
  ///
  /// In en, this message translates to:
  /// **'Tire Change or Repair'**
  String get wheelChangeTitle;

  /// No description provided for @wheelChangeType.
  ///
  /// In en, this message translates to:
  /// **'Wheel Change'**
  String get wheelChangeType;

  /// No description provided for @whoWeAre.
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get whoWeAre;

  /// No description provided for @willContact.
  ///
  /// In en, this message translates to:
  /// **'We\'ll contact you soon with service details'**
  String get willContact;

  /// No description provided for @withDriver.
  ///
  /// In en, this message translates to:
  /// **'With Driver'**
  String get withDriver;

  /// No description provided for @writeHere.
  ///
  /// In en, this message translates to:
  /// **'Write Here'**
  String get writeHere;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// Affirmative response for with driver toggle
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'your location'**
  String get yourLocation;

  /// No description provided for @yourOpinionMatters.
  ///
  /// In en, this message translates to:
  /// **'Your opinion matters, so feel free to share.'**
  String get yourOpinionMatters;

  /// Label for the user's location section
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get your_location;

  /// No description provided for @zoom_in.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoom_in;

  /// No description provided for @zoom_out.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoom_out;

  /// Label for opening the navigation menu
  ///
  /// In en, this message translates to:
  /// **'ⴰⵣⵎⵎⴰⵎ'**
  String get openMenu;

  /// Label for the button to view cached providers in offline mode.
  ///
  /// In en, this message translates to:
  /// **'View Cached Providers'**
  String get view_providers;

  /// Title for the bottom sheet displaying cached providers.
  ///
  /// In en, this message translates to:
  /// **'Cached Providers'**
  String get cached_providers;

  /// Error message shown when a user tries to send a request in offline mode.
  ///
  /// In en, this message translates to:
  /// **'Cannot send request in offline mode. View cached providers instead.'**
  String get offline_request_not_allowed;

  /// Message shown when no cached providers are available in offline mode.
  ///
  /// In en, this message translates to:
  /// **'No cached providers available.'**
  String get no_cached_providers_available;

  /// Personalized greeting with the user's name
  ///
  /// In en, this message translates to:
  /// **'Hi {userName}'**
  String greetingPersonal(Object userName);

  /// Message shown when no videos are available
  ///
  /// In en, this message translates to:
  /// **'No videos found. Try again later.'**
  String get noVideosFound;

  /// Error message for video loading failure
  ///
  /// In en, this message translates to:
  /// **'Unable to load video. Please try again.'**
  String get videoLoadError;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number. Please check and try again.'**
  String get invalidPhoneNumber;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait before trying again.'**
  String get tooManyRequests;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'The verification code has expired. Please request a new one.'**
  String get otpExpired;

  /// Title for the list of nearby stores or service providers, where {serviceTitle} is the type of service (e.g., Gas Stations, Repair Shops).
  ///
  /// In en, this message translates to:
  /// **'Nearby {serviceTitle}'**
  String nearby_stores(Object serviceTitle);

  /// Error shown when OTP request limit is exceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many OTP requests. Try again later or use another method.'**
  String get quotaExceededError;

  /// No description provided for @greetingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Wherever you are,we are'**
  String get greetingAvailability;

  /// No description provided for @greetingSupport.
  ///
  /// In en, this message translates to:
  /// **'Support us to grow and expand'**
  String get greetingSupport;

  /// No description provided for @marketingSlogan.
  ///
  /// In en, this message translates to:
  /// **'Break down anywhere? Rana Jayeen brings help to you fast.'**
  String get marketingSlogan;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr', 'kab'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'kab': return AppLocalizationsKab();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
