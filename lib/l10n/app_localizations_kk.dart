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

  @override
  String get historyNoProgram => 'Бағдарламасыз';

  @override
  String historyPlanPrefix(String plan) {
    return 'жоспар $plan';
  }

  @override
  String historyBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жаттығу жоспардан төмен',
    );
    return '$_temp0';
  }

  @override
  String historySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count өткізілді',
    );
    return '$_temp0';
  }

  @override
  String historyExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жаттығу',
    );
    return '$_temp0';
  }

  @override
  String get historyEdited => 'аяқталғаннан кейін өзгертілген';

  @override
  String get historySkippedMark => 'өткізілді';

  @override
  String get historyEdit => 'Жаттығуды түзету';

  @override
  String historyEditExercise(String name) {
    return 'Түзету: $name';
  }

  @override
  String get historyEmptyTitle => 'Әзірге жаттығу болған жоқ';

  @override
  String get historyEmptyText =>
      'Мұнда әр аяқталған жаттығу көрінеді: жоспарда не болды және не орындалды.';

  @override
  String get historyToPrograms => 'Бағдарламаларға';

  @override
  String get editNotice =>
      'Жаттығу аяқталған. Түзетуден кейін жаттықтырушы «аяқталғаннан кейін өзгертілген» белгісін көреді.';

  @override
  String get editSave => 'Өзгерістерді сақтау';

  @override
  String get editDiscard => 'Сақтамау';

  @override
  String get progressMaxWeight => 'Ең үлкен салмақ';

  @override
  String get progressMaxTime => 'Ең ұзақ уақыт';

  @override
  String get progressMaxReps => 'Ең көп қайталау';

  @override
  String get unitReps => 'қайт.';

  @override
  String progressChange(String change, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жаттығуда',
    );
    return '$_temp0 $change';
  }

  @override
  String get progressEmptyTitle => 'Әзірге бірде-бір нүкте жоқ';

  @override
  String get progressEmptyText =>
      'Кесте алғашқы аяқталған жаттығудан кейін пайда болады. Бір жаттығу — бір нүкте: сол күнгі ең жақсы нәтиже.';

  @override
  String progressChartLabel(
    String from,
    String fromDate,
    String to,
    String toDate,
  ) {
    return 'Кесте: $fromDate $from бастап $toDate $to дейін';
  }

  @override
  String get profileSettings => 'Баптаулар';

  @override
  String get profileLanguage => 'Тіл';

  @override
  String get languageSystem => 'Телефондағыдай';

  @override
  String get profileEntryMode => 'Нәтижені енгізу';

  @override
  String get entryModeSummary => 'Бір жолмен';

  @override
  String get entryModePerSet => 'Тәсіл бойынша';

  @override
  String get profileCatalog => 'Жаттығулар анықтамалығы';

  @override
  String get profileEdit => 'Атты және дене салмағын өзгерту';

  @override
  String get exerciseOwn => 'Өз жаттығуыңыз';

  @override
  String get exerciseName => 'Атауы';

  @override
  String get exerciseMeasure => 'Немен өлшенеді';

  @override
  String get exerciseBodyWeight => 'Өз салмағымен';

  @override
  String get exerciseBodyWeightHint =>
      'Дене салмағы жүктемеге қосылады, тек қосымша салмақ енгізіледі.';

  @override
  String get exerciseRestore => 'Бастапқы қалпына келтіру';

  @override
  String get exerciseSave => 'Сақтау';

  @override
  String get exerciseEdited => 'өзгертілген';

  @override
  String get exerciseMine => 'өзіңіздікі';

  @override
  String get peopleMyCoaches => 'Менің жаттықтырушыларым';

  @override
  String get peopleMyTrainees => 'Менің шәкірттерім';

  @override
  String get peopleCoachActive => 'Бағдарлама тағайындайды';

  @override
  String get peopleCoachReadOnly => 'Жаттығуларды көреді, тағайындамайды';

  @override
  String get chipActive => 'белсенді';

  @override
  String get chipReadOnly => 'қарау';

  @override
  String get peopleTraineeActive => 'Сіз белсенді жаттықтырушысыз';

  @override
  String get peopleTraineeReadOnly => 'Тек қарау';

  @override
  String get peopleInvite => 'Шақыру';

  @override
  String get peopleEnterCode => 'Шақыру кодын енгізу';

  @override
  String get peopleEmpty =>
      'Мұнда әзірге ешкім жоқ. Жаттықтырушыны не шәкіртті шақырыңыз немесе берілген кодты енгізіңіз.';

  @override
  String get inviteRoleQuestion => 'Шақыратын адамыңыз үшін кім боласыз?';

  @override
  String get inviteAsCoach => 'Мен жаттықтырушымын';

  @override
  String get inviteAsCoachHint =>
      'Оған бағдарлама құрып, жаттығуларын көремін.';

  @override
  String get inviteAsTrainee => 'Мен шәкіртпін';

  @override
  String get inviteAsTraineeHint =>
      'Ол маған бағдарлама құрып, жаттығуларымды көреді.';

  @override
  String get inviteCreate => 'Шақыру жасау';

  @override
  String get inviteTitle => 'Шақыру';

  @override
  String get inviteShowCoach =>
      'Сіз жаттықтырушы ретінде шақырасыз. QR кодын көрсетіңіз не кодты айтыңыз.';

  @override
  String get inviteShowTrainee =>
      'Сіз шәкірт ретінде шақырасыз. QR кодын көрсетіңіз не кодты айтыңыз.';

  @override
  String get inviteValid => 'Код бір рет және 7 күн жарамды.';

  @override
  String get inviteCopy => 'Кодты көшіру';

  @override
  String get inviteCopied => 'Код көшірілді';

  @override
  String get inviteShare => 'Сілтемемен бөлісу';

  @override
  String get inviteQrLabel => 'Шақырудың QR коды';

  @override
  String inviteShareText(String code, String link) {
    return 'Progress Bar шақыруы. Код: $code\nҚолданбада ашу: $link';
  }

  @override
  String get inviteCodeLabel => 'Шақыру коды';

  @override
  String get inviteFind => 'Табу';

  @override
  String get inviteFromCoach => 'сізді жаттықтырушы ретінде шақырады';

  @override
  String get inviteFromTrainee => 'сізді шәкірт ретінде шақырады';

  @override
  String inviteCoachWill(String name) {
    return '$name сізге бағдарлама тағайындап, жаттығуларыңызды көре алады.';
  }

  @override
  String inviteTraineeWill(String name) {
    return 'Сіз бағдарлама тағайындап, жаттығуларын көре аласыз: $name.';
  }

  @override
  String inviteCurrentCoach(String name) {
    return 'Қазір белсенді жаттықтырушыңыз — $name. Оның қарау рұқсаты қалады.';
  }

  @override
  String get inviteAccept => 'Қабылдау';

  @override
  String get inviteAcceptActive => 'Қабылдап, белсенді ету';

  @override
  String get inviteDecline => 'Бас тарту';

  @override
  String get inviteNotFound =>
      'Мұндай шақыру жоқ. Кодты тексеріңіз: ол қолданылған не мерзімі өткен болуы мүмкін.';

  @override
  String get inviteOwn => 'Бұл өз шақыруыңыз.';

  @override
  String get inviteFailed =>
      'Орындалмады. Байланысты тексеріп, қайталап көріңіз.';

  @override
  String coachSheetTitle(String name) {
    return '$name, жаттықтырушы';
  }

  @override
  String get coachDeactivate => 'Белсенділіктен шығару';

  @override
  String coachDeactivateHint(String name) {
    return '$name жаттығуларыңызды көре береді, бірақ бағдарлама тағайындай алмайды.';
  }

  @override
  String coachRemoveHint(String name) {
    return '$name рұқсатынан толық айырылады. Жаттығуларыңыз сізде қалады.';
  }

  @override
  String get coachKeep => 'Ештеңе өзгертпеу';

  @override
  String get traineeMine => 'Менің';

  @override
  String get traineeAll => 'Барлығы';

  @override
  String get traineeReadOnly =>
      'Сіз енді белсенді жаттықтырушы емессіз. Жаттығулар көрінеді, бағдарлама тағайындау мүмкін емес.';

  @override
  String get traineeUnavailable => 'Шәкіртке қол жеткізу жабық.';

  @override
  String get traineeEmpty => 'Бұл қойындыда әлі жаттығу жоқ.';

  @override
  String get assignedPrograms => 'Тағайындалған бағдарламалар';

  @override
  String get assignProgram => 'Бағдарлама тағайындау';

  @override
  String get assignTrainee => 'Шәкіртке тағайындау';

  @override
  String get assignEmptyPrograms => 'Алдымен өз бағдарламаңызды жасаңыз.';

  @override
  String get assignEmptyTrainees =>
      'Әзірге бағдарлама тағайындай алатын шәкірттер жоқ.';

  @override
  String get assignSuccess => 'Бағдарлама тағайындалды';

  @override
  String get assignFailed =>
      'Тағайындау расталмады. Желіні және байланыс күйін тексеріп, қайталаңыз.';

  @override
  String assignedBy(String name) {
    return 'Тағайындаған: $name';
  }

  @override
  String assignedOn(String date) {
    return 'Тағайындалған күні: $date';
  }

  @override
  String get programReadOnly =>
      'Жаттықтырушы бағдарламасын көруге және жаттығуды бастауға болады.';

  @override
  String get programUnavailable =>
      'Бағдарлама қолжетімсіз: жойылған немесе қол жеткізу жабылған.';

  @override
  String get dataLoadFailed =>
      'Деректер жүктелмеді. Желіні тексеріп, қайталаңыз.';

  @override
  String get retry => 'Қайталау';

  @override
  String workoutCoach(String name) {
    return 'Жаттықтырушы: $name';
  }

  @override
  String get workoutCoachUnknown => 'Жаттықтырушы: аты сақталмаған';

  @override
  String get workoutSolo => 'Жаттықтырушысыз';

  @override
  String get workoutPendingMark => 'әлі жазылмаған';

  @override
  String get programMissingExercise =>
      'Жаттығу қолжетімсіз. Бұл күнді әзірге бастау мүмкін емес.';
}
