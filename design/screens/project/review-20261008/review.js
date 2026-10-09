'use strict';

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const escapeHtml = (value) => String(value).replace(/[&<>"']/g, (char) => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[char]));
const number = (value) => Number(value).toLocaleString('ru-RU', { maximumFractionDigits: 2 });
const numeric = (value) => value.trim() === '' ? NaN : Number(value.replace(',', '.'));
const motion = () => matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth';
const icons = {
  plus: '<path d="M6 12h12M12 6v12"/>', minus: '<path d="M6 12h12"/>',
  close: '<path d="m6 6 12 12M18 6 6 18"/>', check: '<path d="m5 12 4 4L19 6"/>',
  chevron: '<path d="m9 5 7 7-7 7"/>', back: '<path d="m15 5-7 7 7 7"/>',
  delete: '<path d="M9 6h10a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-6-6 6-6zM12 10l4 4M16 10l-4 4"/>',
  battery: '<rect x="2" y="7" width="17" height="10" rx="2"/><path d="M22 10v4M5 10h11v4H5z"/>',
  wifi: '<path d="M3 8a14 14 0 0 1 18 0M6 12a9 9 0 0 1 12 0M9 16a4 4 0 0 1 6 0M12 20h.01"/>',
};
const icon = (name, className = '') => `<svg class="${className}" viewBox="0 0 24 24" aria-hidden="true">${icons[name]}</svg>`;
const glows = () => '<div class="glow g1"></div><div class="glow g2"></div><div class="glow g3"></div>';
const statusbar = () => `<div class="statusbar" aria-hidden="true"><span>9:41</span><span class="status-icons">${icon('wifi')}${icon('battery')}</span></div>`;
const summary = (value) => `${value.sets} × ${value.reps} × ${number(value.weight)} кг`;
const validDraft = (draft) => Number.isInteger(draft.sets) && draft.sets >= 1 && draft.sets <= 20 && Number.isInteger(draft.reps) && draft.reps >= 1 && draft.reps <= 999 && Number.isFinite(draft.weight) && draft.weight >= 0 && draft.weight <= 999.75 && Number.isInteger(draft.weight * 4);
let owner = 'own';
let visiblePage = 'workout';
let toastTimers = new Map();

const initialExercises = () => [
  { id: 'bench', name: 'Жим лёжа', plan: { sets: 3, reps: 8, weight: 60 }, fact: { sets: 3, reps: 8, weight: 60 }, done: true, added: false },
  { id: 'incline', name: 'Жим на наклонной', plan: { sets: 3, reps: 10, weight: 22.5 }, fact: null, done: false, added: false },
  { id: 'cable', name: 'Разводка в кроссовере', plan: { sets: 3, reps: 12, weight: 15 }, fact: null, done: false, added: false },
  { id: 'french', name: 'Французский жим', plan: null, fact: null, done: false, added: false },
];
const createWorkout = (variant) => ({ variant, exercises: initialExercises(), selected: 'french', sheet: variant === 'b' ? 'entry' : null, mode: 'summary', draft: { sets: 3, reps: 10, weight: 7.5 }, activeField: 'sets', typed: { sets: '3', reps: '10', weight: '7,5' }, replace: true, planDraft: null, planDay: 'Грудь и трицепс', planTarget: null, finished: false });
const workouts = { a: createWorkout('a'), b: createWorkout('b') };

function selectedExercise(state) { return state.exercises.find((exercise) => exercise.id === state.selected); }
function suggestedExercise(state) { return state.exercises.find((exercise) => !exercise.done); }

function entryFields(draft, prefix, mode, target = 'draft', state = null) {
  if (state && target === 'draft') {
    const field = (key, label) => `<label class="entry-field sequence-field ${key === 'weight' ? 'weight' : ''}"><span class="label">${label}</span><span class="field-value"><input readonly inputmode="none" class="value-input ${state.activeField === key ? 'active-value' : ''}" aria-label="${label}" value="${escapeHtml(state.typed[key] || '—')}" data-action="field" data-field="${key}" aria-current="${state.activeField === key ? 'true' : 'false'}">${key === 'weight' ? '<span class="unit-text">кг</span>' : ''}</span></label>`;
    return `<div class="entry-fields">${mode === 'summary' ? field('sets', 'Подходы') : ''}${field('reps', 'Повторения')}${field('weight', 'Вес')}</div>`;
  }
  const field = (key, label, step) => `<label class="entry-field ${key === 'weight' ? 'weight' : ''}">
    <span class="label">${label}</span>
    <span class="field-value"><input class="value-input" id="${prefix}-${key}" aria-label="${label}" inputmode="${key === 'weight' ? 'decimal' : 'numeric'}" value="${escapeHtml(number(draft[key]))}" data-draft="${target}" data-field="${key}">${key === 'weight' ? '<span class="unit-text">кг</span>' : ''}
    ${key === 'weight' ? `<span class="small-steps"><button type="button" class="icon" data-action="step" data-field="weight" data-delta="-${step}" data-target="${target}" aria-label="Уменьшить вес">${icon('minus')}</button><button type="button" class="icon" data-action="step" data-field="weight" data-delta="${step}" data-target="${target}" aria-label="Увеличить вес">${icon('plus')}</button></span>` : ''}</span>
    ${key !== 'weight' ? `<span class="small-steps"><button type="button" class="icon" data-action="step" data-field="${key}" data-delta="-1" data-target="${target}" aria-label="Уменьшить ${label.toLowerCase()}">${icon('minus')}</button><button type="button" class="icon" data-action="step" data-field="${key}" data-delta="1" data-target="${target}" aria-label="Увеличить ${label.toLowerCase()}">${icon('plus')}</button></span>` : ''}
  </label>`;
  return `<div class="entry-fields">${mode === 'summary' ? field('sets', 'Подходы', 1) : ''}${field('reps', 'Повторения', 1)}${field('weight', 'Вес', .5)}</div>`;
}

function entryContent(state) {
  const exercise = selectedExercise(state);
  return `<div class="entry-content">
    <div class="entry-mode" role="group" aria-label="Режим ввода результата"><button data-action="mode" data-value="summary" class="${state.mode === 'summary' ? 'active' : ''}" aria-pressed="${state.mode === 'summary'}">Итогом</button><button data-action="mode" data-value="sets" class="${state.mode === 'sets' ? 'active' : ''}" aria-pressed="${state.mode === 'sets'}">По подходам</button></div>
    ${state.mode === 'sets' ? `<div class="cap">Подход ${(exercise.fact?.sets || 0) + 1}${exercise.plan ? ` из ${exercise.plan.sets}` : ' · вне плана'}</div>${exercise.fact ? `<div class="set-list">${Array.from({ length: exercise.fact.sets }, (_, index) => `<span class="set-token">${index + 1}: ${exercise.fact.reps} × ${number(exercise.fact.weight)} кг</span>`).join('')}</div>` : ''}` : ''}
    ${entryFields(state.draft, state.variant, state.mode, 'draft', state)}
    <div class="cap entry-error" data-error hidden>Проверьте числа: 1–20 подходов, 1–999 повторений, вес 0–999,75 кг с шагом 0,25.</div>
    ${exercise.plan ? `<div class="cap">План: ${summary(exercise.plan)}</div>` : '<div class="cap">Упражнение добавлено во время тренировки</div>'}
  </div>`;
}

const workoutFields = (state) => state.mode === 'summary' ? ['sets', 'reps', 'weight'] : ['reps', 'weight'];
const lastWorkoutField = (state) => state.activeField === workoutFields(state).at(-1);
const activeWorkoutValueValid = (state) => {
  const value = state.draft[state.activeField];
  return state.activeField === 'weight' ? Number.isFinite(value) && value >= 0 && value <= 999.75 && Number.isInteger(value * 4) : Number.isInteger(value) && value >= 1 && value <= (state.activeField === 'sets' ? 20 : 999);
};
function recordLabel(state) { return !lastWorkoutField(state) ? 'Продолжить' : state.mode === 'summary' ? 'Записать итог' : 'Записать подход'; }
function workoutKeyboard(state) {
  const label = { sets: 'Подходы', reps: 'Повторения', weight: 'Вес, кг' }[state.activeField];
  return `<div class="sequence-keyboard"><span class="label">${label}</span><div class="keys" role="group" aria-label="Кастомная цифровая клавиатура">${['1','2','3','4','5','6','7','8','9',',','0','delete'].map((key) => `<button class="pill key" data-action="key" data-key="${key}" ${key === ',' && state.activeField !== 'weight' ? 'disabled' : ''} aria-label="${key === 'delete' ? 'Стереть цифру' : key === ',' ? 'Запятая' : key}">${key === 'delete' ? icon('delete') : key}</button>`).join('')}</div></div>`;
}
function canFinishExercise(state) { return state.mode === 'sets' && selectedExercise(state)?.fact && !selectedExercise(state)?.plan; }

function exerciseCard(state, exercise, index) {
  const active = state.selected === exercise.id;
  const expanded = active && state.variant === 'a';
  return `<section class="exercise ${active ? 'selected' : ''}" data-exercise="${exercise.id}">
    <button class="exercise-trigger" data-action="select" data-id="${exercise.id}" ${state.variant === 'a' ? `aria-expanded="${expanded}"` : 'aria-haspopup="dialog"'}>
      <span class="exercise-number">${exercise.done ? icon('check') : index + 1}</span>
      <span class="exercise-text"><span class="exercise-name">${exercise.name}</span>
        <span class="exercise-meta">${exercise.plan ? '' : '<span class="chip extra">Вне плана</span>'}${exercise.done ? '<span class="done-label">Завершено</span>' : exercise.fact ? '<span>Есть записи</span>' : active ? '<span>Ввод результата</span>' : '<span>Не записано</span>'}</span>
        ${!expanded && (exercise.fact || exercise.plan) ? `<span class="${exercise.fact ? 'exercise-result' : 'cap'}">${exercise.fact ? summary(exercise.fact) : `План: ${summary(exercise.plan)}`}</span>` : ''}
      </span>${icon('chevron', 'exercise-chevron')}
    </button>
    ${expanded ? entryContent(state) : ''}
    ${exercise.done && !exercise.plan && owner === 'own' && !exercise.added ? `<button class="card-action" data-action="add-to-plan" data-id="${exercise.id}">Добавить в план</button>` : ''}
    ${exercise.added ? `<div class="cap card-plan-saved">В будущем плане · ${escapeHtml(exercise.planDay)}</div>` : ''}
  </section>`;
}

function workoutSheet(state) {
  const exercise = selectedExercise(state);
  if (state.sheet === 'entry' && exercise) {
    return `<div class="layer"><section class="modal-sheet" role="dialog" aria-label="Результат: ${exercise.name}" tabindex="-1">
      <div class="sheet-heading"><div><h3>${exercise.name}</h3>${!exercise.plan ? '<span class="chip extra">Вне плана</span>' : ''}</div><button class="icon" data-action="close" aria-label="Закрыть ввод">${icon('close')}</button></div>
      ${entryContent(state)}${workoutKeyboard(state)}<div class="sheet-actions"><button class="btn" data-action="record" ${activeWorkoutValueValid(state) ? '' : 'disabled'}>${recordLabel(state)}</button>${canFinishExercise(state) ? '<button class="btn text" data-action="finish-exercise">Закончить упражнение</button>' : ''}</div>
    </section></div>`;
  }
  if (state.sheet === 'plan') {
    const target = state.exercises.find((item) => item.id === state.planTarget);
    return `<div class="layer"><section class="modal-sheet" role="dialog" aria-label="Добавить упражнение в план" tabindex="-1">
      <div class="sheet-heading"><div><h3>Добавить в план</h3><div class="cap">${target.name} · Сила, 3 дня</div></div><button class="icon" data-action="close" aria-label="Отменить добавление в план">${icon('close')}</button></div>
      <label class="day-select">День программы<select data-action="plan-day">${['Грудь и трицепс','Спина и бицепс','Ноги'].map((day) => `<option ${state.planDay === day ? 'selected' : ''}>${day}</option>`).join('')}</select></label>
      <p class="cap">Подставлен записанный итог. При необходимости измените будущий план.</p>
      ${entryFields(state.planDraft, `${state.variant}-plan`, 'summary', 'planDraft')}
      <p class="cap entry-error" data-error hidden>Проверьте числа: 1–20 подходов, 1–999 повторений, вес 0–999,75 кг с шагом 0,25.</p>
      <p class="cap">Изменится будущий план. В этой тренировке упражнение останется вне плана.</p>
      <div class="sheet-actions"><button class="btn" data-action="confirm-plan" ${validDraft(state.planDraft) ? '' : 'disabled'}>Добавить в план</button><button class="btn text" data-action="close">Отмена</button></div>
    </section></div>`;
  }
  if (state.sheet === 'finish') {
    const pending = state.exercises.filter((item) => !item.done).length;
    return `<div class="layer"><section class="modal-sheet" role="dialog" aria-label="Завершение тренировки" tabindex="-1">
      <div class="sheet-heading"><div><h3>Завершить тренировку?</h3></div><button class="icon" data-action="close" aria-label="Вернуться к тренировке">${icon('close')}</button></div>
      <p class="dialog-text">${pending ? `Ещё не завершено упражнений: ${pending}. Записанные результаты сохранятся.` : 'Все упражнения записаны.'}</p>
      <div class="sheet-actions"><button class="btn" data-action="confirm-finish">Завершить</button><button class="btn text" data-action="close">Продолжить тренировку</button></div>
    </section></div>`;
  }
  return '';
}

function renderWorkout(variant, { scrollToCurrent = false, focusSheet = false } = {}) {
  const state = workouts[variant];
  const root = $(`#workout-${variant}`);
  const oldScroll = $('.exercise-list', root)?.scrollTop || 0;
  const active = selectedExercise(state);
  const next = suggestedExercise(state);
  const done = state.exercises.filter((exercise) => exercise.done).length;
  root.innerHTML = `${glows()}${statusbar()}
    <header class="app-header"><h2>Грудь и трицепс</h2><button class="btn text small" data-action="finish">Завершить</button></header>
    <div class="progress"><div class="bar" role="img" aria-label="Завершено ${done} из ${state.exercises.length} упражнений">${state.exercises.map((exercise) => `<span class="plate ${exercise.done ? 'done' : exercise.id === state.selected ? 'now' : ''}"></span>`).join('')}<span class="collar"></span></div><span class="progress-label"><strong>${done}</strong> из ${state.exercises.length}</span></div>
    <div class="exercise-list">${state.exercises.map((exercise, index) => exerciseCard(state, exercise, index)).join('')}<button class="btn text" data-action="add-exercise">${icon('plus')}Добавить упражнение</button></div>
    <div class="app-bottom">${state.finished ? '<span class="cap done-label">Тренировка завершена в макете</span><button class="btn ghost" data-action="reset">Начать пример заново</button>' : state.variant === 'a' && active ? `${workoutKeyboard(state)}<button class="btn" data-action="record" ${activeWorkoutValueValid(state) && (!lastWorkoutField(state) || validDraft(state.draft)) ? '' : 'disabled'}>${recordLabel(state)}</button>${canFinishExercise(state) ? '<button class="btn text" data-action="finish-exercise">Закончить упражнение</button>' : ''}` : next ? `<span class="cap">Далее: ${next.name}</span><button class="btn" data-action="select" data-id="${next.id}">Записать результат</button>` : '<span class="cap">Все упражнения записаны</span><button class="btn" data-action="finish">Завершить тренировку</button>'}</div>${workoutSheet(state)}`;
  const list = $('.exercise-list', root);
  list.scrollTop = oldScroll;
  if (state.sheet) {
    $$('.exercise-list, .app-bottom, .app-header', root).forEach((element) => { element.inert = true; });
  }
  if (scrollToCurrent && active && state.variant === 'a') {
    const card = $(`[data-exercise="${active.id}"]`, root);
    list.scrollTo({ top: card.offsetTop - list.offsetTop, behavior: motion() });
  }
  if (focusSheet && state.sheet) $('.modal-sheet', root)?.focus({ preventScroll: true });
}

function toast(root, message) {
  clearTimeout(toastTimers.get(root.id));
  $('.toast', root)?.remove();
  const node = document.createElement('div');
  node.className = 'toast'; node.setAttribute('role', 'status'); node.textContent = message;
  root.append(node);
  toastTimers.set(root.id, setTimeout(() => node.remove(), 3500));
}

function selectWorkout(state, id) {
  state.selected = id;
  const exercise = selectedExercise(state);
  state.draft = { ...(exercise.fact || exercise.plan || { sets: 3, reps: 10, weight: 7.5 }) };
  state.typed = Object.fromEntries(Object.entries(state.draft).map(([key, value]) => [key, number(value)]));
  state.activeField = workoutFields(state)[0]; state.replace = true;
  if (state.variant === 'b') state.sheet = 'entry';
}

function finishExercise(state) {
  const exercise = selectedExercise(state);
  exercise.done = true;
  state.sheet = null;
  state.selected = null;
  const next = suggestedExercise(state);
  if (state.variant === 'a' && next) selectWorkout(state, next.id);
}

function recordWorkout(state) {
  if (!activeWorkoutValueValid(state)) return false;
  if (!lastWorkoutField(state)) {
    state.activeField = workoutFields(state)[workoutFields(state).indexOf(state.activeField) + 1];
    state.replace = true;
    return false;
  }
  if (!validDraft(state.draft)) return;
  const exercise = selectedExercise(state);
  if (state.mode === 'summary') {
    exercise.fact = { ...state.draft };
    finishExercise(state);
  } else {
    exercise.fact = { ...state.draft, sets: (exercise.fact?.sets || 0) + 1 };
    if (exercise.plan && exercise.fact.sets >= exercise.plan.sets) finishExercise(state);
    else { state.activeField = workoutFields(state)[0]; state.replace = true; }
  }
  return true;
}

function typeWorkoutKey(state, key) {
  let value = state.typed[state.activeField];
  if (key === 'delete') { value = value.slice(0, -1); }
  else if (key === ',') {
    if (state.activeField !== 'weight') return;
    if (state.replace) value = '';
    if (!value.includes(',')) value = (value || '0') + ',';
  } else {
    value = state.replace ? key : value + key;
    if (value.length > 6) return;
  }
  state.replace = false;
  state.typed[state.activeField] = value;
  state.draft[state.activeField] = numeric(value);
}

function workoutAction(variant, event) {
  const control = event.target.closest('[data-action]');
  if (!control || control.disabled) return;
  const state = workouts[variant];
  const action = control.dataset.action;
  if (control.tagName === 'SELECT') return;
  if (state.finished && !['reset', 'close'].includes(action)) return;
  let scrollToCurrent = false;
  let message = null;
  if (action === 'select') { selectWorkout(state, control.dataset.id); scrollToCurrent = true; }
  else if (action === 'mode') { state.mode = control.dataset.value; state.activeField = workoutFields(state)[0]; state.replace = true; }
  else if (action === 'field') { state.activeField = control.dataset.field; state.replace = true; }
  else if (action === 'key') { typeWorkoutKey(state, control.dataset.key); }
  else if (action === 'step') {
    event.preventDefault();
    const target = control.dataset.target;
    const key = control.dataset.field;
    const limits = { sets: [1, 20], reps: [1, 999], weight: [0, 999.75] };
    const [min, max] = limits[key];
    state[target][key] = Math.min(max, Math.max(min, (Number.isFinite(state[target][key]) ? state[target][key] : min) + Number(control.dataset.delta)));
  }
  else if (action === 'record') { if (recordWorkout(state)) { scrollToCurrent = true; message = state.mode === 'summary' ? 'Итог записан' : 'Подход записан'; } }
  else if (action === 'finish-exercise') { finishExercise(state); scrollToCurrent = true; }
  else if (action === 'close') { state.sheet = null; if (state.variant === 'b') state.selected = null; }
  else if (action === 'add-to-plan') {
    if (owner !== 'own') return;
    state.planTarget = control.dataset.id; state.planDay = 'Грудь и трицепс';
    state.planDraft = { ...state.exercises.find((exercise) => exercise.id === state.planTarget).fact };
    state.sheet = 'plan';
  }
  else if (action === 'confirm-plan') {
    if (owner !== 'own' || !validDraft(state.planDraft)) return;
    const exercise = state.exercises.find((item) => item.id === state.planTarget);
    exercise.added = true; exercise.futurePlan = { ...state.planDraft }; exercise.planDay = state.planDay;
    state.sheet = null; message = 'Добавлено в будущий план';
  }
  else if (action === 'finish') { state.sheet = 'finish'; }
  else if (action === 'confirm-finish') { state.finished = true; state.sheet = null; state.selected = null; }
  else if (action === 'add-exercise') {
    // One catalog choice keeps this prototype focused on recording, not search.
    const existing = state.exercises.find((exercise) => exercise.id === 'pushdown');
    if (existing) { selectWorkout(state, existing.id); }
    else { state.exercises.push({ id: 'pushdown', name: 'Разгибание рук на блоке', plan: null, fact: null, done: false, added: false }); selectWorkout(state, 'pushdown'); }
    scrollToCurrent = true;
  }
  else if (action === 'reset') { workouts[variant] = createWorkout(variant); }
  renderWorkout(variant, { scrollToCurrent, focusSheet: Boolean(state.sheet) });
  if (['key', 'field', 'record'].includes(action) && !state.sheet) focusWorkoutValue(variant);
  if (message) toast($(`#workout-${variant}`), message);
}

function focusWorkoutValue(variant) {
  const root = $(`#workout-${variant}`);
  const value = $('.value-input.active-value', root);
  const list = $('.exercise-list', root);
  if (!value || !list) return;
  value.focus({ preventScroll: true });
  const fieldRect = value.getBoundingClientRect();
  const listRect = list.getBoundingClientRect();
  if (fieldRect.bottom > listRect.bottom) list.scrollTop += fieldRect.bottom - listRect.bottom + 8;
  else if (fieldRect.top < listRect.top) list.scrollTop += fieldRect.top - listRect.top - 8;
}

for (const variant of ['a', 'b']) {
  const root = $(`#workout-${variant}`);
  root.addEventListener('click', (event) => workoutAction(variant, event));
  root.addEventListener('input', (event) => {
    const control = event.target;
    if (!control.matches('[data-draft]')) return;
    const state = workouts[variant];
    state[control.dataset.draft][control.dataset.field] = numeric(control.value);
    const valid = validDraft(state[control.dataset.draft]);
    $$('[data-action="record"], [data-action="confirm-plan"]', root).forEach((button) => { button.disabled = !valid; });
    $$('[data-error]', root).forEach((error) => { error.hidden = valid; });
  });
  root.addEventListener('change', (event) => {
    if (event.target.matches('[data-action="plan-day"]')) workouts[variant].planDay = event.target.value;
  });
}

const planScenarios = {
  new: { name: 'Французский жим', caption: 'Раньше не записывали — введите вес', weight: '', count: '10', known: false },
  history: { name: 'Французский жим', caption: 'В прошлый раз: 3 × 10 × 7,5 кг', weight: '7,5', count: '10', known: true },
  saved: { name: 'Французский жим', caption: 'Сохранённый план: 3 × 10 × 10 кг', weight: '10', count: '10', known: true },
  time: { name: 'Планка', caption: 'Длительность каждого подхода', weight: '', count: '30', known: false, timed: true },
  body: { name: 'Подтягивания', caption: 'Дополнительный вес · без отягощения введите 0', weight: '', count: '8', known: false, body: true },
};
function createPlan(scenario = 'new') { const template = planScenarios[scenario]; return { scenario, active: 'sets', values: { sets: '3', reps: template.count, weight: template.weight }, replace: true, typing: true, note: '', noteOpen: false, open: true, saved: null }; }
let plan = createPlan();
const planKeys = () => planScenarios[plan.scenario].timed ? ['sets', 'reps'] : ['sets', 'reps', 'weight'];
const planLabel = (key) => key === 'sets' ? 'Подходы' : key === 'reps' ? planScenarios[plan.scenario].timed ? 'Время' : 'Повторения' : planScenarios[plan.scenario].body ? 'Доп. вес' : 'Вес';
const validPlanValue = (key) => {
  const value = numeric(plan.values[key]);
  if (key === 'sets') return Number.isInteger(value) && value >= 1 && value <= 20;
  if (key === 'reps') return Number.isInteger(value) && value >= 1 && value <= 999;
  return Number.isFinite(value) && value >= 0 && value <= 999.75 && Number.isInteger(value * 4);
};
const allPlanValid = () => planKeys().every(validPlanValue);

function renderPlan({ focusSheet = false } = {}) {
  const root = $('#planning');
  const oldScroll = $('.plan-scroll', root)?.scrollTop || 0;
  const template = planScenarios[plan.scenario];
  const final = plan.active === planKeys().at(-1);
  const keypad = plan.active !== 'weight' || plan.typing || !template.known;
  const label = planLabel(plan.active);
  const unit = (key) => key === 'weight' ? 'кг' : key === 'reps' && template.timed ? 'с' : '';
  root.innerHTML = `${glows()}${statusbar()}
    <header class="app-header"><button class="icon" data-plan-action="back" aria-label="Назад к планированию">${icon('back')}</button><h2>Сила, 3 дня</h2></header>
    <div class="builder-tabs"><span class="pill on">Грудь и трицепс</span><span class="pill">Спина и бицепс</span></div>
    <div class="builder-list"><div class="exercise"><span class="exercise-name">Жим лёжа</span><span class="exercise-result">3 × 8 × 60 кг</span></div><div class="exercise"><span class="exercise-name">Жим на наклонной</span><span class="exercise-result">3 × 10 × 22,5 кг</span></div>
      ${plan.saved ? `<div class="exercise selected"><span class="exercise-name">${template.name}</span><span class="exercise-result">${template.timed ? `${plan.saved.sets} × ${plan.saved.reps} с` : summary(plan.saved)}</span>${plan.note ? `<span class="cap">${escapeHtml(plan.note)}</span>` : ''}<span class="added-mark">${icon('check')}План сохранён</span></div>` : ''}
      <button class="btn ghost" data-plan-action="open">${icon('plus')}${plan.saved ? 'Изменить упражнение' : 'Добавить упражнение'}</button>
    </div><div class="app-bottom"><button class="btn" data-plan-action="start">Начать тренировку</button></div>
    ${plan.open ? `<div class="layer"><section class="modal-sheet plan-sheet" role="dialog" aria-label="План: ${template.name}" tabindex="-1"><div class="plan-scroll">
      <div class="sheet-heading plan-heading"><div><h3>${template.name}</h3><div class="cap">${template.caption}</div></div><button class="icon" data-plan-action="close" aria-label="Закрыть план без сохранения">${icon('close')}</button></div>
      <div class="plan-fields ${template.timed ? 'two' : ''}" role="group" aria-label="Параметры плана">${planKeys().map((key) => `<button class="plan-field ${plan.active === key ? 'active' : ''}" data-plan-action="field" data-field="${key}" aria-pressed="${plan.active === key}" aria-label="${planLabel(key)}: ${plan.values[key] || 'не введено'}"><span class="plan-label">${planLabel(key)}</span><span class="plan-number ${plan.values[key].length > 4 ? 'long-number' : ''}">${escapeHtml(plan.values[key] || '—')}<span class="unit-text">${unit(key)}</span></span></button>`).join('')}</div>
      <details class="plan-note" ${plan.noteOpen ? 'open' : ''}><summary>${icon('plus')}Заметка для подопечного</summary><textarea aria-label="Заметка для подопечного" placeholder="Необязательно">${escapeHtml(plan.note)}</textarea></details>
      ${keypad ? `<div class="plan-keyboard"><div class="keyboard-label"><span class="label">${label}${unit(plan.active) ? `, ${unit(plan.active)}` : ''}</span><button class="text-key" data-plan-action="clear">Очистить</button></div><div class="keys" role="group" aria-label="Цифровая клавиатура">${['1','2','3','4','5','6','7','8','9',',','0','delete'].map((key) => `<button class="pill key" data-plan-action="key" data-key="${key}" ${key === ',' && plan.active !== 'weight' ? 'disabled' : ''} aria-label="${key === 'delete' ? 'Стереть цифру' : key === ',' ? 'Запятая' : key}">${key === 'delete' ? icon('delete') : key}</button>`).join('')}</div></div>` : `<div class="weight-steps">${[.5, 1, 5, -.5, -1, -5].map((delta) => `<button class="pill" data-plan-action="weight-step" data-delta="${delta}">${delta > 0 ? '+' : '−'}${number(Math.abs(delta))}</button>`).join('')}</div><p class="cap">Можно изменить шагами или нажать на вес и ввести число.</p>`}
      </div><div class="plan-footer"><p class="cap plan-message ${validPlanValue(plan.active) ? '' : 'entry-error'}" aria-live="polite">${validPlanValue(plan.active) ? final ? '«Готово» сохранит упражнение и закроет весь лист.' : `Далее: ${planLabel(planKeys()[planKeys().indexOf(plan.active) + 1]).toLowerCase()}` : plan.active === 'weight' ? 'Введите вес 0–999,75 кг с шагом 0,25.' : plan.active === 'sets' ? 'Введите от 1 до 20 подходов.' : 'Введите целое число от 1 до 999.'}</p>
      <button class="btn" data-plan-action="continue" ${validPlanValue(plan.active) && (!final || allPlanValid()) ? '' : 'disabled'}>${final ? 'Готово' : 'Продолжить'}</button>
    </div></section></div>` : ''}`;
  if ($('.plan-scroll', root)) $('.plan-scroll', root).scrollTop = oldScroll;
  if (plan.open) $$('.app-header, .builder-tabs, .builder-list, .app-bottom', root).forEach((element) => { element.inert = true; });
  if (focusSheet && plan.open) $('.modal-sheet', root)?.focus({ preventScroll: true });
}

function planAction(action, control) {
  const template = planScenarios[plan.scenario];
  if (action === 'field') {
    const isCurrent = plan.active === control.dataset.field;
    plan.active = control.dataset.field; plan.replace = true;
    plan.typing = plan.active !== 'weight' || !template.known || isCurrent;
  } else if (action === 'key') {
    const key = control.dataset.key;
    let value = plan.values[plan.active];
    if (key === 'delete') { value = value.slice(0, -1); plan.replace = false; }
    else if (key === ',') {
      if (plan.active !== 'weight') return;
      if (plan.replace) value = '';
      if (!value.includes(',')) value = (value || '0') + ',';
      plan.replace = false;
    } else {
      value = plan.replace ? key : value + key;
      if (value.length > 6) return;
      plan.replace = false;
    }
    plan.values[plan.active] = value;
  } else if (action === 'clear') { plan.values[plan.active] = ''; plan.replace = false; }
  else if (action === 'weight-step') {
    const value = Math.min(999.75, Math.max(0, numeric(plan.values.weight) + Number(control.dataset.delta)));
    plan.values.weight = number(value); plan.replace = true;
  } else if (action === 'continue') {
    if (!validPlanValue(plan.active)) return;
    const keys = planKeys();
    if (plan.active === keys.at(-1)) {
      if (!allPlanValid()) return;
      plan.saved = { sets: numeric(plan.values.sets), reps: numeric(plan.values.reps), weight: template.timed ? 0 : numeric(plan.values.weight) };
      plan.open = false;
    } else { plan.active = keys[keys.indexOf(plan.active) + 1]; plan.replace = true; plan.typing = plan.active !== 'weight' || !template.known; }
  } else if (action === 'close') { plan.open = false; }
  else if (action === 'open' || action === 'back') { plan.open = true; }
  else if (action === 'start') { toast($('#planning'), 'В макете показано только планирование'); return; }
  renderPlan({ focusSheet: plan.open });
}

$('#planning').addEventListener('click', (event) => {
  const control = event.target.closest('[data-plan-action]');
  if (!control || control.disabled) return;
  planAction(control.dataset.planAction, control);
});
$('#planning').addEventListener('input', (event) => { if (event.target.tagName === 'TEXTAREA') plan.note = event.target.value; });
$('#planning').addEventListener('toggle', (event) => { if (event.target.tagName === 'DETAILS') plan.noteOpen = event.target.open; }, true);

function resetAll() {
  for (const variant of ['a', 'b']) { workouts[variant] = createWorkout(variant); renderWorkout(variant, { scrollToCurrent: variant === 'a' }); }
  plan = createPlan($('#plan-scenario').value); renderPlan();
}

$$('[data-page]').forEach((button) => button.addEventListener('click', () => {
  visiblePage = button.dataset.page;
  $('#workout-page').hidden = visiblePage !== 'workout';
  $('#planning-page').hidden = visiblePage !== 'planning';
  $$('[data-page]').forEach((tab) => { const active = tab === button; tab.classList.toggle('on', active); tab.setAttribute('aria-pressed', active); });
  $('#ownership').closest('label').hidden = visiblePage === 'planning';
}));
$('#theme').addEventListener('change', (event) => {
  $$('[data-theme]').forEach((element) => { element.dataset.theme = event.target.value; });
  document.documentElement.style.background = getComputedStyle(document.body).getPropertyValue('--ground');
});
$('#text-scale').addEventListener('change', (event) => { document.documentElement.style.setProperty('--scale', event.target.value); $$('.phone').forEach((phone) => phone.classList.toggle('large-type', Number(event.target.value) > 1.2)); });
$('#ownership').addEventListener('change', (event) => {
  owner = event.target.value;
  for (const variant of ['a', 'b']) { if (workouts[variant].sheet === 'plan') workouts[variant].sheet = null; renderWorkout(variant); }
});
$('#plan-scenario').addEventListener('change', (event) => { plan = createPlan(event.target.value); renderPlan(); });
$('#reset').addEventListener('click', resetAll);

// Keyboard input works alongside the on-screen number panel. Dialog focus stays
// inside its phone, without trapping the review controls outside that phone.
document.addEventListener('keydown', (event) => {
  const root = event.target.closest('.phone');
  if (!root) return;
  const sheet = $('.modal-sheet', root);
  if (event.key === 'Escape' && sheet) {
    event.preventDefault();
    if (root.id === 'planning') { plan.open = false; renderPlan(); }
    else { const variant = root.id.at(-1); workouts[variant].sheet = null; if (variant === 'b') workouts[variant].selected = null; renderWorkout(variant); }
    return;
  }
  if (root.id === 'workout-a' && !workouts.a.sheet && workouts.a.selected && !event.target.matches('textarea, select')) {
    if (/^[0-9]$/.test(event.key) || ['Backspace', '.', ','].includes(event.key)) {
      event.preventDefault();
      typeWorkoutKey(workouts.a, event.key === 'Backspace' ? 'delete' : ['.', ','].includes(event.key) ? ',' : event.key);
      renderWorkout('a');
      focusWorkoutValue('a');
    } else if (event.key === 'Enter') { event.preventDefault(); $('[data-action="record"]', root)?.click(); }
  }
  if (root.id === 'planning' && plan.open && !event.target.matches('textarea, input, select')) {
    if (/^[0-9]$/.test(event.key) || ['Backspace', '.', ','].includes(event.key)) {
      event.preventDefault(); planAction('key', { dataset: { key: event.key === 'Backspace' ? 'delete' : ['.', ','].includes(event.key) ? ',' : event.key } });
    }
  }
});

resetAll();
