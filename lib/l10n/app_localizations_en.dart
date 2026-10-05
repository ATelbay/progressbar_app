// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Progress Bar';

  @override
  String get tabHome => 'Home';

  @override
  String get tabHistory => 'History';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabPeople => 'People';

  @override
  String get tabProfile => 'Profile';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInPhoneLabel => 'Phone number';

  @override
  String get homeStartFreeWorkout => 'Workout without a program';

  @override
  String get homeNewProgram => 'New program';

  @override
  String get programBuilderTitle => 'Program';

  @override
  String get workoutTitle => 'Workout';

  @override
  String get traineeTitle => 'Trainee';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get comingSoon => 'Nothing here yet';

  @override
  String get signInTagline =>
      'A training log. Your coach writes the plan, you log what happened.';

  @override
  String get signInGetCode => 'Get code';

  @override
  String get signInSmsHint => 'We\'ll text you a code. No password needed.';

  @override
  String get codeTitle => 'Code from SMS';

  @override
  String codeSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get codeLabel => 'Six-digit code';

  @override
  String get codeContinue => 'Continue';

  @override
  String get codeResend => 'Send again';

  @override
  String get welcomeTitle => 'Two quick questions';

  @override
  String get welcomeHint =>
      'We ask once. You can change this later in your profile.';

  @override
  String get welcomeNameLabel => 'Your name';

  @override
  String get welcomeBodyWeight => 'Body weight';

  @override
  String get welcomeBodyWeightHint =>
      'Used for pull-ups, dips and other body-weight exercises.';

  @override
  String get welcomeDone => 'Done';

  @override
  String get unitKg => 'kg';

  @override
  String get decreaseBodyWeight => 'Decrease body weight';

  @override
  String get increaseBodyWeight => 'Increase body weight';

  @override
  String get errorInvalidPhone =>
      'That doesn\'t look like a phone number. Enter it with the country code, like +7 701 234 56 78.';

  @override
  String get errorInvalidCode => 'Wrong code. Check the SMS and try again.';

  @override
  String get errorCodeExpired => 'The code has expired. Request a new one.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorNetwork => 'No connection. Check the network and try again.';

  @override
  String get errorUnknown => 'Couldn\'t sign in. Try again.';

  @override
  String get errorNameRequired => 'Enter your name.';
}
