'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const normalizeCalendarResult = ns.resultNormalizer && ns.resultNormalizer.normalizeCalendarResult;
  const DEFAULT_MAX_CONVERSIONS = 2048;
  const DEFAULT_MAX_CUTLETS = 8;
  const DEFAULT_MAX_PERSISTED_CONVERSIONS = 512;
  const DEFAULT_MAX_PERSISTED_CUTLETS = 4;
  const PERSISTENT_SCHEMA_VERSION = 2;
  const PERSISTENT_KEY_PREFIX = 'pastafari-calendar-cache:';

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
      this.maxConversions = positiveSafeInteger(selected.maxConversions, DEFAULT_MAX_CONVERSIONS, 'maxConversions');
      this.maxCutlets = positiveSafeInteger(selected.maxCutlets, DEFAULT_MAX_CUTLETS, 'maxCutlets');
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

  function safeStorage() {
    try {
      return root && root.localStorage ? root.localStorage : null;
    } catch (_) {
      return null;
    }
  }

  function freezeView(view) {
    const days = Object.freeze(view.days.map((day) => Object.freeze({
      day: BigInt(day.day),
      ...(normalizeCalendarResult ? normalizeCalendarResult(day) : {
        year: String(day.year),
        cutletName: String(day.cutletName),
        dayInCutlet: Number(day.dayInCutlet),
        monthName: String(day.monthName),
        dayInMonth: Number(day.dayInMonth),
      }),
    })));
    const startDay = BigInt(view.startDay);
    const endDay = BigInt(view.endDay);
    if (endDay < startDay || days.length !== Number(endDay - startDay + 1n)) {
      throw new RangeError('Li persistent cutlet-view ne es contigui.');
    }
    return Object.freeze({
      selectedDay: BigInt(view.selectedDay),
      selectedIndex: Number(view.selectedIndex),
      startDay,
      endDay,
      previousCutletDay: BigInt(view.previousCutletDay),
      nextCutletDay: BigInt(view.nextCutletDay),
      year: String(view.year),
      cutletName: String(view.cutletName),
      days,
    });
  }

  function encodeView(view) {
    return [
      String(BigInt(view.selectedDay)),
      Number(view.selectedIndex),
      String(BigInt(view.startDay)),
      String(BigInt(view.endDay)),
      String(BigInt(view.previousCutletDay)),
      String(BigInt(view.nextCutletDay)),
      String(view.year),
      String(view.cutletName),
      view.days.map((day) => [
        String(BigInt(day.day)),
        String(day.year),
        String(day.cutletName),
        Number(day.dayInCutlet),
        String(day.monthName),
        Number(day.dayInMonth),
      ]),
    ];
  }

  function decodeView(payload) {
    if (!Array.isArray(payload) || payload.length !== 9 || !Array.isArray(payload[8])) {
      throw new TypeError('Li persistent cutlet-view payload es ínvalid.');
    }
    return freezeView({
      selectedDay: BigInt(payload[0]),
      selectedIndex: Number(payload[1]),
      startDay: BigInt(payload[2]),
      endDay: BigInt(payload[3]),
      previousCutletDay: BigInt(payload[4]),
      nextCutletDay: BigInt(payload[5]),
      year: String(payload[6]),
      cutletName: String(payload[7]),
      days: payload[8].map((row) => {
        if (!Array.isArray(row) || row.length !== 6) throw new TypeError('Li persistent day-row es ínvalid.');
        return {
          day: BigInt(row[0]),
          year: String(row[1]),
          cutletName: String(row[2]),
          dayInCutlet: Number(row[3]),
          monthName: String(row[4]),
          dayInMonth: Number(row[5]),
        };
      }),
    });
  }

  function freshPersistentStore() {
    return { schemaVersion: PERSISTENT_SCHEMA_VERSION, conversions: [], cutlets: [] };
  }

  class PersistentCalendarMemory {
    constructor(options) {
      const selected = options || {};
      this.hot = new BoundedCalendarMemory(selected);
      this.maxPersistedConversions = positiveSafeInteger(
        selected.maxPersistedConversions,
        DEFAULT_MAX_PERSISTED_CONVERSIONS,
        'maxPersistedConversions',
      );
      this.maxPersistedCutlets = positiveSafeInteger(
        selected.maxPersistedCutlets,
        DEFAULT_MAX_PERSISTED_CUTLETS,
        'maxPersistedCutlets',
      );
      const configuredNamespace = selected.namespace || (root.PastafariBrowserConfig && root.PastafariBrowserConfig.cacheNamespace);
      this.namespace = String(configuredNamespace || 'unversioned');
      this.storage = selected.storage === undefined ? safeStorage() : selected.storage;
      this.storageKey = PERSISTENT_KEY_PREFIX + this.namespace + ':schema-' + PERSISTENT_SCHEMA_VERSION;
      this.store = freshPersistentStore();
      this._load();
      this._removeOldNamespaces();
    }

    _load() {
      if (!this.storage) return;
      try {
        const raw = this.storage.getItem(this.storageKey);
        if (!raw) return;
        const parsed = JSON.parse(raw);
        if (!parsed || parsed.schemaVersion !== PERSISTENT_SCHEMA_VERSION ||
            !Array.isArray(parsed.conversions) || !Array.isArray(parsed.cutlets)) return;
        this.store = parsed;
      } catch (_) {
        this.store = freshPersistentStore();
      }
    }

    _removeOldNamespaces() {
      if (!this.storage || typeof this.storage.length !== 'number' || typeof this.storage.key !== 'function') return;
      try {
        const stale = [];
        for (let index = 0; index < this.storage.length; index += 1) {
          const key = this.storage.key(index);
          if (typeof key === 'string' &&
              key.startsWith(PERSISTENT_KEY_PREFIX + 'pc-browser-core-') &&
              key !== this.storageKey) stale.push(key);
        }
        for (const key of stale) this.storage.removeItem(key);
      } catch (_) {}
    }

    _touchList(list, key, value) {
      const existing = list.findIndex((entry) => entry && entry.key === key);
      if (existing >= 0) list.splice(existing, 1);
      list.push({ key, value });
    }

    _trim() {
      while (this.store.conversions.length > this.maxPersistedConversions) this.store.conversions.shift();
      while (this.store.cutlets.length > this.maxPersistedCutlets) this.store.cutlets.shift();
    }

    _save() {
      if (!this.storage) return;
      this._trim();
      let attempts = this.store.cutlets.length + this.store.conversions.length + 1;
      while (attempts > 0) {
        attempts -= 1;
        try {
          this.storage.setItem(this.storageKey, JSON.stringify(this.store));
          return;
        } catch (_) {
          if (this.store.cutlets.length > 1) this.store.cutlets.shift();
          else if (this.store.conversions.length > 1) this.store.conversions.shift();
          else {
            this.storage = null;
            return;
          }
        }
      }
    }

    getConversion(calculationDay, targetDay) {
      const hot = this.hot.getConversion(calculationDay, targetDay);
      if (hot !== undefined) return hot;
      const key = pairKey(calculationDay, targetDay);
      const index = this.store.conversions.findIndex((entry) => entry && entry.key === key);
      if (index < 0) return undefined;
      try {
        const raw = this.store.conversions[index].value;
        const value = normalizeCalendarResult ? normalizeCalendarResult(raw) : Object.freeze({ ...raw });
        const entry = this.store.conversions.splice(index, 1)[0];
        this.store.conversions.push(entry);
        this.hot.setConversion(calculationDay, targetDay, value);
        this._save();
        return value;
      } catch (_) {
        this.store.conversions.splice(index, 1);
        this._save();
        return undefined;
      }
    }

    setConversion(calculationDay, targetDay, value) {
      const normalized = normalizeCalendarResult ? normalizeCalendarResult(value) : Object.freeze({ ...value });
      this.hot.setConversion(calculationDay, targetDay, normalized);
      this._touchList(this.store.conversions, pairKey(calculationDay, targetDay), normalized);
      this._save();
    }

    getCutletView(calculationDay, targetDay) {
      const hot = this.hot.getCutletView(calculationDay, targetDay);
      if (hot !== undefined) return hot;
      const key = pairKey(calculationDay, targetDay);
      const index = this.store.cutlets.findIndex((entry) => entry && entry.key === key);
      if (index < 0) return undefined;
      try {
        const view = decodeView(this.store.cutlets[index].value);
        const target = BigInt(targetDay);
        if (target < view.startDay || target > view.endDay) throw new RangeError('Li persistent cutlet ne contene su target-key.');
        const entry = this.store.cutlets.splice(index, 1)[0];
        this.store.cutlets.push(entry);
        this.hot.setCutletView(calculationDay, targetDay, view);
        this._save();
        return this.hot.getCutletView(calculationDay, targetDay);
      } catch (_) {
        this.store.cutlets.splice(index, 1);
        this._save();
        return undefined;
      }
    }

    setCutletView(calculationDay, targetDay, view) {
      const frozen = freezeView(view);
      this.hot.setCutletView(calculationDay, targetDay, frozen);
      this._touchList(this.store.cutlets, pairKey(calculationDay, targetDay), encodeView(frozen));
      this._save();
    }

    clearCalculation(calculationDayValue) {
      const calculationDay = BigInt(calculationDayValue);
      const prefix = String(calculationDay) + ':';
      this.hot.clearCalculation(calculationDay);
      this.store.conversions = this.store.conversions.filter((entry) => !entry.key.startsWith(prefix));
      this.store.cutlets = this.store.cutlets.filter((entry) => !entry.key.startsWith(prefix));
      this._save();
    }

    clear() {
      this.hot.clear();
      this.store = freshPersistentStore();
      if (this.storage) {
        try { this.storage.removeItem(this.storageKey); } catch (_) {}
      }
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
    PersistentCalendarMemory,
    DEFAULT_MAX_CONVERSIONS,
    DEFAULT_MAX_CUTLETS,
    DEFAULT_MAX_PERSISTED_CONVERSIONS,
    DEFAULT_MAX_PERSISTED_CUTLETS,
    PERSISTENT_SCHEMA_VERSION,
    assertCalendarMemory,
  });
})(typeof globalThis === 'object' ? globalThis : this);
