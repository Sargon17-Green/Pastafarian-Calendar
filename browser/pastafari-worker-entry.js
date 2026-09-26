'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal;
  const normalizeCalendarResult = ns.resultNormalizer.normalizeCalendarResult;
  const deriveCutletViewBlackBox = ns.blackBoxCutlet.deriveCutletViewBlackBox;
  const core = root.PastafariBrowserCore;
  const cookingTraceApi = root.PastafariBrowserCookingTrace;
  const workerConfig = root.PastafariBrowserWorkerConfig || {};
  const buildId = workerConfig.buildId == null || String(workerConfig.buildId) === ''
    ? null : String(workerConfig.buildId);
  const BUILD_MISMATCH_CODE = 'ERR_BROWSER_BUILD_MISMATCH';

  if (!core || typeof core.calendarDateSpaghetti !== 'function') {
    throw new Error('Li JavaScript+Interlingue core ne exporta calendarDateSpaghetti().');
  }
  if (!cookingTraceApi || typeof cookingTraceApi.calendarDateSpaghettiCookingTrace !== 'function') {
    throw new Error('Li JavaScript+Interlingue Worker ne have li normative cooking-trace API.');
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

  function parseGateDetailGateIndices(message) {
    if (message.gateDetailGateIndices === undefined || message.gateDetailGateIndices === null) return null;
    if (!Array.isArray(message.gateDetailGateIndices)) {
      throw new TypeError('gateDetailGateIndices del Worker deve esser null o un array.');
    }
    return message.gateDetailGateIndices.map((value) => {
      const index = BigInt(value);
      if (index === 0n) throw new RangeError('Un gate-detail index ne posse esser zero.');
      return index;
    });
  }

  function cookingTraceForRequest(calculationDay, targetDay, message, id) {
    const streamGateSauceDetail = message.streamGateSauceDetail === true;
    const streamProgress = message.streamProgress === true;
    const gateDetailGateIndices = parseGateDetailGateIndices(message);
    if (!streamGateSauceDetail && gateDetailGateIndices !== null) {
      throw new TypeError('gateDetailGateIndices exige streamGateSauceDetail=true.');
    }
    let options = null;
    if (streamGateSauceDetail || streamProgress) {
      options = {};
      if (streamGateSauceDetail) {
        options.onGateSauceDetail = (detail) => {
          root.postMessage(responseEnvelope({
            id,
            ok: true,
            kind: 'gate-detail',
            value: detail,
          }));
        };
        if (gateDetailGateIndices !== null) options.gateDetailGateIndices = gateDetailGateIndices;
      }
      if (streamProgress) {
        options.onProgress = (progress) => {
          root.postMessage(responseEnvelope({
            id,
            ok: true,
            kind: 'progress',
            value: progress,
          }));
        };
      }
    }
    return cookingTraceApi.calendarDateSpaghettiCookingTrace(calculationDay, targetDay, options);
  }

  function resultFromCookingTrace(trace) {
    if (!trace || !trace.finalResult) throw new TypeError('Li cooking trace ne contene un resultate final.');
    return normalizeCalendarResult({
      year: trace.finalResult.year,
      cutletName: trace.finalResult.cutlet && trace.finalResult.cutlet.sourceName,
      dayInCutlet: trace.finalResult.dayInCutlet,
      monthName: trace.finalResult.month && trace.finalResult.month.sourceName,
      dayInMonth: trace.finalResult.dayInMonth,
    });
  }

  function convertWithTraceForRequest(calculationDay, targetDay, message, id) {
    const trace = cookingTraceForRequest(calculationDay, targetDay, message, id);
    return { result: resultFromCookingTrace(trace), trace };
  }

  async function cutletViewForRequest(calculationDay, targetDay, message, id) {
    if (message.streamProgress !== true) {
      return serializeView(await deriveCutletViewBlackBox({ calculationDay, targetDay, convert }));
    }
    const startedAt = Date.now();
    let previousAt = startedAt;
    let ordinal = 0;
    const progressConvert = async (cDay, tDay) => {
      const value = await convert(cDay, tDay);
      const now = Date.now();
      root.postMessage(responseEnvelope({
        id,
        ok: true,
        kind: 'progress',
        value: {
          kind: 'view-day-ready',
          elapsedMs: Math.max(0, now - startedAt),
          durationMs: Math.max(0, now - previousAt),
          payload: { ordinal: ++ordinal, targetDay: String(tDay) },
        },
      }));
      previousAt = now;
      return value;
    };
    return serializeView(await deriveCutletViewBlackBox({
      calculationDay,
      targetDay,
      convert: progressConvert,
    }));
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
      let responseKind = null;
      if (message.operation === 'convert') {
        value = await convert(calculationDay, targetDay);
      } else if (message.operation === 'convertWithTrace') {
        value = convertWithTraceForRequest(calculationDay, targetDay, message, id);
        responseKind = 'result';
      } else if (message.operation === 'getCutletView') {
        value = await cutletViewForRequest(calculationDay, targetDay, message, id);
      } else if (message.operation === 'cookingTrace') {
        value = cookingTraceForRequest(calculationDay, targetDay, message, id);
        responseKind = 'result';
      } else {
        throw new Error('Ínconosset worker-operation: ' + String(message.operation));
      }
      const response = { id, ok: true, value };
      if (responseKind !== null) response.kind = responseKind;
      root.postMessage(responseEnvelope(response));
    } catch (error) {
      root.postMessage(responseEnvelope({ id, ok: false, error: serializeError(error) }));
    }
  });
})(typeof globalThis === 'object' ? globalThis : self);
