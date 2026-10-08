import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Bar'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get tabPeople;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get signInPhoneLabel;

  /// No description provided for @homeStartFreeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout without a program'**
  String get homeStartFreeWorkout;

  /// No description provided for @homeNewProgram.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get homeNewProgram;

  /// No description provided for @programBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get programBuilderTitle;

  /// No description provided for @workoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTitle;

  /// No description provided for @traineeTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainee'**
  String get traineeTitle;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get comingSoon;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'A training log. Your coach writes the plan, you log what happened.'**
  String get signInTagline;

  /// No description provided for @signInGetCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get signInGetCode;

  /// No description provided for @signInSmsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a code. No password needed.'**
  String get signInSmsHint;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Code from SMS'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Six-digit code'**
  String get codeLabel;

  /// No description provided for @codeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get codeContinue;

  /// No description provided for @codeResend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get codeResend;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Two quick questions'**
  String get welcomeTitle;

  /// No description provided for @welcomeHint.
  ///
  /// In en, this message translates to:
  /// **'We ask once. You can change this later in your profile.'**
  String get welcomeHint;

  /// No description provided for @welcomeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get welcomeNameLabel;

  /// No description provided for @welcomeBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get welcomeBodyWeight;

  /// No description provided for @welcomeBodyWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Used for pull-ups, dips and other body-weight exercises.'**
  String get welcomeBodyWeightHint;

  /// No description provided for @welcomeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get welcomeDone;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @decreaseBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Decrease body weight'**
  String get decreaseBodyWeight;

  /// No description provided for @increaseBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Increase body weight'**
  String get increaseBodyWeight;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a phone number. Enter it with the country code, like +7 701 234 56 78.'**
  String get errorInvalidPhone;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong code. Check the SMS and try again.'**
  String get errorInvalidCode;

  /// No description provided for @errorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Request a new one.'**
  String get errorCodeExpired;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check the network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Try again.'**
  String get errorUnknown;

  /// No description provided for @errorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get errorNameRequired;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinish;

  /// No description provided for @workoutProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recorded {done} of {total} exercises'**
  String workoutProgressLabel(int done, int total);

  /// No description provided for @workoutOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String workoutOfTotal(int total);

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutAddExercise;

  /// No description provided for @workoutAllRecorded.
  ///
  /// In en, this message translates to:
  /// **'Everything is recorded'**
  String get workoutAllRecorded;

  /// No description provided for @workoutEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add the first exercise.'**
  String get workoutEmptyHint;

  /// No description provided for @chipAsPlanned.
  ///
  /// In en, this message translates to:
  /// **'on plan'**
  String get chipAsPlanned;

  /// No description provided for @chipBelowPlan.
  ///
  /// In en, this message translates to:
  /// **'below plan'**
  String get chipBelowPlan;

  /// No description provided for @chipAbovePlan.
  ///
  /// In en, this message translates to:
  /// **'above plan'**
  String get chipAbovePlan;

  /// No description provided for @chipNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get chipNow;

  /// No description provided for @entryPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get entryPlan;

  /// No description provided for @entryFact.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get entryFact;

  /// No description provided for @entrySets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get entrySets;

  /// No description provided for @entryReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get entryReps;

  /// No description provided for @entryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get entryWeight;

  /// No description provided for @entryExtraWeight.
  ///
  /// In en, this message translates to:
  /// **'Extra weight'**
  String get entryExtraWeight;

  /// No description provided for @entryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get entryTime;

  /// No description provided for @unitSec.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSec;

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String setsCount(int count);

  /// No description provided for @entryLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time: {result}'**
  String entryLastTime(String result);

  /// No description provided for @entryBodyWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Body weight {kg} kg comes from your profile.'**
  String entryBodyWeightNote(String kg);

  /// No description provided for @entryRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get entryRecord;

  /// No description provided for @entryEachSet.
  ///
  /// In en, this message translates to:
  /// **'Add each set'**
  String get entryEachSet;

  /// No description provided for @entryRecordSet.
  ///
  /// In en, this message translates to:
  /// **'Record set {number}'**
  String entryRecordSet(int number);

  /// No description provided for @entryExtraSet.
  ///
  /// In en, this message translates to:
  /// **'Beyond plan'**
  String get entryExtraSet;

  /// No description provided for @entrySummaryOnly.
  ///
  /// In en, this message translates to:
  /// **'Total only'**
  String get entrySummaryOnly;

  /// No description provided for @entryEffort.
  ///
  /// In en, this message translates to:
  /// **'Effort, optional'**
  String get entryEffort;

  /// No description provided for @entryDecrease.
  ///
  /// In en, this message translates to:
  /// **'Less: {what}'**
  String entryDecrease(String what);

  /// No description provided for @entryIncrease.
  ///
  /// In en, this message translates to:
  /// **'More: {what}'**
  String entryIncrease(String what);

  /// No description provided for @keyComma.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get keyComma;

  /// No description provided for @keyErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get keyErase;

  /// No description provided for @finishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish the workout?'**
  String get finishTitle;

  /// No description provided for @finishBody.
  ///
  /// In en, this message translates to:
  /// **'Recorded {done} of {total} exercises. The rest stay without a result — a coach will see them as skipped.'**
  String finishBody(int done, int total);

  /// No description provided for @finishBodyAll.
  ///
  /// In en, this message translates to:
  /// **'All exercises are recorded.'**
  String get finishBodyAll;

  /// No description provided for @finishBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the workout'**
  String get finishBack;

  /// No description provided for @finishCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the workout'**
  String get finishCancel;

  /// No description provided for @homeActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get homeActiveLabel;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeMyPrograms.
  ///
  /// In en, this message translates to:
  /// **'My programs'**
  String get homeMyPrograms;

  /// No description provided for @homeOwnProgram.
  ///
  /// In en, this message translates to:
  /// **'Your own program'**
  String get homeOwnProgram;

  /// No description provided for @homeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String homeDays(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The bar is empty for now'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Build your own program or start a workout without one.'**
  String get homeEmptyText;

  /// No description provided for @errorStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server yet. Go online once and try again.'**
  String get errorStoreUnavailable;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get pickerTitle;

  /// No description provided for @pickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get pickerSearch;

  /// No description provided for @pickerNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get pickerNothing;

  /// No description provided for @groupAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupAll;

  /// No description provided for @groupChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get groupChest;

  /// No description provided for @groupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get groupBack;

  /// No description provided for @groupLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get groupLegs;

  /// No description provided for @groupShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get groupShoulders;

  /// No description provided for @groupArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get groupArms;

  /// No description provided for @groupCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get groupCore;

  /// No description provided for @equipDumbbell.
  ///
  /// In en, this message translates to:
  /// **'dumbbells'**
  String get equipDumbbell;

  /// No description provided for @equipBarbell.
  ///
  /// In en, this message translates to:
  /// **'barbell'**
  String get equipBarbell;

  /// No description provided for @equipMachine.
  ///
  /// In en, this message translates to:
  /// **'machine'**
  String get equipMachine;

  /// No description provided for @equipCable.
  ///
  /// In en, this message translates to:
  /// **'cable'**
  String get equipCable;

  /// No description provided for @equipBodyOnly.
  ///
  /// In en, this message translates to:
  /// **'body weight'**
  String get equipBodyOnly;

  /// No description provided for @equipEzBar.
  ///
  /// In en, this message translates to:
  /// **'EZ bar'**
  String get equipEzBar;

  /// No description provided for @equipKettlebell.
  ///
  /// In en, this message translates to:
  /// **'kettlebell'**
  String get equipKettlebell;

  /// No description provided for @effortMore.
  ///
  /// In en, this message translates to:
  /// **'Could do more'**
  String get effortMore;

  /// No description provided for @effortSome.
  ///
  /// In en, this message translates to:
  /// **'Some left'**
  String get effortSome;

  /// No description provided for @effortNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing left'**
  String get effortNone;

  /// No description provided for @builderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Program name'**
  String get builderNameHint;

  /// No description provided for @builderAddDay.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get builderAddDay;

  /// No description provided for @builderDayName.
  ///
  /// In en, this message translates to:
  /// **'Day name'**
  String get builderDayName;

  /// No description provided for @builderDayDefault.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String builderDayDefault(int number);

  /// No description provided for @builderNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the trainee'**
  String get builderNote;

  /// No description provided for @builderLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time: {result}'**
  String builderLastTime(String result);

  /// No description provided for @builderNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Not recorded before — enter the weight'**
  String get builderNoHistory;

  /// No description provided for @builderNotePrefix.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String builderNotePrefix(String note);

  /// No description provided for @builderRemoveExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove from the day'**
  String get builderRemoveExercise;

  /// No description provided for @builderRemoveDay.
  ///
  /// In en, this message translates to:
  /// **'Delete day'**
  String get builderRemoveDay;

  /// No description provided for @builderDeleteProgram.
  ///
  /// In en, this message translates to:
  /// **'Delete program'**
  String get builderDeleteProgram;

  /// No description provided for @builderDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete «{name}»? Workouts already recorded stay in history.'**
  String builderDeleteConfirm(String name);

  /// No description provided for @builderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get builderDelete;

  /// No description provided for @builderKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get builderKeep;

  /// No description provided for @builderStart.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get builderStart;

  /// No description provided for @builderBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get builderBodyWeight;

  /// No description provided for @builderTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get builderTimed;

  /// No description provided for @builderEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No exercises in this day yet.'**
  String get builderEmptyDay;

  /// No description provided for @builderActiveExists.
  ///
  /// In en, this message translates to:
  /// **'Finish the workout in progress first.'**
  String get builderActiveExists;

  /// No description provided for @historyNoProgram.
  ///
  /// In en, this message translates to:
  /// **'No program'**
  String get historyNoProgram;

  /// No description provided for @historyPlanPrefix.
  ///
  /// In en, this message translates to:
  /// **'plan {plan}'**
  String historyPlanPrefix(String plan);

  /// No description provided for @historyBelow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise below plan} other{{count} exercises below plan}}'**
  String historyBelow(int count);

  /// No description provided for @historySkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} skipped} other{{count} skipped}}'**
  String historySkipped(int count);

  /// No description provided for @historyExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}}'**
  String historyExercises(int count);

  /// No description provided for @historyEdited.
  ///
  /// In en, this message translates to:
  /// **'edited after completion'**
  String get historyEdited;

  /// No description provided for @historySkippedMark.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get historySkippedMark;

  /// No description provided for @historyEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit workout'**
  String get historyEdit;

  /// No description provided for @historyEditExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit: {name}'**
  String historyEditExercise(String name);

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Every completed workout will appear here: what was planned and what was done.'**
  String get historyEmptyText;

  /// No description provided for @historyToPrograms.
  ///
  /// In en, this message translates to:
  /// **'To programs'**
  String get historyToPrograms;

  /// No description provided for @editNotice.
  ///
  /// In en, this message translates to:
  /// **'This workout is completed. After a change a coach will see it marked «edited after completion».'**
  String get editNotice;

  /// No description provided for @editSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editSave;

  /// No description provided for @editDiscard.
  ///
  /// In en, this message translates to:
  /// **'Don\'t save'**
  String get editDiscard;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String dayToday(String date);

  /// No description provided for @dayPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Day of the workout'**
  String get dayPickerTitle;

  /// No description provided for @editDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get editDelete;

  /// No description provided for @editDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this workout? Its results will disappear from history and progress. This cannot be undone.'**
  String get editDeleteConfirm;

  /// No description provided for @progressMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'Heaviest weight'**
  String get progressMaxWeight;

  /// No description provided for @progressMaxTime.
  ///
  /// In en, this message translates to:
  /// **'Longest time'**
  String get progressMaxTime;

  /// No description provided for @progressMaxReps.
  ///
  /// In en, this message translates to:
  /// **'Most reps'**
  String get progressMaxReps;

  /// No description provided for @unitReps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get unitReps;

  /// No description provided for @progressChange.
  ///
  /// In en, this message translates to:
  /// **'{change} over {count, plural, one{{count} workout} other{{count} workouts}}'**
  String progressChange(String change, int count);

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No points yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyText.
  ///
  /// In en, this message translates to:
  /// **'The chart appears after the first completed workout. One workout is one point: the best result of that day.'**
  String get progressEmptyText;

  /// No description provided for @progressChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Chart: from {from} on {fromDate} to {to} on {toDate}'**
  String progressChartLabel(
    String from,
    String fromDate,
    String to,
    String toDate,
  );

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as the phone'**
  String get languageSystem;

  /// No description provided for @profileEntryMode.
  ///
  /// In en, this message translates to:
  /// **'Result entry'**
  String get profileEntryMode;

  /// No description provided for @entryModeSummary.
  ///
  /// In en, this message translates to:
  /// **'In one line'**
  String get entryModeSummary;

  /// No description provided for @entryModePerSet.
  ///
  /// In en, this message translates to:
  /// **'Set by set'**
  String get entryModePerSet;

  /// No description provided for @profileCatalog.
  ///
  /// In en, this message translates to:
  /// **'Exercise catalog'**
  String get profileCatalog;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit name and body weight'**
  String get profileEdit;

  /// No description provided for @exerciseOwn.
  ///
  /// In en, this message translates to:
  /// **'Your own exercise'**
  String get exerciseOwn;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exerciseName;

  /// No description provided for @exerciseMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measured in'**
  String get exerciseMeasure;

  /// No description provided for @exerciseBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Uses body weight'**
  String get exerciseBodyWeight;

  /// No description provided for @exerciseBodyWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Body weight is added to the load; you enter only the extra weight.'**
  String get exerciseBodyWeightHint;

  /// No description provided for @exerciseRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore the original'**
  String get exerciseRestore;

  /// No description provided for @exerciseSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get exerciseSave;

  /// No description provided for @exerciseEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get exerciseEdited;

  /// No description provided for @exerciseMine.
  ///
  /// In en, this message translates to:
  /// **'yours'**
  String get exerciseMine;

  /// No description provided for @peopleMyCoaches.
  ///
  /// In en, this message translates to:
  /// **'My coaches'**
  String get peopleMyCoaches;

  /// No description provided for @peopleMyTrainees.
  ///
  /// In en, this message translates to:
  /// **'My trainees'**
  String get peopleMyTrainees;

  /// No description provided for @peopleCoachActive.
  ///
  /// In en, this message translates to:
  /// **'Assigns programs'**
  String get peopleCoachActive;

  /// No description provided for @peopleCoachReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Sees workouts, does not assign'**
  String get peopleCoachReadOnly;

  /// No description provided for @chipActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get chipActive;

  /// No description provided for @chipReadOnly.
  ///
  /// In en, this message translates to:
  /// **'view only'**
  String get chipReadOnly;

  /// No description provided for @peopleTraineeActive.
  ///
  /// In en, this message translates to:
  /// **'You are the active coach'**
  String get peopleTraineeActive;

  /// No description provided for @peopleTraineeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get peopleTraineeReadOnly;

  /// No description provided for @peopleInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get peopleInvite;

  /// No description provided for @peopleEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter an invitation code'**
  String get peopleEnterCode;

  /// No description provided for @peopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one here yet. Invite a coach or a trainee, or enter the code you were given.'**
  String get peopleEmpty;

  /// No description provided for @inviteRoleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who will you be for the person you invite?'**
  String get inviteRoleQuestion;

  /// No description provided for @inviteAsCoach.
  ///
  /// In en, this message translates to:
  /// **'I am the coach'**
  String get inviteAsCoach;

  /// No description provided for @inviteAsCoachHint.
  ///
  /// In en, this message translates to:
  /// **'I will write their programs and see their workouts.'**
  String get inviteAsCoachHint;

  /// No description provided for @inviteAsTrainee.
  ///
  /// In en, this message translates to:
  /// **'I am the trainee'**
  String get inviteAsTrainee;

  /// No description provided for @inviteAsTraineeHint.
  ///
  /// In en, this message translates to:
  /// **'They will write my programs and see my workouts.'**
  String get inviteAsTraineeHint;

  /// No description provided for @inviteCreate.
  ///
  /// In en, this message translates to:
  /// **'Create invitation'**
  String get inviteCreate;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get inviteTitle;

  /// No description provided for @inviteShowCoach.
  ///
  /// In en, this message translates to:
  /// **'You invite as a coach. Show the QR code or say the code.'**
  String get inviteShowCoach;

  /// No description provided for @inviteShowTrainee.
  ///
  /// In en, this message translates to:
  /// **'You invite as a trainee. Show the QR code or say the code.'**
  String get inviteShowTrainee;

  /// No description provided for @inviteValid.
  ///
  /// In en, this message translates to:
  /// **'The code works once and for 7 days.'**
  String get inviteValid;

  /// No description provided for @inviteCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get inviteCopy;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get inviteCopied;

  /// No description provided for @inviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get inviteShare;

  /// No description provided for @inviteQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation QR code'**
  String get inviteQrLabel;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Invitation to Progress Bar. Code: {code}\nOpen in the app: {link}'**
  String inviteShareText(String code, String link);

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get inviteFind;

  /// No description provided for @inviteFromCoach.
  ///
  /// In en, this message translates to:
  /// **'invites you as a coach'**
  String get inviteFromCoach;

  /// No description provided for @inviteFromTrainee.
  ///
  /// In en, this message translates to:
  /// **'invites you as a trainee'**
  String get inviteFromTrainee;

  /// No description provided for @inviteCoachWill.
  ///
  /// In en, this message translates to:
  /// **'{name} will be able to assign you programs and see your workouts.'**
  String inviteCoachWill(String name);

  /// No description provided for @inviteTraineeWill.
  ///
  /// In en, this message translates to:
  /// **'You will be able to assign programs to {name} and see their workouts.'**
  String inviteTraineeWill(String name);

  /// No description provided for @inviteCurrentCoach.
  ///
  /// In en, this message translates to:
  /// **'Your active coach now is {name}. They will keep view-only access.'**
  String inviteCurrentCoach(String name);

  /// No description provided for @inviteAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get inviteAccept;

  /// No description provided for @inviteAcceptActive.
  ///
  /// In en, this message translates to:
  /// **'Accept and make active'**
  String get inviteAcceptActive;

  /// No description provided for @inviteDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get inviteDecline;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'No such invitation. Check the code: it may have been used already or expired.'**
  String get inviteNotFound;

  /// No description provided for @inviteOwn.
  ///
  /// In en, this message translates to:
  /// **'This is your own invitation.'**
  String get inviteOwn;

  /// No description provided for @inviteFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Check the connection and try again.'**
  String get inviteFailed;

  /// No description provided for @coachSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}, coach'**
  String coachSheetTitle(String name);

  /// No description provided for @coachDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get coachDeactivate;

  /// No description provided for @coachDeactivateHint.
  ///
  /// In en, this message translates to:
  /// **'{name} will keep seeing your workouts but will not be able to assign programs.'**
  String coachDeactivateHint(String name);

  /// No description provided for @coachRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access completely. Your workouts stay with you.'**
  String coachRemoveHint(String name);

  /// No description provided for @coachKeep.
  ///
  /// In en, this message translates to:
  /// **'Change nothing'**
  String get coachKeep;

  /// No description provided for @traineeMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get traineeMine;

  /// No description provided for @traineeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get traineeAll;

  /// No description provided for @traineeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You are no longer the active coach. You can see workouts but cannot assign programs.'**
  String get traineeReadOnly;

  /// No description provided for @traineeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Access to this trainee is closed.'**
  String get traineeUnavailable;

  /// No description provided for @traineeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts in this tab yet.'**
  String get traineeEmpty;

  /// No description provided for @assignedPrograms.
  ///
  /// In en, this message translates to:
  /// **'Assigned programs'**
  String get assignedPrograms;

  /// No description provided for @assignProgram.
  ///
  /// In en, this message translates to:
  /// **'Assign program'**
  String get assignProgram;

  /// No description provided for @assignTrainee.
  ///
  /// In en, this message translates to:
  /// **'Assign to trainee'**
  String get assignTrainee;

  /// No description provided for @assignEmptyPrograms.
  ///
  /// In en, this message translates to:
  /// **'Create your own program first.'**
  String get assignEmptyPrograms;

  /// No description provided for @assignEmptyTrainees.
  ///
  /// In en, this message translates to:
  /// **'No trainees you can assign a program to yet.'**
  String get assignEmptyTrainees;

  /// No description provided for @assignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Program assigned'**
  String get assignSuccess;

  /// No description provided for @assignFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the assignment. Check your connection and coach status, then try again.'**
  String get assignFailed;

  /// No description provided for @assignedBy.
  ///
  /// In en, this message translates to:
  /// **'Assigned by {name}'**
  String assignedBy(String name);

  /// No description provided for @assignedOn.
  ///
  /// In en, this message translates to:
  /// **'Assigned {date}'**
  String assignedOn(String date);

  /// No description provided for @programReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Coach program — you can view it and start a workout.'**
  String get programReadOnly;

  /// No description provided for @programUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Program unavailable: it was deleted or access was closed.'**
  String get programUnavailable;

  /// No description provided for @dataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Check your connection and try again.'**
  String get dataLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @workoutCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach: {name}'**
  String workoutCoach(String name);

  /// No description provided for @workoutCoachUnknown.
  ///
  /// In en, this message translates to:
  /// **'Coach: name not recorded'**
  String get workoutCoachUnknown;

  /// No description provided for @workoutSolo.
  ///
  /// In en, this message translates to:
  /// **'Without a coach'**
  String get workoutSolo;

  /// No description provided for @workoutPendingMark.
  ///
  /// In en, this message translates to:
  /// **'not recorded yet'**
  String get workoutPendingMark;

  /// No description provided for @programMissingExercise.
  ///
  /// In en, this message translates to:
  /// **'An exercise is unavailable. This day cannot be started yet.'**
  String get programMissingExercise;

  /// No description provided for @workoutLocalSaved.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the server. Results are saved on this phone and will be sent automatically, even if you close the app.'**
  String get workoutLocalSaved;

  /// No description provided for @workoutLocalReady.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the server. You can keep training: new results will be saved on this phone.'**
  String get workoutLocalReady;

  /// No description provided for @workoutNotSent.
  ///
  /// In en, this message translates to:
  /// **'not sent'**
  String get workoutNotSent;

  /// No description provided for @saveWorkoutRejected.
  ///
  /// In en, this message translates to:
  /// **'The server refused the workout changes. Check your results: the last change was not saved.'**
  String get saveWorkoutRejected;

  /// No description provided for @saveProgramRejected.
  ///
  /// In en, this message translates to:
  /// **'The server refused the program changes. Check your plan: the last change was not saved.'**
  String get saveProgramRejected;

  /// No description provided for @saveExerciseRejected.
  ///
  /// In en, this message translates to:
  /// **'The server refused the exercise changes. The last change was not saved.'**
  String get saveExerciseRejected;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
