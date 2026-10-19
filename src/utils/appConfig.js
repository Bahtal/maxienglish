export const STORE_KEY = 'lessonly-demo-v2';
export const weekdays = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
export const weekdaysShort = ['вс', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб'];
export const themeOptions = [
  { id: 'default', name: 'Светлая', description: 'Чистая и лёгкая тема по умолчанию.', colors: ['var(--preview-background)', 'var(--preview-surface)', 'var(--preview-purple)'] },
  { id: 'darked', name: 'Тёмная', description: 'Мягкий тёмный фон для вечерних занятий.', colors: ['var(--preview-background)', 'var(--preview-surface)', 'var(--preview-purple)'] },
];
export const allowedThemeIds = new Set(themeOptions.map(({ id }) => id));
export const normalizeTheme = (value) => allowedThemeIds.has(value) ? value : 'default';
export const dateKey = (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
export const todayKey = () => dateKey(new Date());
export const nextDate = (weekday, weeksLater = 0, time = '11:00') => {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  let days = (weekday - date.getDay() + 7) % 7;
  if (days === 0) days = 7;
  date.setDate(date.getDate() + days + weeksLater * 7);
  return dateKey(date);
};
export const dateObject = (key, time = '00:00') => {
  const [year, month, day] = String(key).split('-').map(Number);
  const [hour, minute] = time.split(':').map(Number);
  return new Date(year, month - 1, day, hour, minute);
};
export const formatDay = (value, options = { day: 'numeric', month: 'long' }) => {
  if (!value) return '—';
  const date = /^\d{4}-\d{2}-\d{2}$/.test(String(value)) ? dateObject(value) : new Date(value);
  return Number.isNaN(date.getTime()) ? '—' : new Intl.DateTimeFormat('ru-RU', options).format(date);
};
export const formatWeekday = (value, short = false) => {
  const weekday = dateObject(value).getDay();
  return short ? weekdaysShort[weekday] : weekdays[weekday];
};
export const cap = (value = '') => value ? value[0].toLocaleUpperCase('ru-RU') + value.slice(1) : '';
export const initials = (value = '') => value.trim().split(/\s+/).slice(0, 2).map((part) => part[0] || '').join('').toLocaleUpperCase('ru-RU');
export const humanCount = (count, one, few, many) => count % 10 === 1 && count % 100 !== 11 ? one : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14) ? few : many;
export const dateTimeIso = (date, time) => new Date(`${date}T${time}:00`).toISOString();
export const statusLabel = (status) => ({ paid: 'Оплачено', awaiting: 'Ожидает оплаты', unpaid: 'Не оплачено', completed: 'Завершено', cancelled: 'Отменено' }[status] || status);
export const statusClass = (status) => ({ paid: 'paid', awaiting: 'pending', unpaid: 'unpaid', completed: 'paid', cancelled: 'unpaid' }[status] || 'paid');
export const isDoneHomework = (item) => item.status === 'done' || item.status === 'completed';
export const isValidHttpsUrl = (value) => {
  if (!String(value || '').trim()) return true;

  try {
    const url = new URL(String(value).trim());
    return url.protocol === 'https:' && Boolean(url.hostname);
  } catch {
    return false;
  }
};
