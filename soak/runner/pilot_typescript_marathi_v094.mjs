#!/usr/bin/env node
// v094: READ-ONLY adapter. Native Date is calculated exclusively by pinned
// TypeScript+Marathi src/postStage55FinalDate.ts, never by this adapter.
// Linux CI bounded to exactly two targets; not a Windows or full-year engine.
import { createHash } from "node:crypto";
import { openSync, writeSync, fsyncSync, closeSync, realpathSync } from "node:fs";
import { resolve, join } from "node:path";
import { pathToFileURL } from "node:url";

const C = "-15055671";
const TARGETS = ["-15055660", "-15055659"];
const ENTRY = "src/postStage55FinalDate.ts";
const CATALOG = "src/sourceLanguageCatalog.ts";
function reject(msg) { throw new Error("V094_REJECT: " + msg); }
function canonicalText(s) {
  if (typeof s !== "string" || !/^(0|-[1-9]\d*|[1-9]\d*)$/.test(s)) reject("noncanonical decimal");
  return BigInt(s);
}
function argumentsFor(argv) {
  const options = new Map();
  for (let i = 0; i < argv.length; i += 2) {
    if (i + 1 >= argv.length || !argv[i].startsWith("--") ||
        options.has(argv[i])) reject("non-paired, unknown, or duplicate switch");
    options.set(argv[i], argv[i+1]);
  }
  const names = ["--source-root", "--calculation-day", "--first-target-day",
                 "--last-target-day", "--raw-out", "--catalog-out"];
  if (options.size !== names.length || names.some(n => !options.has(n)))
    reject("exact original-source, two-coordinate, and evidence options required");
  if (options.get("--calculation-day") !== C ||
      options.get("--first-target-day") !== TARGETS[0] ||
      options.get("--last-target-day") !== TARGETS[1])
    reject("only the two previously pinned ordinal-1021 target days authorized");
  names.slice(1,4).forEach(n => canonicalText(options.get(n)));
  return options;
}
function catalogRows(entries, n, label) {
  if (!Array.isArray(entries) || entries.length !== n) reject("wrong " + label + " catalog size");
  const names = [];
  for (let i=0;i<n;i++) {
    const r=entries[i];
    if (!r || r.canonicalIndex !== i+1 || typeof r.text !== "string" || !r.text)
      reject("noncanonical " + label + " catalog");
    names.push(r.text);
  }
  if (new Set(names).size !== n) reject("duplicate " + label + " catalog name");
  return names;
}
function emitExclusive(file, bytes) {
  const fd = openSync(file, "wx", 0o600);
  try { writeSync(fd, bytes); fsyncSync(fd); } finally { closeSync(fd); }
}
const o = argumentsFor(process.argv.slice(2));
if (process.env.PASTAFARI_V094_LINUX_QA_ADMITTED !== "1")
  reject("bounded Linux CI resource admission missing");
const base = realpathSync(resolve(o.get("--source-root")));
const imported = await import(pathToFileURL(realpathSync(join(base,ENTRY))).href);
const catalog = await import(pathToFileURL(realpathSync(join(base,CATALOG))).href);
if (typeof imported.calendarDateSpaghetti !== "function")
  reject("original public two-bigint entrypoint missing");
const cutlets = catalogRows(catalog.CUTLET_CATALOG,17,"cutlet");
const months = catalogRows(catalog.MONTH_CATALOG,47,"month");
const nativeMap = {cutlets,months};
emitExclusive(o.get("--catalog-out"), Buffer.from(JSON.stringify(nativeMap)+"\n","utf8"));
const fd = openSync(o.get("--raw-out"), "wx", 0o600);
let records = 0;
try {
  for (const t of TARGETS) {
    const value = imported.calendarDateSpaghetti(BigInt(C), BigInt(t));
    if (!Array.isArray(value) || value.length !== 5 ||
        typeof value[0] !== "bigint" || typeof value[1] !== "string" ||
        typeof value[2] !== "bigint" || typeof value[3] !== "string" ||
        typeof value[4] !== "bigint" || value[2] <= 0n || value[4] <= 0n ||
        !cutlets.includes(value[1]) || !months.includes(value[3]))
      reject("original returned invalid five-part native tuple");
    const native = [value[0].toString(),value[1],value[2].toString(),
                    value[3],value[4].toString()];
    const line = JSON.stringify({
      calculation_day:C,target_day:t,native_tuple:native
    })+"\n";
    writeSync(fd,Buffer.from(line,"utf8"));
    fsyncSync(fd);
    records++;
    process.stdout.write("V094_ORIGINAL_TYPESCRIPT_NATIVE_DAY_OBSERVED="+t+"\n");
  }
} finally {closeSync(fd);}
if(records!==2)reject("incomplete source two-day pilot");
const rawDigest=createHash("sha256").update(
  Buffer.from(await (await import("node:fs/promises")).readFile(o.get("--raw-out")))
).digest("hex");
process.stdout.write("V094_TYPESCRIPT_ORIGINAL_TWO_DAYS_NATIVE_NOT_YEAR raw_sha256="+rawDigest+"\n");
