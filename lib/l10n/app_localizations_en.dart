// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AquaSol';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToManage => 'Sign in to manage your smart farm';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get home => 'Home';

  @override
  String get farm => 'Farm';

  @override
  String get control => 'Control';

  @override
  String get data => 'Data';

  @override
  String get solu => 'Solu';

  @override
  String get farmHealthScore => 'FARM HEALTH SCORE';

  @override
  String get allSystemsOperational => 'All systems operational';

  @override
  String get aiAdvisory => 'AI ADVISORY';

  @override
  String get quickOperations => 'Quick Operations';

  @override
  String get farmDiary => 'Farm Diary';

  @override
  String get cropPlanner => 'Crop Planner';

  @override
  String get systemHealth => 'System Health';

  @override
  String get pnlAnalytics => 'P&L Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign Out';

  @override
  String get irrigationSchedule => 'Irrigation Schedule';

  @override
  String get selectTarget => 'SELECT TARGET';

  @override
  String get individualZone => 'Individual Zone';

  @override
  String get completeAcre => 'Complete Acre';

  @override
  String get dateTime => 'DATE & TIME';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get repeatOn => 'REPEAT ON';

  @override
  String get mode => 'MODE';

  @override
  String get manualTimer => 'Manual Timer';

  @override
  String get aiWindow => 'AI Window';

  @override
  String get durationIntensity => 'DURATION & INTENSITY';

  @override
  String get duration => 'Duration';

  @override
  String get intensity => 'Intensity';

  @override
  String get confirmSchedule => 'Confirm Schedule';

  @override
  String get scheduleSuccess => 'Schedule confirmed successfully!';

  @override
  String get scheduleError => 'Failed to save schedule.';

  @override
  String get acreWideIrrigation => 'Acre-wide Irrigation';

  @override
  String zoneSchedule(String name) {
    return '$name Schedule';
  }

  @override
  String get acreAllZones => 'Acre 1 (All Zones)';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get greeting => 'Greeting';

  @override
  String get profile => 'Profile';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get fullName => 'Full Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get phoneOptional => 'Phone Number (Optional)';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get agreeToTerms => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get joinFarmers => 'Create your account';

  @override
  String get joinFarmersSub => 'Join thousands of smart farmers across India';

  @override
  String get signInFree => 'Sign in';

  @override
  String get signUpFree => 'Sign up free';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get whatGrowing => 'What are you growing?';

  @override
  String get pickCropSoil => 'Pick your primary crop and soil type';

  @override
  String get primaryCropLabel => 'PRIMARY CROP';

  @override
  String get soilTypeLabel => 'SOIL TYPE';

  @override
  String get continues => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get zonesCreatedSuccess => 'Zones Created Successfully!';

  @override
  String get tellUsAboutFarm => 'Tell us about your farm';

  @override
  String get quickDetailsSub => 'A few quick details to set things up';

  @override
  String get farmNameLabel => 'FARM NAME';

  @override
  String get ownerNameLabel => 'OWNER NAME';

  @override
  String get stateLabel => 'STATE';

  @override
  String get villageTownLabel => 'VILLAGE / TOWN';

  @override
  String get infrastructureConfig => 'Infrastructure Config';

  @override
  String get defineHierarchy => 'Define your farm\'s irrigation hierarchy';

  @override
  String get totalAcresLabel => 'TOTAL ACRES';

  @override
  String get zonesPerAcreLabel => 'ZONES PER ACRE';

  @override
  String get totalZonesGenerated => 'TOTAL ZONES GENERATED';

  @override
  String get nodesPerZoneLabel => 'NODES PER ZONE';

  @override
  String get waterSourceLabel => 'WATER SOURCE';

  @override
  String get personalizeNaming => 'Personalize Naming';

  @override
  String get giveUniqueNames => 'Give unique names to your zones and nodes';

  @override
  String get hardwarePairing => 'Hardware Pairing';

  @override
  String get useCodesToPair => 'Use these codes to pair your physical nodes';

  @override
  String get masterGateway => 'Master Gateway';

  @override
  String get pairThisFirst => 'Pair this first — it routes all nodes';

  @override
  String stepX(int index) {
    return 'STEP $index';
  }

  @override
  String get pairingCodeLabel => 'Pairing Code';

  @override
  String get fieldNodesLabel => 'Field Nodes';

  @override
  String get pairAfterMasterOnline => 'Pair after Master Gateway is online';

  @override
  String get finalizeSetup => 'Finalize Setup';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get skip => 'Skip';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }
}
