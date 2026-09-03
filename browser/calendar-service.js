'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const axis = ns.dateAxis;
  const memoryApi = ns.calendarMemory;
  const PastafariEngineClient = ns.engineClient && ns.engineClient.PastafariEngineClient;
  const normalizeCalendarResult = ns.resultNormalizer && ns.resultNormalizer.normalizeCalendarResult;

  function requestKey(calculationDay, targetDay) {
    return String(BigInt(calculationDay)) + ':' + String(BigInt(targetDay));
  }

  function sameCanonicalResult(aValue, bValue) {
    const a = normalizeCalendarResult(aValue);
    const b = normalizeCalendarResult(bValue);
    return a.year === b.year &&
      a.cutletName === b.cutletName &&
      a.dayInCutlet === b.dayInCutlet &&
      a.monthName === b.monthName &&
      a.dayInMonth === b.dayInMonth;
  }

  function consistencyError(directValue, viewValue) {
    const direct = normalizeCalendarResult(directValue);
    const fromView = normalizeCalendarResult(viewValue);
    const error = new Error(
      'Li direct conversion e li cutlet-view diverge por li sam calculation-day e target-day.'
    );
    error.name = 'CalendarConsistencyError';
    error.code = 'ERR_CALENDAR_INCONSISTENCY';
    error.directResult = direct;
    error.viewResult = fromView;
    return error;
  }

  function adaptViewToJdn(view) {
    const days = Object.freeze(view.days.map((day) => Object.freeze({
      jdn: axis.projectDayToJdn(day.day),
      ...normalizeCalendarResult(day),
    })));
    return Object.freeze({
      selectedJdn: axis.projectDayToJdn(view.selectedDay),
      selectedIndex: Number(view.selectedIndex),
      startJdn: axis.projectDayToJdn(view.startDay),
      endJdn: axis.projectDayToJdn(view.endDay),
      previousCutletJdn: axis.projectDayToJdn(view.previousCutletDay),
      nextCutletJdn: axis.projectDayToJdn(view.nextCutletDay),
      year: String(view.year),
      cutletName: String(view.cutletName),
      days,
    });
  }

  function resultFromRememberedView(view, targetDay) {
    if (!view || typeof view !== 'object' || !Array.isArray(view.days)) return undefined;
    const indexBig = BigInt(targetDay) - BigInt(view.startDay);
    if (indexBig < 0n || indexBig > BigInt(Number.MAX_SAFE_INTEGER)) return undefined;
    const index = Number(indexBig);
    const day = view.days[index];
    if (!day || BigInt(day.day) !== BigInt(targetDay)) return undefined;
    return normalizeCalendarResult(day);
  }

  class CalendarService {
    constructor(options) {
      const selected = options || {};
      this.engineClient = selected.engineClient || new PastafariEngineClient();
      this.memory = memoryApi.assertCalendarMemory(
        selected.memory || new memoryApi.BoundedCalendarMemory(),
      );
      this.conversionInflight = new Map();
      this.cutletInflight = new Map();
      this.memoryGeneration = 0;
    }

    async convert(targetJdn, calculationJdn) {
      const targetDay = axis.jdnToProjectDay(targetJdn);
      const calculationDay = axis.jdnToProjectDay(calculationJdn);
      const remembered = await this.memory.getConversion(calculationDay, targetDay);
      if (remembered !== undefined) return normalizeCalendarResult(remembered);

      /*
       * A cutlet-view is deliberately NOT an authority for convert().
       * A prior implementation promoted a view-derived value into the direct conversion
       * cache. If the two black-box calculations disagreed, that poisoned later loads.
       */
      const key = requestKey(calculationDay, targetDay);
      const existing = this.conversionInflight.get(key);
      if (existing) return existing;

      const memoryGeneration = this.memoryGeneration;
      const request = (async () => {
        const result = normalizeCalendarResult(await this.engineClient.convert(calculationDay, targetDay));
        if (memoryGeneration === this.memoryGeneration) {
          await this.memory.setConversion(calculationDay, targetDay, result);
        }
        return result;
      })();
      this.conversionInflight.set(key, request);
      try {
        return await request;
      } finally {
        if (this.conversionInflight.get(key) === request) this.conversionInflight.delete(key);
      }
    }

    async _invalidateCalculation(calculationDay) {
      this.memoryGeneration += 1;
      await this.memory.clearCalculation(calculationDay);
      this.conversionInflight.clear();
      this.cutletInflight.clear();
    }

    async getCutletView(targetJdn, calculationJdn) {
      const targetDay = axis.jdnToProjectDay(targetJdn);
      const calculationDay = axis.jdnToProjectDay(calculationJdn);

      // The direct five-field conversion is the authority for this exact target.
      // Concurrent callers coalesce through convert(), so this does not duplicate a direct request.
      const direct = await this.convert(targetJdn, calculationJdn);

      const remembered = await this.memory.getCutletView(calculationDay, targetDay);
      if (remembered !== undefined) {
        const selected = resultFromRememberedView(remembered, targetDay);
        if (selected !== undefined && sameCanonicalResult(direct, selected)) {
          return adaptViewToJdn(remembered);
        }
        // A stale/corrupt persistent view is discarded, but the already verified direct
        // result is preserved and the view is rebuilt below.
        await this._invalidateCalculation(calculationDay);
        await this.memory.setConversion(calculationDay, targetDay, direct);
      }

      const key = requestKey(calculationDay, targetDay);
      const existing = this.cutletInflight.get(key);
      if (existing) return adaptViewToJdn(await existing);

      const requestGeneration = this.memoryGeneration;
      const request = (async () => {
        let generation = requestGeneration;
        let view = await this.engineClient.getCutletView(calculationDay, targetDay);
        let selected = resultFromRememberedView(view, targetDay);

        if (generation === this.memoryGeneration &&
            (selected === undefined || !sameCanonicalResult(direct, selected))) {
          // The direct result already won the arbitration. A divergent view is never
          // displayed or cached. Recreate the single Worker once, then repeat the whole
          // cutlet derivation from a clean black-box core instance.
          await this._invalidateCalculation(calculationDay);
          this.engineClient.retry();
          generation = this.memoryGeneration;
          await this.memory.setConversion(calculationDay, targetDay, direct);

          view = await this.engineClient.getCutletView(calculationDay, targetDay);
          selected = resultFromRememberedView(view, targetDay);
          if (selected === undefined || !sameCanonicalResult(direct, selected)) {
            await this._invalidateCalculation(calculationDay);
            this.engineClient.retry();
            throw consistencyError(direct, selected || direct);
          }
        }

        if (generation === this.memoryGeneration) {
          await this.memory.setConversion(calculationDay, targetDay, direct);
          await this.memory.setCutletView(calculationDay, targetDay, view);
          // Never overwrite a direct conversion with a value derived from a cutlet scan.
        }
        return view;
      })();
      this.cutletInflight.set(key, request);
      try {
        return adaptViewToJdn(await request);
      } finally {
        if (this.cutletInflight.get(key) === request) this.cutletInflight.delete(key);
      }
    }

    async retry(calculationJdn) {
      this.memoryGeneration += 1;
      if (calculationJdn == null) await this.memory.clear();
      else await this.memory.clearCalculation(axis.jdnToProjectDay(calculationJdn));
      this.conversionInflight.clear();
      this.cutletInflight.clear();
      this.engineClient.retry();
    }

    dispose() {
      this.memoryGeneration += 1;
      this.conversionInflight.clear();
      this.cutletInflight.clear();
      this.engineClient.dispose();
    }
  }

  let sharedCalendarService = null;

  function persistentDefaultMemory() {
    const config = root.PastafariBrowserConfig || {};
    if (memoryApi && typeof memoryApi.PersistentCalendarMemory === 'function') {
      return new memoryApi.PersistentCalendarMemory({ namespace: config.cacheNamespace });
    }
    return new memoryApi.BoundedCalendarMemory();
  }

  function getSharedCalendarService() {
    if (!sharedCalendarService) {
      sharedCalendarService = new CalendarService({ memory: persistentDefaultMemory() });
    }
    return sharedCalendarService;
  }

  function installSharedCalendarService(service) {
    if (!service || typeof service.convert !== 'function' || typeof service.getCutletView !== 'function') {
      throw new TypeError('Li shared CalendarService es ínvalid.');
    }
    if (sharedCalendarService && sharedCalendarService !== service && typeof sharedCalendarService.dispose === 'function') {
      sharedCalendarService.dispose();
    }
    sharedCalendarService = service;
    return service;
  }

  function installSharedCalendarMemory(memory) {
    const validated = memoryApi.assertCalendarMemory(memory);
    const oldService = sharedCalendarService;
    sharedCalendarService = new CalendarService({ memory: validated });
    if (oldService && typeof oldService.dispose === 'function') oldService.dispose();
    return sharedCalendarService;
  }

  ns.calendarService = Object.freeze({
    CalendarService,
    getSharedCalendarService,
    installSharedCalendarService,
    installSharedCalendarMemory,
    sameCanonicalResult,
  });
})(typeof globalThis === 'object' ? globalThis : this);
