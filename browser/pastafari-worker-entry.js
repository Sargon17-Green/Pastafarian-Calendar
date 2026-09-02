'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal;
  const normalizeCalendarResult = ns.resultNormalizer.normalizeCalendarResult;
  const deriveCutletViewBlackBox = ns.blackBoxCutlet.deriveCutletViewBlackBox;
  const core = root.PastafariBrowserCore;

  if (!core || typeof core.calendarDateSpaghetti !== 'function') {
    throw new Error('Li JavaScript+Interlingue core ne exporta calendarDateSpaghetti().');
  }

  async function convert(calculationDay, targetDay) {
    return normalizeCalendarResult(core.calendarDateSpaghetti(
      BigInt(calculationDay),
      BigInt(targetDay),
    ));
  }

  function serializeView(view) {
    return {
      selectedDay: String(view.selectedDay),
      selectedIndex: view.selectedIndex,
      startDay: String(view.startDay),
      endDay: String(view.endDay),
      previousCutletDay: String(view.previousCutletDay),
      nextCutletDay: String(view.nextCutletDay),
      year: view.year,
      cutletName: view.cutletName,
      days: view.days.map((day) => ({
        day: String(day.day),
        ...normalizeCalendarResult(day),
      })),
    };
  }

  function serializeError(error) {
    return {
      name: error && error.name ? String(error.name) : 'Error',
      message: error && error.message ? String(error.message) : String(error),
      code: error && error.code ? String(error.code) : null,
    };
  }

  root.addEventListener('message', async (event) => {
    const message = event.data || {};
    const id = Number(message.id);
    try {
      const calculationDay = BigInt(message.calculationDay);
      const targetDay = BigInt(message.targetDay);
      let value;
      if (message.operation === 'convert') {
        value = await convert(calculationDay, targetDay);
      } else if (message.operation === 'getCutletView') {
        value = serializeView(await deriveCutletViewBlackBox({
          calculationDay,
          targetDay,
          convert,
        }));
      } else {
        throw new Error('Ínconosset worker-operation: ' + String(message.operation));
      }
      root.postMessage({ id, ok: true, value });
    } catch (error) {
      root.postMessage({ id, ok: false, error: serializeError(error) });
    }
  });
})(typeof globalThis === 'object' ? globalThis : self);
