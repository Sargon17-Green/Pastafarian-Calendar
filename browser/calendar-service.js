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

      const rememberedView = await this.memory.getCutletView(calculationDay, targetDay);
      const fromView = resultFromRememberedView(rememberedView, targetDay);
      if (fromView !== undefined) {
        await this.memory.setConversion(calculationDay, targetDay, fromView);
        return fromView;
      }

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

    async getCutletView(targetJdn, calculationJdn) {
      const targetDay = axis.jdnToProjectDay(targetJdn);
      const calculationDay = axis.jdnToProjectDay(calculationJdn);
      const remembered = await this.memory.getCutletView(calculationDay, targetDay);
      if (remembered !== undefined) return adaptViewToJdn(remembered);

      const key = requestKey(calculationDay, targetDay);
      const existing = this.cutletInflight.get(key);
      if (existing) return adaptViewToJdn(await existing);

      const memoryGeneration = this.memoryGeneration;
      const request = (async () => {
        const view = await this.engineClient.getCutletView(calculationDay, targetDay);
        if (memoryGeneration === this.memoryGeneration) {
          await this.memory.setCutletView(calculationDay, targetDay, view);
          const selected = resultFromRememberedView(view, targetDay);
          if (selected !== undefined) await this.memory.setConversion(calculationDay, targetDay, selected);
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

  function getSharedCalendarService() {
    if (!sharedCalendarService) sharedCalendarService = new CalendarService();
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
  });
})(typeof globalThis === 'object' ? globalThis : this);
