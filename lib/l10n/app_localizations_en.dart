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

  @override
  String get workoutFinish => 'Finish';

  @override
  String workoutProgressLabel(int done, int total) {
    return 'Recorded $done of $total exercises';
  }

  @override
  String workoutOfTotal(int total) {
    return 'of $total';
  }

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutAllRecorded => 'Everything is recorded';

  @override
  String get workoutEmptyHint => 'Add the first exercise.';

  @override
  String get chipAsPlanned => 'on plan';

  @override
  String get chipBelowPlan => 'below plan';

  @override
  String get chipAbovePlan => 'above plan';

  @override
  String get chipNow => 'now';

  @override
  String get entryPlan => 'Plan';

  @override
  String get entryFact => 'Done';

  @override
  String get entrySets => 'Sets';

  @override
  String get entryReps => 'Reps';

  @override
  String get entryWeight => 'Weight';

  @override
  String get entryExtraWeight => 'Extra weight';

  @override
  String get entryTime => 'Time';

  @override
  String get unitSec => 's';

  @override
  String setsCount(int count) {
    return '$count sets';
  }

  @override
  String entryLastTime(String result) {
    return 'Last time: $result';
  }

  @override
  String entryBodyWeightNote(String kg) {
    return 'Body weight $kg kg comes from your profile.';
  }

  @override
  String get entryRecord => 'Record';

  @override
  String get entryEachSet => 'Add each set';

  @override
  String entryRecordSet(int number) {
    return 'Record set $number';
  }

  @override
  String get entryExtraSet => 'Beyond plan';

  @override
  String get entrySummaryOnly => 'Total only';

  @override
  String get entryEffort => 'Effort, optional';

  @override
  String entryDecrease(String what) {
    return 'Less: $what';
  }

  @override
  String entryIncrease(String what) {
    return 'More: $what';
  }

  @override
  String get keyComma => 'Decimal point';

  @override
  String get keyErase => 'Erase';

  @override
  String get finishTitle => 'Finish the workout?';

  @override
  String finishBody(int done, int total) {
    return 'Recorded $done of $total exercises. The rest stay without a result — a coach will see them as skipped.';
  }

  @override
  String get finishBodyAll => 'All exercises are recorded.';

  @override
  String get finishBack => 'Back to the workout';

  @override
  String get finishCancel => 'Cancel the workout and delete the records';

  @override
  String get homeActiveLabel => 'Workout in progress';

  @override
  String get homeContinue => 'Continue';

  @override
  String get homeMyPrograms => 'My programs';

  @override
  String get homeOwnProgram => 'Your own program';

  @override
  String homeDays(int count) {
    return '$count days';
  }

  @override
  String get homeEmptyTitle => 'The bar is empty for now';

  @override
  String get homeEmptyText =>
      'Build your own program or start a workout without one.';

  @override
  String get errorStoreUnavailable =>
      'No connection to the server yet. Go online once and try again.';

  @override
  String get pickerTitle => 'Exercise';

  @override
  String get pickerSearch => 'Search';

  @override
  String get pickerNothing => 'Nothing found';

  @override
  String get groupAll => 'All';

  @override
  String get groupChest => 'Chest';

  @override
  String get groupBack => 'Back';

  @override
  String get groupLegs => 'Legs';

  @override
  String get groupShoulders => 'Shoulders';

  @override
  String get groupArms => 'Arms';

  @override
  String get groupCore => 'Core';

  @override
  String get equipDumbbell => 'dumbbells';

  @override
  String get equipBarbell => 'barbell';

  @override
  String get equipMachine => 'machine';

  @override
  String get equipCable => 'cable';

  @override
  String get equipBodyOnly => 'body weight';

  @override
  String get equipEzBar => 'EZ bar';

  @override
  String get equipKettlebell => 'kettlebell';

  @override
  String get effortMore => 'Could do more';

  @override
  String get effortSome => 'Some strength left';

  @override
  String get effortNone => 'Nothing left';

  @override
  String get builderNameHint => 'Program name';

  @override
  String get builderAddDay => 'Add day';

  @override
  String get builderDayName => 'Day name';

  @override
  String builderDayDefault(int number) {
    return 'Day $number';
  }

  @override
  String get builderNote => 'Note for the trainee';

  @override
  String builderNotePrefix(String note) {
    return 'Note: $note';
  }

  @override
  String get builderRemoveExercise => 'Remove from the day';

  @override
  String get builderRemoveDay => 'Delete day';

  @override
  String get builderDeleteProgram => 'Delete program';

  @override
  String builderDeleteConfirm(String name) {
    return 'Delete «$name»? Workouts already recorded stay in history.';
  }

  @override
  String get builderDelete => 'Delete';

  @override
  String get builderKeep => 'Keep';

  @override
  String get builderStart => 'Start workout';

  @override
  String get builderBodyWeight => 'Body weight';

  @override
  String get builderTimed => 'Timed';

  @override
  String get builderEmptyDay => 'No exercises in this day yet.';

  @override
  String get builderActiveExists => 'Finish the workout in progress first.';

  @override
  String get historyNoProgram => 'No program';

  @override
  String historyPlanPrefix(String plan) {
    return 'plan $plan';
  }

  @override
  String historyBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises below plan',
      one: '$count exercise below plan',
    );
    return '$_temp0';
  }

  @override
  String historySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped',
      one: '$count skipped',
    );
    return '$_temp0';
  }

  @override
  String historyExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String get historyEdited => 'edited after completion';

  @override
  String get historySkippedMark => 'skipped';

  @override
  String get historyEdit => 'Edit workout';

  @override
  String historyEditExercise(String name) {
    return 'Edit: $name';
  }

  @override
  String get historyEmptyTitle => 'No workouts yet';

  @override
  String get historyEmptyText =>
      'Every completed workout will appear here: what was planned and what was done.';

  @override
  String get historyToPrograms => 'To programs';

  @override
  String get editNotice =>
      'This workout is completed. After a change a coach will see it marked «edited after completion».';

  @override
  String get editSave => 'Save changes';

  @override
  String get editDiscard => 'Don\'t save';
}
