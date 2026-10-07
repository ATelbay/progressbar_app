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
  String get finishCancel => 'Cancel the workout';

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
  String get effortSome => 'Some left';

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
  String builderLastTime(String result) {
    return 'Last time: $result';
  }

  @override
  String get builderNoHistory => 'Not recorded before — enter the weight';

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

  @override
  String dayToday(String date) {
    return 'Today, $date';
  }

  @override
  String get dayPickerTitle => 'Day of the workout';

  @override
  String get editDelete => 'Delete workout';

  @override
  String get editDeleteConfirm =>
      'Delete this workout? Its results will disappear from history and progress. This cannot be undone.';

  @override
  String get progressMaxWeight => 'Heaviest weight';

  @override
  String get progressMaxTime => 'Longest time';

  @override
  String get progressMaxReps => 'Most reps';

  @override
  String get unitReps => 'reps';

  @override
  String progressChange(String change, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '$count workout',
    );
    return '$change over $_temp0';
  }

  @override
  String get progressEmptyTitle => 'No points yet';

  @override
  String get progressEmptyText =>
      'The chart appears after the first completed workout. One workout is one point: the best result of that day.';

  @override
  String progressChartLabel(
    String from,
    String fromDate,
    String to,
    String toDate,
  ) {
    return 'Chart: from $from on $fromDate to $to on $toDate';
  }

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileTheme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get languageSystem => 'Same as the phone';

  @override
  String get profileEntryMode => 'Result entry';

  @override
  String get entryModeSummary => 'In one line';

  @override
  String get entryModePerSet => 'Set by set';

  @override
  String get profileCatalog => 'Exercise catalog';

  @override
  String get profileEdit => 'Edit name and body weight';

  @override
  String get exerciseOwn => 'Your own exercise';

  @override
  String get exerciseName => 'Name';

  @override
  String get exerciseMeasure => 'Measured in';

  @override
  String get exerciseBodyWeight => 'Uses body weight';

  @override
  String get exerciseBodyWeightHint =>
      'Body weight is added to the load; you enter only the extra weight.';

  @override
  String get exerciseRestore => 'Restore the original';

  @override
  String get exerciseSave => 'Save';

  @override
  String get exerciseEdited => 'edited';

  @override
  String get exerciseMine => 'yours';

  @override
  String get peopleMyCoaches => 'My coaches';

  @override
  String get peopleMyTrainees => 'My trainees';

  @override
  String get peopleCoachActive => 'Assigns programs';

  @override
  String get peopleCoachReadOnly => 'Sees workouts, does not assign';

  @override
  String get chipActive => 'active';

  @override
  String get chipReadOnly => 'view only';

  @override
  String get peopleTraineeActive => 'You are the active coach';

  @override
  String get peopleTraineeReadOnly => 'View only';

  @override
  String get peopleInvite => 'Invite';

  @override
  String get peopleEnterCode => 'Enter an invitation code';

  @override
  String get peopleEmpty =>
      'No one here yet. Invite a coach or a trainee, or enter the code you were given.';

  @override
  String get inviteRoleQuestion => 'Who will you be for the person you invite?';

  @override
  String get inviteAsCoach => 'I am the coach';

  @override
  String get inviteAsCoachHint =>
      'I will write their programs and see their workouts.';

  @override
  String get inviteAsTrainee => 'I am the trainee';

  @override
  String get inviteAsTraineeHint =>
      'They will write my programs and see my workouts.';

  @override
  String get inviteCreate => 'Create invitation';

  @override
  String get inviteTitle => 'Invitation';

  @override
  String get inviteShowCoach =>
      'You invite as a coach. Show the QR code or say the code.';

  @override
  String get inviteShowTrainee =>
      'You invite as a trainee. Show the QR code or say the code.';

  @override
  String get inviteValid => 'The code works once and for 7 days.';

  @override
  String get inviteCopy => 'Copy code';

  @override
  String get inviteCopied => 'Code copied';

  @override
  String get inviteShare => 'Share link';

  @override
  String get inviteQrLabel => 'Invitation QR code';

  @override
  String inviteShareText(String code, String link) {
    return 'Invitation to Progress Bar. Code: $code\nOpen in the app: $link';
  }

  @override
  String get inviteCodeLabel => 'Invitation code';

  @override
  String get inviteFind => 'Find';

  @override
  String get inviteFromCoach => 'invites you as a coach';

  @override
  String get inviteFromTrainee => 'invites you as a trainee';

  @override
  String inviteCoachWill(String name) {
    return '$name will be able to assign you programs and see your workouts.';
  }

  @override
  String inviteTraineeWill(String name) {
    return 'You will be able to assign programs to $name and see their workouts.';
  }

  @override
  String inviteCurrentCoach(String name) {
    return 'Your active coach now is $name. They will keep view-only access.';
  }

  @override
  String get inviteAccept => 'Accept';

  @override
  String get inviteAcceptActive => 'Accept and make active';

  @override
  String get inviteDecline => 'Decline';

  @override
  String get inviteNotFound =>
      'No such invitation. Check the code: it may have been used already or expired.';

  @override
  String get inviteOwn => 'This is your own invitation.';

  @override
  String get inviteFailed =>
      'That did not work. Check the connection and try again.';

  @override
  String coachSheetTitle(String name) {
    return '$name, coach';
  }

  @override
  String get coachDeactivate => 'Deactivate';

  @override
  String coachDeactivateHint(String name) {
    return '$name will keep seeing your workouts but will not be able to assign programs.';
  }

  @override
  String coachRemoveHint(String name) {
    return '$name will lose access completely. Your workouts stay with you.';
  }

  @override
  String get coachKeep => 'Change nothing';

  @override
  String get traineeMine => 'Mine';

  @override
  String get traineeAll => 'All';

  @override
  String get traineeReadOnly =>
      'You are no longer the active coach. You can see workouts but cannot assign programs.';

  @override
  String get traineeUnavailable => 'Access to this trainee is closed.';

  @override
  String get traineeEmpty => 'No workouts in this tab yet.';

  @override
  String get assignedPrograms => 'Assigned programs';

  @override
  String get assignProgram => 'Assign program';

  @override
  String get assignTrainee => 'Assign to trainee';

  @override
  String get assignEmptyPrograms => 'Create your own program first.';

  @override
  String get assignEmptyTrainees =>
      'No trainees you can assign a program to yet.';

  @override
  String get assignSuccess => 'Program assigned';

  @override
  String get assignFailed =>
      'Could not confirm the assignment. Check your connection and coach status, then try again.';

  @override
  String assignedBy(String name) {
    return 'Assigned by $name';
  }

  @override
  String assignedOn(String date) {
    return 'Assigned $date';
  }

  @override
  String get programReadOnly =>
      'Coach program — you can view it and start a workout.';

  @override
  String get programUnavailable =>
      'Program unavailable: it was deleted or access was closed.';

  @override
  String get dataLoadFailed =>
      'Could not load data. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String workoutCoach(String name) {
    return 'Coach: $name';
  }

  @override
  String get workoutCoachUnknown => 'Coach: name not recorded';

  @override
  String get workoutSolo => 'Without a coach';

  @override
  String get workoutPendingMark => 'not recorded yet';

  @override
  String get programMissingExercise =>
      'An exercise is unavailable. This day cannot be started yet.';
}
