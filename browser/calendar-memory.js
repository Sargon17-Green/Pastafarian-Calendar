/**
 * Punctu de extension por futur strates de memorisat computation.
 * Un retorn de undefined significa un manca in li cache. Li predefinit implementation conserva necos.
 */
export class NullCalendarMemory {
  async getConversion(_calculationDay, _targetDay) { return undefined; }
  async setConversion(_calculationDay, _targetDay, _value) {}
  async getCutletView(_calculationDay, _targetDay) { return undefined; }
  async setCutletView(_calculationDay, _targetDay, _value) {}
  async clearCalculation(_calculationDay) {}
  async clear() {}
}

export function assertCalendarMemory(memory) {
  if (!memory || typeof memory !== "object") throw new TypeError("CalendarMemory deve esser un object.");
  for (const name of ["getConversion", "setConversion", "getCutletView", "setCutletView", "clearCalculation", "clear"]) {
    if (typeof memory[name] !== "function") throw new TypeError(`CalendarMemory manca ${name}().`);
  }
  return memory;
}
