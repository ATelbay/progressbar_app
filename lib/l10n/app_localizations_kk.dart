// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Progress Bar';

  @override
  String get tabHome => 'Басты бет';

  @override
  String get tabHistory => 'Тарих';

  @override
  String get tabProgress => 'Прогресс';

  @override
  String get tabPeople => 'Адамдар';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get signInTitle => 'Кіру';

  @override
  String get signInPhoneLabel => 'Телефон нөмірі';

  @override
  String get homeStartFreeWorkout => 'Бағдарламасыз жаттығу';

  @override
  String get homeNewProgram => 'Жаңа бағдарлама';

  @override
  String get programBuilderTitle => 'Бағдарлама';

  @override
  String get workoutTitle => 'Жаттығу';

  @override
  String get traineeTitle => 'Шәкірт';

  @override
  String get profileSignOut => 'Шығу';

  @override
  String get comingSoon => 'Әзірге бос';

  @override
  String get signInTagline =>
      'Жаттығу журналы. Жаттықтырушы жоспар жазады, сіз — нәтижені.';

  @override
  String get signInGetCode => 'Код алу';

  @override
  String get signInSmsHint =>
      'Кодты SMS арқылы жібереміз. Құпиясөз қажет емес.';

  @override
  String get codeTitle => 'SMS коды';

  @override
  String codeSentTo(String phone) {
    return '$phone нөміріне жіберілді';
  }

  @override
  String get codeLabel => 'Алты таңбалы код';

  @override
  String get codeContinue => 'Жалғастыру';

  @override
  String get codeResend => 'Қайта жіберу';

  @override
  String get welcomeTitle => 'Екі сұрақ';

  @override
  String get welcomeHint =>
      'Бір рет сұраймыз. Кейін профильде өзгертуге болады.';

  @override
  String get welcomeNameLabel => 'Атыңыз кім';

  @override
  String get welcomeBodyWeight => 'Дене салмағы';

  @override
  String get welcomeBodyWeightHint =>
      'Тартылу, брус және өз салмағымен жасалатын басқа жаттығулар үшін қажет.';

  @override
  String get welcomeDone => 'Дайын';

  @override
  String get unitKg => 'кг';

  @override
  String get decreaseBodyWeight => 'Дене салмағын азайту';

  @override
  String get increaseBodyWeight => 'Дене салмағын көбейту';

  @override
  String get errorInvalidPhone =>
      'Бұл телефон нөміріне ұқсамайды. Ел кодымен енгізіңіз: +7 701 234 56 78.';

  @override
  String get errorInvalidCode =>
      'Код сәйкес келмеді. SMS-ті тексеріп, қайталап көріңіз.';

  @override
  String get errorCodeExpired => 'Кодтың мерзімі өтті. Жаңасын сұраңыз.';

  @override
  String get errorTooManyRequests =>
      'Әрекет тым көп. Кейінірек қайталап көріңіз.';

  @override
  String get errorNetwork => 'Байланыс жоқ. Желіні тексеріп, қайталап көріңіз.';

  @override
  String get errorUnknown => 'Кіру мүмкін болмады. Қайталап көріңіз.';

  @override
  String get errorNameRequired => 'Атыңызды енгізіңіз.';

  @override
  String get workoutFinish => 'Аяқтау';

  @override
  String workoutProgressLabel(int done, int total) {
    return '$total жаттығудың $done-і жазылды';
  }

  @override
  String workoutOfTotal(int total) {
    return '/ $total';
  }

  @override
  String get workoutAddExercise => 'Жаттығу қосу';

  @override
  String get workoutAllRecorded => 'Барлығы жазылды';

  @override
  String get workoutEmptyHint => 'Алғашқы жаттығуды қосыңыз.';

  @override
  String get chipAsPlanned => 'жоспар бойынша';

  @override
  String get chipBelowPlan => 'жоспардан төмен';

  @override
  String get chipAbovePlan => 'жоспардан жоғары';

  @override
  String get chipNow => 'қазір';

  @override
  String get entryPlan => 'Жоспар';

  @override
  String get entryFact => 'Нақты';

  @override
  String get entrySets => 'Тәсілдер';

  @override
  String get entryReps => 'Қайталау';

  @override
  String get entryWeight => 'Салмақ';

  @override
  String get entryExtraWeight => 'Қосымша салмақ';

  @override
  String get entryTime => 'Уақыт';

  @override
  String get unitSec => 'с';

  @override
  String setsCount(int count) {
    return '$count тәсіл';
  }

  @override
  String entryLastTime(String result) {
    return 'Өткен жолы: $result';
  }

  @override
  String entryBodyWeightNote(String kg) {
    return 'Дене салмағы $kg кг профильден алынады.';
  }

  @override
  String get entryRecord => 'Жазу';

  @override
  String get entryEachSet => 'Әр тәсілді қосу';

  @override
  String entryRecordSet(int number) {
    return '$number-тәсілді жазу';
  }

  @override
  String get entryExtraSet => 'Жоспардан тыс';

  @override
  String get entrySummaryOnly => 'Тек қорытынды';

  @override
  String get entryEffort => 'Ауырлық, қалауыңызша';

  @override
  String entryDecrease(String what) {
    return 'Азайту: $what';
  }

  @override
  String entryIncrease(String what) {
    return 'Көбейту: $what';
  }

  @override
  String get keyComma => 'Үтір';

  @override
  String get keyErase => 'Өшіру';

  @override
  String get finishTitle => 'Жаттығуды аяқтайсыз ба?';

  @override
  String finishBody(int done, int total) {
    return '$total жаттығудың $done-і жазылды. Қалғандары нәтижесіз қалады — жаттықтырушы оларды өткізілген деп көреді.';
  }

  @override
  String get finishBodyAll => 'Барлық жаттығу жазылды.';

  @override
  String get finishBack => 'Жаттығуға оралу';

  @override
  String get finishCancel => 'Жаттығудан бас тартып, жазбаларды жою';

  @override
  String get homeActiveLabel => 'Жаттығу жүріп жатыр';

  @override
  String get homeContinue => 'Жалғастыру';

  @override
  String get homeMyPrograms => 'Менің бағдарламаларым';

  @override
  String get homeOwnProgram => 'Өз бағдарламаңыз';

  @override
  String homeDays(int count) {
    return '$count күн';
  }

  @override
  String get homeEmptyTitle => 'Гриф әзірге бос';

  @override
  String get homeEmptyText =>
      'Өз бағдарламаңызды құрыңыз немесе бағдарламасыз жаттығуды бастаңыз.';

  @override
  String get errorStoreUnavailable =>
      'Серверге әзірге қосылым жоқ. Желіге бір рет қосылып, қайталап көріңіз.';

  @override
  String get pickerTitle => 'Жаттығу';

  @override
  String get pickerSearch => 'Іздеу';

  @override
  String get pickerNothing => 'Ештеңе табылмады';

  @override
  String get groupAll => 'Барлығы';

  @override
  String get groupChest => 'Кеуде';

  @override
  String get groupBack => 'Арқа';

  @override
  String get groupLegs => 'Аяқ';

  @override
  String get groupShoulders => 'Иық';

  @override
  String get groupArms => 'Қол';

  @override
  String get groupCore => 'Іш';

  @override
  String get equipDumbbell => 'гантельдер';

  @override
  String get equipBarbell => 'штанга';

  @override
  String get equipMachine => 'тренажёр';

  @override
  String get equipCable => 'блок';

  @override
  String get equipBodyOnly => 'өз салмағы';

  @override
  String get equipEzBar => 'EZ-гриф';

  @override
  String get equipKettlebell => 'гір';

  @override
  String get effortMore => 'Тағы жасай аламын';

  @override
  String get effortSome => 'Күш қалды';

  @override
  String get effortNone => 'Бұдан артық алмаймын';

  @override
  String get builderNameHint => 'Бағдарлама атауы';

  @override
  String get builderAddDay => 'Күн қосу';

  @override
  String get builderDayName => 'Күн атауы';

  @override
  String builderDayDefault(int number) {
    return '$number-күн';
  }

  @override
  String get builderNote => 'Жаттығуға ескертпе';

  @override
  String builderNotePrefix(String note) {
    return 'Ескертпе: $note';
  }

  @override
  String get builderRemoveExercise => 'Күннен алып тастау';

  @override
  String get builderRemoveDay => 'Күнді жою';

  @override
  String get builderDeleteProgram => 'Бағдарламаны жою';

  @override
  String builderDeleteConfirm(String name) {
    return '«$name» жойылсын ба? Жазылған жаттығулар тарихта қалады.';
  }

  @override
  String get builderDelete => 'Жою';

  @override
  String get builderKeep => 'Қалдыру';

  @override
  String get builderStart => 'Жаттығуды бастау';

  @override
  String get builderBodyWeight => 'Өз салмағы';

  @override
  String get builderTimed => 'Уақытқа';

  @override
  String get builderEmptyDay => 'Бұл күнде әзірге жаттығу жоқ.';

  @override
  String get builderActiveExists => 'Алдымен жүріп жатқан жаттығуды аяқтаңыз.';
}
