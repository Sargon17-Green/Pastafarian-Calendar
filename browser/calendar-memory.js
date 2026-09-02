'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));

  class NullCalendarMemory {
    getConversion() { return undefined; }
    setConversion() {}
    getCutletView() { return undefined; }
    setCutletView() {}
    clearCalculation() {}
    clear() {}
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

  ns.calendarMemory = Object.freeze({ NullCalendarMemory, assertCalendarMemory });
})(typeof globalThis === 'object' ? globalThis : this);
