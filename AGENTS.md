# Progress Bar — инструкции для Codex

Журнал силовых тренировок для тренера и подопечного. Flutter, iOS и Android из одной кодовой базы. Владелец делает приложение в первую очередь для себя.

Общайся с владельцем по-русски, простыми словами; объясняй термины. Коммить только по его просьбе.

## Источники и начало работы

- `docs/REQUIREMENTS.md` — главный документ о продукте: MVP, отложенные возможности, экраны, дизайн и сервер. Прочитай перед работой над поведением приложения. Новые решения записывай только после обсуждения с владельцем.
- Текущий статус, блокеры и очередь работ — разделы «Где мы сейчас» и «Что делать дальше» в `CLAUDE.md`. Проверяй их перед продолжением разработки; не веди вторую копию статуса здесь.
- Перед изменениями кода проверь исходное состояние командами `rtk proxy flutter analyze` и `rtk proxy flutter test`. После изменений выполни соответствующие проверки; сообщи о непрошедших или недоступных проверках.
- Все shell-команды запускай через `rtk`: поддерживаемые — напрямую, остальные — через `rtk proxy <команда>`.
- iOS и Android собирай и проверяй по очереди. Перед запуском другой платформы выключай запущенный для проверки симулятор/эмулятор; учитывай доступную память.

## Код и правила продукта

- `lib/domain/` — модели и чистая логика без Flutter и Firebase. Новое поведение сначала реализуется здесь и покрывается тестами.
- `lib/data/` — доступ к Firebase за интерфейсами `AuthRepository`, `ProfileRepository`, `ProgramRepository`, `WorkoutRepository`, `PersonalExerciseRepository`. Вход и профиль в тестах подменяются на `test/support/fakes.dart`, хранение — настоящие репозитории поверх `FakeFirebaseFirestore`.
- Хранение программ, тренировок и личных упражнений описано в разделе «Хранение данных» в `CLAUDE.md`; прочитай его перед правкой `lib/data/` или `firestore.rules`. Главное: тренировку пиши только через `WorkoutRepository`, запись в Firestore не жди через `await` — без сети она не завершается.
- `lib/features/<раздел>/` — экраны; состояние — Riverpod, маршруты — go_router в `lib/router.dart`.
- `lib/widgets/` — общие виджеты, включая `GlowBackground` и `GlassPanel`.
- План и факт хранятся раздельно. При старте тренировки сохраняется копия плана; изменение программы не переписывает историю.
- Упрощённый ввод «подходы × повторения × вес» — только способ ввода. Данные всегда хранятся по подходам.
- Вес тела участвует только в упражнениях с `usesBodyWeight`; его значение сохраняется в тренировке при старте.
- Одновременно допустима одна активная тренировка. Наличие требования не означает, что оно уже реализовано: сверяйся с кодом и текущим статусом.
- Строки интерфейса — в `lib/l10n/`; каждая строка должна быть во всех трёх языках: ru, en, kk. Казахский перевод ещё требует проверки носителем.

## Дизайн

- Темы: тёмная «Закат» и светлая «Рассвет», по настройке системы. Основной материал — стекло, акцент — янтарный.
- Источник токенов — `design/system/project/tokens.json`; `lib/design/tokens.g.dart` генерируется, руками его не править.
- Цвета, отступы, радиусы и стили текста брать из `PbColors`, `PbSpace`, `PbRadius`, `PbText`.
- Шрифты: Golos Text для текста, Fira Sans Extra Condensed для цифр; файлы в `assets/fonts/`.
- Дизайн-система — `design/system/project/`, макеты экранов и состояний — `design/screens/project/`, общие стили — `pb.css` в каталоге макетов. Ссылки на опубликованные макеты — в `docs/REQUIREMENTS.md`.
- Макеты написаны на HTML: значения переносить точно, виджеты реализовывать на Flutter.
- Не использовать сине-фиолетовые градиенты, эмодзи вместо иконок и декоративные плитки.
- Основные действия располагать в нижней половине экрана, области касания — не меньше 48.
- Использовать системные элементы управления там, где они есть. Экран тренировки проверять с крупным системным шрифтом.
- При работе над дизайном см. `.claude/skills/impeccable` и отчёт `.impeccable/critique/`.

## Команды

```bash
rtk proxy flutter analyze
rtk proxy flutter test
rtk proxy dart run tool/gen_tokens.dart       # после изменения токенов
rtk proxy flutter gen-l10n                    # после изменения lib/l10n/*.arb
rtk proxy flutter build ios --simulator --debug
rtk proxy flutter build apk --debug

# Правила доступа на эмуляторе Firestore (Java 21+; один раз: npm --prefix firestore_tests install):
rtk proxy npx -y firebase-tools@latest emulators:exec --only firestore --project demo-progressbar "npm --prefix firestore_tests test"

# Офлайн-хранение с перезапуском приложения; эмуляторы запущены, iOS-симулятор включён:
rtk proxy npx -y firebase-tools@latest emulators:start --only firestore,auth --project progressbar-app
tool/offline_storage_test.sh <simulator-id>

# Развернуть правила доступа:
rtk proxy npx -y firebase-tools@latest deploy --only firestore:rules --project progressbar-app

# Сквозной тест входа через настоящий Firebase; нужен запущенный симулятор/эмулятор:
rtk proxy flutter test integration_test/sign_in_test.dart -d <device-id> --dart-define-from-file=<private-json>
```

Firebase CLI запускается через `rtk proxy npx -y firebase-tools@latest …`; также можно использовать доступные инструменты Firebase MCP. Правила доступа — `firestore.rules`; изменения правил требуют развёртывания для применения на сервере.

## Firebase и окружение

- Проект — `progressbar-app`, Firestore — `europe-west3`, идентификатор приложений — `com.atelbay.progressbar`.
- Параметры подключения — `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`.
- Состояние оплаты и проверки тестового входа описаны в `CLAUDE.md` и `docs/REQUIREMENTS.md`. Подключение тарифа и успешный вход — разные проверки; подтверждай результат каждой отдельно.
- `appVerificationDisabledForTesting` включён только в отладочных сборках. В релизе он должен быть выключен; настоящий номер владельца нужно убрать из тестовых перед выпуском.
- SMS-вход на настоящем iPhone и доставка через сторы зависят от настройки Apple и аккаунтов разработчика; текущее состояние см. в `CLAUDE.md`.
- Эмуляторам Firebase нужна Java 21+, а `JAVA_HOME` по умолчанию указывает на 17; способ переключения — в разделе «Грабли» в `CLAUDE.md`. Тесты на эмуляторах не обращаются к боевому проекту.
- `flutterfire configure` повторно нужен только при добавлении платформы. Для него требуется Ruby-библиотека `xcodeproj`; сведения о временном `GEM_HOME`/`GEM_PATH` — в разделе «Грабли» в `CLAUDE.md`.
- Первая Android-сборка может занимать около 15 минут. Известные предупреждения `flutter doctor` об Android cmdline-tools и лицензиях описаны в `CLAUDE.md`; фактический результат сборки проверяй отдельно.
