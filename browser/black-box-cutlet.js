'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const normalizeCalendarResult = ns.resultNormalizer && ns.resultNormalizer.normalizeCalendarResult;
  const MAX_CUTLET_DAYS = 6000;

  async function deriveCutletViewBlackBox(options) {
    if (!normalizeCalendarResult) throw new Error('Li result-normalizer deve esser cargat ante li black-box cutlet builder.');
    const calculationDay = BigInt(options.calculationDay);
    const targetDay = BigInt(options.targetDay);
    const convert = options.convert;
    if (typeof convert !== 'function') throw new TypeError('Li black-box converter manca.');
    const selected = normalizeCalendarResult(await convert(calculationDay, targetDay));
    const startDay = targetDay - BigInt(selected.dayInCutlet - 1);
    const days = [];
    let boundaryFound = false;

    for (let offset = 0; offset < MAX_CUTLET_DAYS; offset += 1) {
      const day = startDay + BigInt(offset);
      const value = day === targetDay ? selected : normalizeCalendarResult(await convert(calculationDay, day));
      if (offset > 0 && value.dayInCutlet === 1) {
        boundaryFound = true;
        break;
      }
      if (value.dayInCutlet !== offset + 1) {
        throw new Error('Li black-box cutlet scan trovat un non-contigui dayInCutlet.');
      }
      days.push(Object.freeze({ day, ...value }));
    }

    if (!boundaryFound) throw new Error('Li black-box cutlet scan ne trovat li sequent limite ante 6000 dies.');
    const endDay = startDay + BigInt(days.length - 1);
    return Object.freeze({
      selectedDay: targetDay,
      selectedIndex: Number(targetDay - startDay),
      startDay,
      endDay,
      previousCutletDay: startDay - 1n,
      nextCutletDay: endDay + 1n,
      year: selected.year,
      cutletName: selected.cutletName,
      days: Object.freeze(days),
    });
  }

  ns.blackBoxCutlet = Object.freeze({ MAX_CUTLET_DAYS, deriveCutletViewBlackBox });
})(typeof globalThis === 'object' ? globalThis : this);
