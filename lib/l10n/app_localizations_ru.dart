// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Progress Bar';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabHistory => 'История';

  @override
  String get tabProgress => 'Прогресс';

  @override
  String get tabPeople => 'Люди';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get signInTitle => 'Вход';

  @override
  String get signInPhoneLabel => 'Номер телефона';

  @override
  String get homeStartFreeWorkout => 'Тренировка без программы';

  @override
  String get homeNewProgram => 'Новая программа';

  @override
  String get programBuilderTitle => 'Программа';

  @override
  String get workoutTitle => 'Тренировка';

  @override
  String get traineeTitle => 'Подопечный';

  @override
  String get profileSignOut => 'Выйти';

  @override
  String get comingSoon => 'Здесь пока пусто';

  @override
  String get signInTagline =>
      'Журнал тренировок. Тренер пишет план, вы — что получилось.';

  @override
  String get signInGetCode => 'Получить код';

  @override
  String get signInSmsHint => 'Пришлём код в SMS. Пароль не нужен.';

  @override
  String get codeTitle => 'Код из SMS';

  @override
  String codeSentTo(String phone) {
    return 'Отправили на $phone';
  }

  @override
  String get codeLabel => 'Код из шести цифр';

  @override
  String get codeContinue => 'Продолжить';

  @override
  String get codeResend => 'Отправить ещё раз';

  @override
  String get welcomeTitle => 'Пара вопросов';

  @override
  String get welcomeHint =>
      'Спросим один раз. Потом это можно поменять в профиле.';

  @override
  String get welcomeNameLabel => 'Как вас зовут';

  @override
  String get welcomeBodyWeight => 'Вес тела';

  @override
  String get welcomeBodyWeightHint =>
      'Нужен для подтягиваний, отжиманий и других упражнений с собственным весом.';

  @override
  String get welcomeDone => 'Готово';

  @override
  String get unitKg => 'кг';

  @override
  String get decreaseBodyWeight => 'Меньше вес тела';

  @override
  String get increaseBodyWeight => 'Больше вес тела';

  @override
  String get errorInvalidPhone =>
      'Это не похоже на номер телефона. Введите его с кодом страны: +7 701 234 56 78.';

  @override
  String get errorInvalidCode =>
      'Код не подошёл. Проверьте SMS и попробуйте ещё раз.';

  @override
  String get errorCodeExpired => 'Код устарел. Запросите новый.';

  @override
  String get errorTooManyRequests => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get errorNetwork => 'Нет связи. Проверьте сеть и попробуйте ещё раз.';

  @override
  String get errorUnknown => 'Не получилось войти. Попробуйте ещё раз.';

  @override
  String get errorNameRequired => 'Введите имя.';
}
