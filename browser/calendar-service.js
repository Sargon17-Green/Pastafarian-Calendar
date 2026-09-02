'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const axis = ns.dateAxis;
  const memoryApi = ns.calendarMemory;
  const PastafariEngineClient = ns.engineClient && ns.engineClient.PastafariEngineClient;
  const normalizeCalendarResult = ns.resultNormalizer && ns.resultNormalizer.normalizeCalendarResult;

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

  class CalendarService {
    constructor(options) {
      const selected = options || {};
      this.engineClient = selected.engineClient || new PastafariEngineClient();
      this.memory = memoryApi.assertCalendarMemory(selected.memory || new memoryApi.NullCalendarMemory());
    }

    async convert(targetJdn, calculationJdn) {
      const targetDay = axis.jdnToProjectDay(targetJdn);
      const calculationDay = axis.jdnToProjectDay(calculationJdn);
      const remembered = await this.memory.getConversion(calculationDay, targetDay);
      if (remembered !== undefined) return normalizeCalendarResult(remembered);
      const result = normalizeCalendarResult(await this.engineClient.convert(calculationDay, targetDay));
      await this.memory.setConversion(calculationDay, targetDay, result);
      return result;
    }

    async getCutletView(targetJdn, calculationJdn) {
      const targetDay = axis.jdnToProjectDay(targetJdn);
      const calculationDay = axis.jdnToProjectDay(calculationJdn);
      const remembered = await this.memory.getCutletView(calculationDay, targetDay);
      if (remembered !== undefined) return adaptViewToJdn(remembered);
      const view = await this.engineClient.getCutletView(calculationDay, targetDay);
      await this.memory.setCutletView(calculationDay, targetDay, view);
      return adaptViewToJdn(view);
    }

    async retry(calculationJdn) {
      if (calculationJdn == null) await this.memory.clear();
      else await this.memory.clearCalculation(axis.jdnToProjectDay(calculationJdn));
      this.engineClient.retry();
    }

    dispose() {
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
