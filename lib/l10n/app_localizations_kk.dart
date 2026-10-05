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
}
