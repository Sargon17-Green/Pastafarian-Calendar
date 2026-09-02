export const JDN_MINUS_PROJECT_DAY = 1721425n;

export function floorDiv(aValue, bValue) {
  const a = BigInt(aValue);
  const b = BigInt(bValue);
  if (b === 0n) throw new RangeError("Division per zero.");
  let quotient = a / b;
  const remainder = a % b;
  if (remainder !== 0n && ((remainder > 0n) !== (b > 0n))) quotient -= 1n;
  return quotient;
}

export function isGregorianLeapYear(yearValue) {
  const year = BigInt(yearValue);
  return year % 4n === 0n && (year % 100n !== 0n || year % 400n === 0n);
}

export function daysInGregorianMonth(year, month) {
  if (month === 2) return isGregorianLeapYear(year) ? 29 : 28;
  return [31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1] ?? 0;
}

export function validateGregorian(date, fieldName = "התאריך") {
  if (!date || typeof date !== "object") throw new TypeError(`${fieldName} אינו תאריך תקין.`);
  if (!Number.isInteger(date.month) || date.month < 1 || date.month > 12) {
    throw new RangeError(`${fieldName}: החודש חייב להיות בין 1 ל־12.`);
  }
  const maxDay = daysInGregorianMonth(date.year, date.month);
  if (!Number.isInteger(date.day) || date.day < 1 || date.day > maxDay) {
    throw new RangeError(`${fieldName}: היום אינו קיים בחודש שנבחר.`);
  }
  return date;
}

export function localToday() {
  const now = new Date();
  return Object.freeze({ year: BigInt(now.getFullYear()), month: now.getMonth() + 1, day: now.getDate() });
}

export function parseIsoDate(value, fieldName = "התאריך") {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) throw new RangeError(`${fieldName} אינו תאריך תקין.`);
    return Object.freeze({ year: BigInt(value.getFullYear()), month: value.getMonth() + 1, day: value.getDate() });
  }
  if (value && typeof value === "object" && "year" in value && "month" in value && "day" in value) {
    return Object.freeze(validateGregorian({ year: BigInt(value.year), month: Number(value.month), day: Number(value.day) }, fieldName));
  }
  const match = /^(?<year>[+-]?\d+)-(?<month>\d{2})-(?<day>\d{2})$/.exec(String(value ?? "").trim());
  if (!match) throw new RangeError(`${fieldName} חייב להיות בפורמט YYYY-MM-DD.`);
  return Object.freeze(validateGregorian({
    year: BigInt(match.groups.year),
    month: Number(match.groups.month),
    day: Number(match.groups.day),
  }, fieldName));
}

export function normalizeDateInput(value, fieldName) {
  return value == null || value === "" ? localToday() : parseIsoDate(value, fieldName);
}

export function gregorianToJdn(dateValue) {
  const date = validateGregorian(dateValue);
  const month = BigInt(date.month);
  const day = BigInt(date.day);
  const a = floorDiv(14n - month, 12n);
  const year = BigInt(date.year) + 4800n - a;
  const shiftedMonth = month + 12n * a - 3n;
  return day + floorDiv(153n * shiftedMonth + 2n, 5n) + 365n * year
    + floorDiv(year, 4n) - floorDiv(year, 100n) + floorDiv(year, 400n) - 32045n;
}

export function jdnToGregorian(jdnValue) {
  const jdn = BigInt(jdnValue);
  const a = jdn + 32044n;
  const b = floorDiv(4n * a + 3n, 146097n);
  const c = a - floorDiv(146097n * b, 4n);
  const d = floorDiv(4n * c + 3n, 1461n);
  const e = c - floorDiv(1461n * d, 4n);
  const m = floorDiv(5n * e + 2n, 153n);
  const day = e - floorDiv(153n * m + 2n, 5n) + 1n;
  const month = m + 3n - 12n * floorDiv(m, 10n);
  const year = 100n * b + d - 4800n + floorDiv(m, 10n);
  return Object.freeze({ year, month: Number(month), day: Number(day) });
}

export function projectDayToJdn(dayValue) {
  return BigInt(dayValue) + JDN_MINUS_PROJECT_DAY;
}

export function jdnToProjectDay(jdnValue) {
  return BigInt(jdnValue) - JDN_MINUS_PROJECT_DAY;
}

export function padYear(yearValue) {
  const year = BigInt(yearValue);
  const negative = year < 0n;
  const digits = (negative ? -year : year).toString().padStart(4, "0");
  return `${negative ? "-" : ""}${digits}`;
}

export function toIsoDate(date) {
  return `${padYear(date.year)}-${String(date.month).padStart(2, "0")}-${String(date.day).padStart(2, "0")}`;
}
