const OUTPUT_FIELDS = Object.freeze(["year", "cutletName", "dayInCutlet", "monthName", "dayInMonth"]);

function safePositiveInteger(value, fieldName) {
  const integer = typeof value === "bigint" ? value : BigInt(value);
  if (integer <= 0n || integer > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new RangeError(`${fieldName} es extra li valid interval.`);
  }
  return Number(integer);
}

export function normalizeCalendarResult(value) {
  let source;
  if (Array.isArray(value)) {
    if (value.length !== OUTPUT_FIELDS.length) throw new TypeError("Li motor retornat un resultat con ínvalid longore.");
    source = Object.fromEntries(OUTPUT_FIELDS.map((field, index) => [field, value[index]]));
  } else if (value && typeof value === "object") {
    source = value;
  } else {
    throw new TypeError("Li motor retornat un ínvalid resultat.");
  }

  const result = {
    year: String(source.year),
    cutletName: String(source.cutletName),
    dayInCutlet: safePositiveInteger(source.dayInCutlet, "dayInCutlet"),
    monthName: String(source.monthName),
    dayInMonth: safePositiveInteger(source.dayInMonth, "dayInMonth"),
  };
  if (!result.cutletName || !result.monthName) throw new TypeError("Li motor retornat un vacui nómine.");
  return Object.freeze(result);
}

export function cloneCanonicalResult(value) {
  const normalized = normalizeCalendarResult(value);
  return Object.freeze({ ...normalized });
}
