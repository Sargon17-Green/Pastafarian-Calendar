'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const DEFAULT_MAX_CONVERSIONS = 2048;
  const DEFAULT_MAX_CUTLETS = 8;

  class NullCalendarMemory {
    getConversion() { return undefined; }
    setConversion() {}
    getCutletView() { return undefined; }
    setCutletView() {}
    clearCalculation() {}
    clear() {}
  }

  function positiveSafeInteger(value, fallback, field) {
    const selected = value == null ? fallback : Number(value);
    if (!Number.isSafeInteger(selected) || selected < 1) {
      throw new RangeError(field + ' deve esser un positiv secur integer.');
    }
    return selected;
  }

  function pairKey(calculationDay, targetDay) {
    return String(BigInt(calculationDay)) + ':' + String(BigInt(targetDay));
  }

  function cutletKey(calculationDay, startDay) {
    return String(BigInt(calculationDay)) + ':' + String(BigInt(startDay));
  }

  function touch(map, key, value) {
    map.delete(key);
    map.set(key, value);
  }

  function trimOldest(map, maximum) {
    while (map.size > maximum) {
      const oldest = map.keys().next();
      if (oldest.done) break;
      map.delete(oldest.value);
    }
  }

  function retargetCutlet(entry, targetDayValue) {
    const targetDay = BigInt(targetDayValue);
    const selectedIndexBig = targetDay - entry.startDay;
    if (selectedIndexBig < 0n || targetDay > entry.endDay) return undefined;
    const selectedIndex = Number(selectedIndexBig);
    if (!Number.isSafeInteger(selectedIndex) || selectedIndex < 0 || selectedIndex >= entry.view.days.length) {
      return undefined;
    }
    const selected = entry.view.days[selectedIndex];
    if (!selected || BigInt(selected.day) !== targetDay) return undefined;
    return Object.freeze({
      selectedDay: targetDay,
      selectedIndex,
      startDay: entry.view.startDay,
      endDay: entry.view.endDay,
      previousCutletDay: entry.view.previousCutletDay,
      nextCutletDay: entry.view.nextCutletDay,
      year: entry.view.year,
      cutletName: entry.view.cutletName,
      days: entry.view.days,
    });
  }

  class BoundedCalendarMemory {
    constructor(options) {
      const selected = options || {};
      this.maxConversions = positiveSafeInteger(
        selected.maxConversions,
        DEFAULT_MAX_CONVERSIONS,
        'maxConversions',
      );
      this.maxCutlets = positiveSafeInteger(
        selected.maxCutlets,
        DEFAULT_MAX_CUTLETS,
        'maxCutlets',
      );
      this.conversions = new Map();
      this.cutlets = new Map();
    }

    getConversion(calculationDay, targetDay) {
      const key = pairKey(calculationDay, targetDay);
      const value = this.conversions.get(key);
      if (value === undefined) return undefined;
      touch(this.conversions, key, value);
      return value;
    }

    setConversion(calculationDay, targetDay, value) {
      const key = pairKey(calculationDay, targetDay);
      touch(this.conversions, key, value);
      trimOldest(this.conversions, this.maxConversions);
    }

    getCutletView(calculationDayValue, targetDayValue) {
      const calculationDay = BigInt(calculationDayValue);
      const targetDay = BigInt(targetDayValue);
      for (const [key, entry] of this.cutlets) {
        if (entry.calculationDay !== calculationDay) continue;
        if (targetDay < entry.startDay || targetDay > entry.endDay) continue;
        const retargeted = retargetCutlet(entry, targetDay);
        if (retargeted === undefined) continue;
        touch(this.cutlets, key, entry);
        return retargeted;
      }
      return undefined;
    }

    setCutletView(calculationDayValue, _targetDayValue, view) {
      if (!view || typeof view !== 'object' || !Array.isArray(view.days)) {
        throw new TypeError('Li cutlet-view por CalendarMemory es ínvalid.');
      }
      const calculationDay = BigInt(calculationDayValue);
      const startDay = BigInt(view.startDay);
      const endDay = BigInt(view.endDay);
      if (endDay < startDay || view.days.length !== Number(endDay - startDay + 1n)) {
        throw new RangeError('Li cutlet-view por CalendarMemory ne es contigui.');
      }
      const key = cutletKey(calculationDay, startDay);
      const entry = Object.freeze({ calculationDay, startDay, endDay, view });
      touch(this.cutlets, key, entry);
      trimOldest(this.cutlets, this.maxCutlets);
    }

    clearCalculation(calculationDayValue) {
      const calculationDay = BigInt(calculationDayValue);
      const prefix = String(calculationDay) + ':';
      for (const key of Array.from(this.conversions.keys())) {
        if (key.startsWith(prefix)) this.conversions.delete(key);
      }
      for (const [key, entry] of Array.from(this.cutlets.entries())) {
        if (entry.calculationDay === calculationDay) this.cutlets.delete(key);
      }
    }

    clear() {
      this.conversions.clear();
      this.cutlets.clear();
    }
  }

  function assertCalendarMemory(memory) {
    const required = [
      'getConversion', 'setConversion',
      'getCutletView', 'setCutletView',
      'clearCalculation', 'clear',
    ];
    if (!memory || required.some((name) => typeof memory[name] !== 'function')) {
      throw new TypeError('Li CalendarMemory contract es ínvalid.');
    }
    return memory;
  }

  ns.calendarMemory = Object.freeze({
    NullCalendarMemory,
    BoundedCalendarMemory,
    DEFAULT_MAX_CONVERSIONS,
    DEFAULT_MAX_CUTLETS,
    assertCalendarMemory,
  });
})(typeof globalThis === 'object' ? globalThis : this);
