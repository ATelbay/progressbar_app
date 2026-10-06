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

  @override
  String get workoutFinish => 'Завершить';

  @override
  String workoutProgressLabel(int done, int total) {
    return 'Записано $done из $total упражнений';
  }

  @override
  String workoutOfTotal(int total) {
    return 'из $total';
  }

  @override
  String get workoutAddExercise => 'Добавить упражнение';

  @override
  String get workoutAllRecorded => 'Всё записано';

  @override
  String get workoutEmptyHint => 'Добавьте первое упражнение.';

  @override
  String get chipAsPlanned => 'по плану';

  @override
  String get chipBelowPlan => 'ниже плана';

  @override
  String get chipAbovePlan => 'выше плана';

  @override
  String get chipNow => 'сейчас';

  @override
  String get entryPlan => 'План';

  @override
  String get entryFact => 'Факт';

  @override
  String get entrySets => 'Подходы';

  @override
  String get entryReps => 'Повторения';

  @override
  String get entryWeight => 'Вес';

  @override
  String get entryExtraWeight => 'Доп. вес';

  @override
  String get entryTime => 'Время';

  @override
  String get unitSec => 'с';

  @override
  String setsCount(int count) {
    return '$count подх.';
  }

  @override
  String entryLastTime(String result) {
    return 'Прошлый раз: $result';
  }

  @override
  String entryBodyWeightNote(String kg) {
    return 'Вес тела $kg кг берётся из профиля.';
  }

  @override
  String get entryRecord => 'Записать';

  @override
  String get entryEachSet => 'Добавить каждый подход';

  @override
  String entryRecordSet(int number) {
    return 'Записать подход $number';
  }

  @override
  String get entryExtraSet => 'Сверх плана';

  @override
  String get entrySummaryOnly => 'Только итог';

  @override
  String get entryEffort => 'Тяжесть, по желанию';

  @override
  String entryDecrease(String what) {
    return 'Меньше: $what';
  }

  @override
  String entryIncrease(String what) {
    return 'Больше: $what';
  }

  @override
  String get keyComma => 'Запятая';

  @override
  String get keyErase => 'Стереть';

  @override
  String get finishTitle => 'Завершить тренировку?';

  @override
  String finishBody(int done, int total) {
    return 'Записано $done из $total упражнений. Остальные останутся без результата — тренер увидит их как пропущенные.';
  }

  @override
  String get finishBodyAll => 'Все упражнения записаны.';

  @override
  String get finishBack => 'Вернуться к тренировке';

  @override
  String get finishCancel => 'Отменить тренировку и удалить записи';

  @override
  String get homeActiveLabel => 'Идёт тренировка';

  @override
  String get homeContinue => 'Продолжить';

  @override
  String get homeMyPrograms => 'Мои программы';

  @override
  String get homeOwnProgram => 'Своя программа';

  @override
  String homeDays(int count) {
    return '$count дн.';
  }

  @override
  String get homeEmptyTitle => 'Гриф пока пустой';

  @override
  String get homeEmptyText =>
      'Составьте свою программу или начните тренировку без неё.';

  @override
  String get errorStoreUnavailable =>
      'Пока нет связи с сервером. Подключитесь к сети один раз и попробуйте снова.';

  @override
  String get pickerTitle => 'Упражнение';

  @override
  String get pickerSearch => 'Поиск';

  @override
  String get pickerNothing => 'Ничего не найдено';

  @override
  String get groupAll => 'Все';

  @override
  String get groupChest => 'Грудь';

  @override
  String get groupBack => 'Спина';

  @override
  String get groupLegs => 'Ноги';

  @override
  String get groupShoulders => 'Плечи';

  @override
  String get groupArms => 'Руки';

  @override
  String get groupCore => 'Пресс';

  @override
  String get equipDumbbell => 'гантели';

  @override
  String get equipBarbell => 'штанга';

  @override
  String get equipMachine => 'тренажёр';

  @override
  String get equipCable => 'блок';

  @override
  String get equipBodyOnly => 'свой вес';

  @override
  String get equipEzBar => 'EZ-гриф';

  @override
  String get equipKettlebell => 'гиря';

  @override
  String get effortMore => 'Могу ещё';

  @override
  String get effortSome => 'Остались силы';

  @override
  String get effortNone => 'Больше не могу';

  @override
  String get builderNameHint => 'Название программы';

  @override
  String get builderAddDay => 'Добавить день';

  @override
  String get builderDayName => 'Название дня';

  @override
  String builderDayDefault(int number) {
    return 'День $number';
  }

  @override
  String get builderNote => 'Заметка к упражнению';

  @override
  String builderNotePrefix(String note) {
    return 'Заметка: $note';
  }

  @override
  String get builderRemoveExercise => 'Убрать из дня';

  @override
  String get builderRemoveDay => 'Удалить день';

  @override
  String get builderDeleteProgram => 'Удалить программу';

  @override
  String builderDeleteConfirm(String name) {
    return 'Удалить «$name»? Уже записанные тренировки останутся в истории.';
  }

  @override
  String get builderDelete => 'Удалить';

  @override
  String get builderKeep => 'Оставить';

  @override
  String get builderStart => 'Начать тренировку';

  @override
  String get builderBodyWeight => 'Собственный вес';

  @override
  String get builderTimed => 'На время';

  @override
  String get builderEmptyDay => 'В этом дне пока нет упражнений.';

  @override
  String get builderActiveExists => 'Сначала завершите идущую тренировку.';

  @override
  String get historyNoProgram => 'Без программы';

  @override
  String historyPlanPrefix(String plan) {
    return 'план $plan';
  }

  @override
  String historyBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнений ниже плана',
      many: '$count упражнений ниже плана',
      few: '$count упражнения ниже плана',
      one: '$count упражнение ниже плана',
    );
    return '$_temp0';
  }

  @override
  String historySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пропущено',
      many: '$count пропущено',
      few: '$count пропущено',
      one: '$count пропущено',
    );
    return '$_temp0';
  }

  @override
  String historyExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнений',
      many: '$count упражнений',
      few: '$count упражнения',
      one: '$count упражнение',
    );
    return '$_temp0';
  }

  @override
  String get historyEdited => 'изменено после завершения';

  @override
  String get historySkippedMark => 'пропущено';

  @override
  String get historyEdit => 'Исправить тренировку';

  @override
  String historyEditExercise(String name) {
    return 'Исправить: $name';
  }

  @override
  String get historyEmptyTitle => 'Тренировок ещё не было';

  @override
  String get historyEmptyText =>
      'Здесь появится каждая завершённая тренировка: что было в плане и что получилось.';

  @override
  String get historyToPrograms => 'К программам';

  @override
  String get editNotice =>
      'Тренировка завершена. После правки тренер увидит пометку «изменено после завершения».';

  @override
  String get editSave => 'Сохранить изменения';

  @override
  String get editDiscard => 'Не сохранять';

  @override
  String get progressMaxWeight => 'Максимальный вес';

  @override
  String get progressMaxTime => 'Максимальное время';

  @override
  String get progressMaxReps => 'Максимум повторений';

  @override
  String get unitReps => 'повт.';

  @override
  String progressChange(String change, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тренировок',
      many: '$count тренировок',
      few: '$count тренировки',
      one: '$count тренировку',
    );
    return '$change за $_temp0';
  }

  @override
  String get progressEmptyTitle => 'Пока нет ни одной точки';

  @override
  String get progressEmptyText =>
      'График появится после первой завершённой тренировки. Одна тренировка — одна точка: лучший результат за день.';

  @override
  String progressChartLabel(
    String from,
    String fromDate,
    String to,
    String toDate,
  ) {
    return 'График: с $from $fromDate до $to $toDate';
  }
}
