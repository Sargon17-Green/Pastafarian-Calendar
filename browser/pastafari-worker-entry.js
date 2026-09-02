import core from "../src/index.js";
import { deriveCutletViewBlackBox } from "./black-box-cutlet.js";
import { normalizeCalendarResult } from "./result-normalizer.js";

if (!core || typeof core.calendarDateSpaghetti !== "function") {
  throw new Error("Li JavaScript+Interlingue core ne exporta calendarDateSpaghetti().");
}

async function convert(calculationDay, targetDay) {
  return normalizeCalendarResult(core.calendarDateSpaghetti(BigInt(calculationDay), BigInt(targetDay)));
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
    days: view.days.map((day) => ({ day: String(day.day), ...normalizeCalendarResult(day) })),
  };
}

function serializeError(error) {
  return {
    name: error?.name || "Error",
    message: error?.message || String(error),
    code: error?.code || null,
  };
}

self.addEventListener("message", async (event) => {
  const message = event.data || {};
  const id = Number(message.id);
  try {
    const calculationDay = BigInt(message.calculationDay);
    const targetDay = BigInt(message.targetDay);
    let value;
    if (message.operation === "convert") {
      value = await convert(calculationDay, targetDay);
    } else if (message.operation === "getCutletView") {
      value = serializeView(await deriveCutletViewBlackBox({ calculationDay, targetDay, convert }));
    } else {
      throw new Error(`Ínconosset worker-operation: ${message.operation}`);
    }
    self.postMessage({ id, ok: true, value });
  } catch (error) {
    self.postMessage({ id, ok: false, error: serializeError(error) });
  }
});
