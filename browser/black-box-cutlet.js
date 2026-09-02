import { normalizeCalendarResult } from "./result-normalizer.js";

export const MAX_CUTLET_DAYS = 6000;

export async function deriveCutletViewBlackBox({ calculationDay, targetDay, convert, maxCutletDays = MAX_CUTLET_DAYS }) {
  const calculation = BigInt(calculationDay);
  const target = BigInt(targetDay);
  if (typeof convert !== "function") throw new TypeError("convert deve esser un function.");
  if (!Number.isSafeInteger(maxCutletDays) || maxCutletDays < 1) throw new RangeError("maxCutletDays es ínvalid.");

  const selected = normalizeCalendarResult(await convert(calculation, target));
  const startDay = target - BigInt(selected.dayInCutlet - 1);
  const days = [];
  let boundaryFound = false;

  for (let offset = 0; offset < maxCutletDays; offset += 1) {
    const day = startDay + BigInt(offset);
    const value = day === target ? selected : normalizeCalendarResult(await convert(calculation, day));
    if (offset > 0 && value.dayInCutlet === 1) {
      boundaryFound = true;
      break;
    }
    const expected = offset + 1;
    if (value.dayInCutlet !== expected) {
      throw new Error(`Ínvalid cutlet continuity at day ${day}: expectat ${expected}, recivet ${value.dayInCutlet}.`);
    }
    if (days.length > 0 && (value.year !== days[0].year || value.cutletName !== days[0].cutletName)) {
      throw new Error(`Li motor changeat cutlet identity ante li proxim limite at day ${day}.`);
    }
    days.push(Object.freeze({ day, ...value }));
  }

  if (days.length === 0) throw new Error("Li cutlet derivation retornat null dies.");
  if (!boundaryFound) throw new Error(`Li cutlet excedet li securitá-limite de ${maxCutletDays} dies.`);

  const endDay = startDay + BigInt(days.length - 1);
  const selectedIndexBig = target - startDay;
  if (selectedIndexBig < 0n || selectedIndexBig >= BigInt(days.length)) throw new Error("Li selectet die ne es intra li derivat cutlet.");

  return Object.freeze({
    selectedDay: target,
    selectedIndex: Number(selectedIndexBig),
    startDay,
    endDay,
    previousCutletDay: startDay - 1n,
    nextCutletDay: endDay + 1n,
    year: days[0].year,
    cutletName: days[0].cutletName,
    days: Object.freeze(days),
  });
}
