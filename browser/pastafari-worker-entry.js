'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal;
  const normalizeCalendarResult = ns.resultNormalizer.normalizeCalendarResult;
  const deriveCutletViewBlackBox = ns.blackBoxCutlet.deriveCutletViewBlackBox;
  const core = root.PastafariBrowserCore;
  const workerConfig = root.PastafariBrowserWorkerConfig || {};
  const buildId = workerConfig.buildId == null || String(workerConfig.buildId) === ''
    ? null : String(workerConfig.buildId);
  const BUILD_MISMATCH_CODE = 'ERR_BROWSER_BUILD_MISMATCH';

  if (!core || typeof core.calendarDateSpaghetti !== 'function') {
    throw new Error('Li JavaScript+Interlingue core ne exporta calendarDateSpaghetti().');
  }

  function assertRequestBuildId(message) {
    if (buildId == null) return;
    const requested = message && message.buildId != null ? String(message.buildId) : null;
    if (requested === buildId) return;
    const error = new Error(
      'Li browser main-bundle e Worker ne apartene al sam build: Worker '
      + buildId + ', request ' + (requested == null || requested === '' ? '(mancant)' : requested) + '.',
    );
    error.name = 'BrowserBuildMismatchError';
    error.code = BUILD_MISMATCH_CODE;
    throw error;
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

  function responseEnvelope(payload) {
    if (buildId == null) return payload;
    return { ...payload, buildId };
  }

  root.addEventListener('message', async (event) => {
    const message = event.data || {};
    const id = Number(message.id);
    try {
      assertRequestBuildId(message);
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
      root.postMessage(responseEnvelope({ id, ok: true, value }));
    } catch (error) {
      root.postMessage(responseEnvelope({ id, ok: false, error: serializeError(error) }));
    }
  });
})(typeof globalThis === 'object' ? globalThis : self);
