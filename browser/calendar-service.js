import { jdnToProjectDay, projectDayToJdn } from "./date-axis.js";
import { NullCalendarMemory, assertCalendarMemory } from "./calendar-memory.js";
import { PastafariEngineClient } from "./engine-client.js";
import { normalizeCalendarResult } from "./result-normalizer.js";

function adaptViewToJdn(view) {
  const days = Object.freeze(view.days.map((day) => Object.freeze({
    jdn: projectDayToJdn(day.day),
    ...normalizeCalendarResult(day),
  })));
  return Object.freeze({
    selectedJdn: projectDayToJdn(view.selectedDay),
    selectedIndex: view.selectedIndex,
    startJdn: projectDayToJdn(view.startDay),
    endJdn: projectDayToJdn(view.endDay),
    previousCutletJdn: projectDayToJdn(view.previousCutletDay),
    nextCutletJdn: projectDayToJdn(view.nextCutletDay),
    year: String(view.year),
    cutletName: String(view.cutletName),
    days,
  });
}

export class CalendarService {
  constructor({ engineClient = new PastafariEngineClient(), memory = new NullCalendarMemory() } = {}) {
    this.engineClient = engineClient;
    this.memory = assertCalendarMemory(memory);
  }

  async convert(targetJdn, calculationJdn) {
    const targetDay = jdnToProjectDay(targetJdn);
    const calculationDay = jdnToProjectDay(calculationJdn);
    const remembered = await this.memory.getConversion(calculationDay, targetDay);
    if (remembered !== undefined) return normalizeCalendarResult(remembered);
    const result = normalizeCalendarResult(await this.engineClient.convert(calculationDay, targetDay));
    await this.memory.setConversion(calculationDay, targetDay, result);
    return result;
  }

  async getCutletView(targetJdn, calculationJdn) {
    const targetDay = jdnToProjectDay(targetJdn);
    const calculationDay = jdnToProjectDay(calculationJdn);
    const remembered = await this.memory.getCutletView(calculationDay, targetDay);
    if (remembered !== undefined) return adaptViewToJdn(remembered);
    const view = await this.engineClient.getCutletView(calculationDay, targetDay);
    await this.memory.setCutletView(calculationDay, targetDay, view);
    return adaptViewToJdn(view);
  }

  async retry(calculationJdn = null) {
    if (calculationJdn == null) await this.memory.clear();
    else await this.memory.clearCalculation(jdnToProjectDay(calculationJdn));
    await this.engineClient.retry();
  }

  dispose() {
    this.engineClient.dispose();
  }
}

let sharedCalendarService = null;

export function getSharedCalendarService() {
  if (!sharedCalendarService) sharedCalendarService = new CalendarService();
  return sharedCalendarService;
}

export function installSharedCalendarService(service) {
  if (!service || typeof service.convert !== "function" || typeof service.getCutletView !== "function") {
    throw new TypeError("Li shared CalendarService es ínvalid.");
  }
  if (sharedCalendarService && sharedCalendarService !== service) sharedCalendarService.dispose?.();
  sharedCalendarService = service;
  return service;
}
