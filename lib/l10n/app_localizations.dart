import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AquaSol'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToManage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your smart farm'**
  String get signInToManage;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

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

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @control.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get control;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @solu.
  ///
  /// In en, this message translates to:
  /// **'Solu'**
  String get solu;

  /// No description provided for @farmHealthScore.
  ///
  /// In en, this message translates to:
  /// **'FARM HEALTH SCORE'**
  String get farmHealthScore;

  /// No description provided for @allSystemsOperational.
  ///
  /// In en, this message translates to:
  /// **'All systems operational'**
  String get allSystemsOperational;

  /// No description provided for @aiAdvisory.
  ///
  /// In en, this message translates to:
  /// **'AI ADVISORY'**
  String get aiAdvisory;

  /// No description provided for @quickOperations.
  ///
  /// In en, this message translates to:
  /// **'Quick Operations'**
  String get quickOperations;

  /// No description provided for @farmDiary.
  ///
  /// In en, this message translates to:
  /// **'Farm Diary'**
  String get farmDiary;

  /// No description provided for @cropPlanner.
  ///
  /// In en, this message translates to:
  /// **'Crop Planner'**
  String get cropPlanner;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get systemHealth;

  /// No description provided for @pnlAnalytics.
  ///
  /// In en, this message translates to:
  /// **'P&L Analytics'**
  String get pnlAnalytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @irrigationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Schedule'**
  String get irrigationSchedule;

  /// No description provided for @selectTarget.
  ///
  /// In en, this message translates to:
  /// **'SELECT TARGET'**
  String get selectTarget;

  /// No description provided for @individualZone.
  ///
  /// In en, this message translates to:
  /// **'Individual Zone'**
  String get individualZone;

  /// No description provided for @completeAcre.
  ///
  /// In en, this message translates to:
  /// **'Complete Acre'**
  String get completeAcre;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'DATE & TIME'**
  String get dateTime;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'REPEAT ON'**
  String get repeatOn;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get mode;

  /// No description provided for @manualTimer.
  ///
  /// In en, this message translates to:
  /// **'Manual Timer'**
  String get manualTimer;

  /// No description provided for @aiWindow.
  ///
  /// In en, this message translates to:
  /// **'AI Window'**
  String get aiWindow;

  /// No description provided for @durationIntensity.
  ///
  /// In en, this message translates to:
  /// **'DURATION & INTENSITY'**
  String get durationIntensity;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity;

  /// No description provided for @confirmSchedule.
  ///
  /// In en, this message translates to:
  /// **'Confirm Schedule'**
  String get confirmSchedule;

  /// No description provided for @scheduleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule confirmed successfully!'**
  String get scheduleSuccess;

  /// No description provided for @scheduleError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule.'**
  String get scheduleError;

  /// No description provided for @acreWideIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Acre-wide Irrigation'**
  String get acreWideIrrigation;

  /// No description provided for @zoneSchedule.
  ///
  /// In en, this message translates to:
  /// **'{name} Schedule'**
  String zoneSchedule(String name);

  /// No description provided for @acreAllZones.
  ///
  /// In en, this message translates to:
  /// **'Acre 1 (All Zones)'**
  String get acreAllZones;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Greeting'**
  String get greeting;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneOptional;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @joinFarmers.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get joinFarmers;

  /// No description provided for @joinFarmersSub.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of smart farmers across India'**
  String get joinFarmersSub;

  /// No description provided for @signInFree.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInFree;

  /// No description provided for @signUpFree.
  ///
  /// In en, this message translates to:
  /// **'Sign up free'**
  String get signUpFree;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @whatGrowing.
  ///
  /// In en, this message translates to:
  /// **'What are you growing?'**
  String get whatGrowing;

  /// No description provided for @pickCropSoil.
  ///
  /// In en, this message translates to:
  /// **'Pick your primary crop and soil type'**
  String get pickCropSoil;

  /// No description provided for @primaryCropLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY CROP'**
  String get primaryCropLabel;

  /// No description provided for @soilTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'SOIL TYPE'**
  String get soilTypeLabel;

  /// No description provided for @continues.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continues;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @zonesCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Zones Created Successfully!'**
  String get zonesCreatedSuccess;

  /// No description provided for @tellUsAboutFarm.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your farm'**
  String get tellUsAboutFarm;

  /// No description provided for @quickDetailsSub.
  ///
  /// In en, this message translates to:
  /// **'A few quick details to set things up'**
  String get quickDetailsSub;

  /// No description provided for @farmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FARM NAME'**
  String get farmNameLabel;

  /// No description provided for @ownerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'OWNER NAME'**
  String get ownerNameLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'STATE'**
  String get stateLabel;

  /// No description provided for @villageTownLabel.
  ///
  /// In en, this message translates to:
  /// **'VILLAGE / TOWN'**
  String get villageTownLabel;

  /// No description provided for @infrastructureConfig.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure Config'**
  String get infrastructureConfig;

  /// No description provided for @defineHierarchy.
  ///
  /// In en, this message translates to:
  /// **'Define your farm\'s irrigation hierarchy'**
  String get defineHierarchy;

  /// No description provided for @totalAcresLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ACRES'**
  String get totalAcresLabel;

  /// No description provided for @zonesPerAcreLabel.
  ///
  /// In en, this message translates to:
  /// **'ZONES PER ACRE'**
  String get zonesPerAcreLabel;

  /// No description provided for @totalZonesGenerated.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ZONES GENERATED'**
  String get totalZonesGenerated;

  /// No description provided for @nodesPerZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'NODES PER ZONE'**
  String get nodesPerZoneLabel;

  /// No description provided for @waterSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'WATER SOURCE'**
  String get waterSourceLabel;

  /// No description provided for @personalizeNaming.
  ///
  /// In en, this message translates to:
  /// **'Personalize Naming'**
  String get personalizeNaming;

  /// No description provided for @giveUniqueNames.
  ///
  /// In en, this message translates to:
  /// **'Give unique names to your zones and nodes'**
  String get giveUniqueNames;

  /// No description provided for @hardwarePairing.
  ///
  /// In en, this message translates to:
  /// **'Hardware Pairing'**
  String get hardwarePairing;

  /// No description provided for @useCodesToPair.
  ///
  /// In en, this message translates to:
  /// **'Use these codes to pair your physical nodes'**
  String get useCodesToPair;

  /// No description provided for @masterGateway.
  ///
  /// In en, this message translates to:
  /// **'Master Gateway'**
  String get masterGateway;

  /// No description provided for @pairThisFirst.
  ///
  /// In en, this message translates to:
  /// **'Pair this first — it routes all nodes'**
  String get pairThisFirst;

  /// No description provided for @stepX.
  ///
  /// In en, this message translates to:
  /// **'STEP {index}'**
  String stepX(int index);

  /// No description provided for @pairingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing Code'**
  String get pairingCodeLabel;

  /// No description provided for @fieldNodesLabel.
  ///
  /// In en, this message translates to:
  /// **'Field Nodes'**
  String get fieldNodesLabel;

  /// No description provided for @pairAfterMasterOnline.
  ///
  /// In en, this message translates to:
  /// **'Pair after Master Gateway is online'**
  String get pairAfterMasterOnline;

  /// No description provided for @finalizeSetup.
  ///
  /// In en, this message translates to:
  /// **'Finalize Setup'**
  String get finalizeSetup;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);
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
      <String>['en', 'hi', 'kn', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
