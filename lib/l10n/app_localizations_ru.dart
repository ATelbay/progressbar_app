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

  @override
  String get profileSettings => 'Настройки';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get languageSystem => 'Как в телефоне';

  @override
  String get profileEntryMode => 'Ввод результата';

  @override
  String get entryModeSummary => 'Одной строкой';

  @override
  String get entryModePerSet => 'По подходам';

  @override
  String get profileCatalog => 'Справочник упражнений';

  @override
  String get profileEdit => 'Изменить имя и вес тела';

  @override
  String get exerciseOwn => 'Своё упражнение';

  @override
  String get exerciseName => 'Название';

  @override
  String get exerciseMeasure => 'Чем измеряется';

  @override
  String get exerciseBodyWeight => 'С собственным весом';

  @override
  String get exerciseBodyWeightHint =>
      'Вес тела прибавляется к нагрузке, вводится только дополнительный вес.';

  @override
  String get exerciseRestore => 'Вернуть как было';

  @override
  String get exerciseSave => 'Сохранить';

  @override
  String get exerciseEdited => 'изменено';

  @override
  String get exerciseMine => 'своё';

  @override
  String get peopleMyCoaches => 'Мои тренеры';

  @override
  String get peopleMyTrainees => 'Мои подопечные';

  @override
  String get peopleCoachActive => 'Назначает программы';

  @override
  String get peopleCoachReadOnly => 'Видит тренировки, не назначает';

  @override
  String get chipActive => 'активный';

  @override
  String get chipReadOnly => 'просмотр';

  @override
  String get peopleTraineeActive => 'Вы активный тренер';

  @override
  String get peopleTraineeReadOnly => 'Только просмотр';

  @override
  String get peopleInvite => 'Пригласить';

  @override
  String get peopleEnterCode => 'Ввести код приглашения';

  @override
  String get peopleEmpty =>
      'Здесь пока никого. Пригласите тренера или подопечного либо введите код, который вам дали.';

  @override
  String get inviteRoleQuestion =>
      'Кем вы будете для человека, которого приглашаете?';

  @override
  String get inviteAsCoach => 'Я тренер';

  @override
  String get inviteAsCoachHint =>
      'Буду составлять ему программы и видеть его тренировки.';

  @override
  String get inviteAsTrainee => 'Я подопечный';

  @override
  String get inviteAsTraineeHint =>
      'Он будет составлять мне программы и видеть мои тренировки.';

  @override
  String get inviteCreate => 'Создать приглашение';

  @override
  String get inviteTitle => 'Приглашение';

  @override
  String get inviteShowCoach =>
      'Вы приглашаете как тренер. Продиктуйте или отправьте этот код.';

  @override
  String get inviteShowTrainee =>
      'Вы приглашаете как подопечный. Продиктуйте или отправьте этот код.';

  @override
  String get inviteValid => 'Код действует один раз и 7 дней.';

  @override
  String get inviteCopy => 'Скопировать код';

  @override
  String get inviteCopied => 'Код скопирован';

  @override
  String get inviteCodeLabel => 'Код приглашения';

  @override
  String get inviteFind => 'Найти';

  @override
  String get inviteFromCoach => 'приглашает вас как тренер';

  @override
  String get inviteFromTrainee => 'приглашает вас как подопечный';

  @override
  String inviteCoachWill(String name) {
    return '$name сможет назначать вам программы и видеть ваши тренировки.';
  }

  @override
  String inviteTraineeWill(String name) {
    return 'Вы сможете назначать программы и видеть тренировки: $name.';
  }

  @override
  String inviteCurrentCoach(String name) {
    return 'Сейчас ваш активный тренер — $name. У него останется доступ на просмотр.';
  }

  @override
  String get inviteAccept => 'Принять';

  @override
  String get inviteAcceptActive => 'Принять и сделать активным';

  @override
  String get inviteDecline => 'Отклонить';

  @override
  String get inviteNotFound =>
      'Такого приглашения нет. Проверьте код: возможно, его уже использовали или срок истёк.';

  @override
  String get inviteOwn => 'Это ваше собственное приглашение.';

  @override
  String get inviteFailed =>
      'Не получилось. Проверьте связь и попробуйте ещё раз.';

  @override
  String coachSheetTitle(String name) {
    return '$name, тренер';
  }

  @override
  String get coachDeactivate => 'Деактивировать';

  @override
  String coachDeactivateHint(String name) {
    return '$name продолжит видеть ваши тренировки, но не сможет назначать программы.';
  }

  @override
  String coachRemoveHint(String name) {
    return '$name потеряет доступ полностью. Ваши тренировки останутся у вас.';
  }

  @override
  String get coachKeep => 'Ничего не менять';

  @override
  String get traineeMine => 'Мои';

  @override
  String get traineeAll => 'Все';

  @override
  String get traineeReadOnly =>
      'Вы больше не активный тренер. Тренировки видны, назначать программы нельзя.';

  @override
  String get traineeUnavailable => 'Доступ к подопечному закрыт.';

  @override
  String get traineeEmpty => 'В этой вкладке пока нет тренировок.';

  @override
  String get assignedPrograms => 'Назначенные программы';

  @override
  String get assignProgram => 'Назначить программу';

  @override
  String get assignTrainee => 'Назначить подопечному';

  @override
  String get assignEmptyPrograms => 'Сначала создайте свою программу.';

  @override
  String get assignEmptyTrainees =>
      'Пока нет подопечных, которым вы можете назначить программу.';

  @override
  String get assignSuccess => 'Программа назначена';

  @override
  String get assignFailed =>
      'Не удалось подтвердить назначение. Проверьте сеть и статус связи, затем повторите.';

  @override
  String assignedBy(String name) {
    return 'Назначил: $name';
  }

  @override
  String assignedOn(String date) {
    return 'Назначена $date';
  }

  @override
  String get programReadOnly =>
      'Программа тренера — доступна для просмотра и тренировки.';

  @override
  String get programUnavailable =>
      'Программа недоступна: она удалена или доступ закрыт.';

  @override
  String get dataLoadFailed =>
      'Не удалось загрузить данные. Проверьте сеть и повторите.';

  @override
  String get retry => 'Повторить';

  @override
  String workoutCoach(String name) {
    return 'Тренер: $name';
  }

  @override
  String get workoutCoachUnknown => 'Тренер: имя не сохранено';

  @override
  String get workoutSolo => 'Без тренера';

  @override
  String get workoutPendingMark => 'ещё не записано';

  @override
  String get programMissingExercise =>
      'Упражнение недоступно. Начать этот день пока нельзя.';
}
