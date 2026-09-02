import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as esbuild from "esbuild";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const out = path.join(root, "dist", "browser");
const standaloneOut = path.join(out, "standalone");

await rm(out, { recursive: true, force: true });
await mkdir(standaloneOut, { recursive: true });

await esbuild.build({
  entryPoints: [path.join(root, "browser", "pastafari-date.js")],
  outfile: path.join(out, "pastafari-date.js"),
  bundle: true,
  format: "esm",
  platform: "browser",
  target: ["es2022"],
  sourcemap: true,
});

await esbuild.build({
  entryPoints: [path.join(root, "browser", "pastafari-worker-entry.js")],
  outfile: path.join(out, "pastafari-worker.js"),
  bundle: true,
  format: "esm",
  platform: "browser",
  target: ["es2022"],
  sourcemap: true,
});

const workerBuild = await esbuild.build({
  entryPoints: [path.join(root, "browser", "pastafari-worker-entry.js")],
  bundle: true,
  format: "iife",
  platform: "browser",
  target: ["es2022"],
  write: false,
});
const workerSource = workerBuild.outputFiles[0].text;
const virtualStandaloneEntry = `
import { CalendarService, installSharedCalendarService } from "./browser/calendar-service.js";
import { PastafariEngineClient } from "./browser/engine-client.js";
import { getPastafariDate, getPastafariDateAsync } from "./browser/pastafari-date.js";
const workerSource = ${JSON.stringify(workerSource)};
function workerFactory() {
  if (typeof globalThis.Worker !== "function" || typeof globalThis.Blob !== "function" || !globalThis.URL?.createObjectURL) {
    throw new Error("Li standalone build besona classic Worker, Blob e URL.createObjectURL().");
  }
  const url = URL.createObjectURL(new Blob([workerSource], { type: "text/javascript" }));
  const worker = new Worker(url, { name: "pastafari-calendar-standalone" });
  const terminate = worker.terminate.bind(worker);
  worker.terminate = () => { try { terminate(); } finally { URL.revokeObjectURL(url); } };
  return worker;
}
installSharedCalendarService(new CalendarService({ engineClient: new PastafariEngineClient({ workerFactory }) }));
globalThis.PastafariCalendarStandalone = Object.freeze({ getPastafariDate, getPastafariDateAsync });
`;

async function buildStandalone(outfile, minify) {
  await esbuild.build({
    stdin: { contents: virtualStandaloneEntry, resolveDir: root, sourcefile: "standalone-entry.js", loader: "js" },
    outfile,
    bundle: true,
    format: "iife",
    platform: "browser",
    target: ["es2022"],
    minify,
    legalComments: "none",
  });
}

await buildStandalone(path.join(standaloneOut, "pastafari-date.js"), false);
await buildStandalone(path.join(standaloneOut, "pastafari-date.min.js"), true);
await writeFile(path.join(out, "example.html"), await readFile(path.join(root, "browser", "example.html"), "utf8"));
await writeFile(path.join(standaloneOut, "example-file.html"), await readFile(path.join(root, "browser", "standalone", "example-file.html"), "utf8"));
await writeFile(path.join(out, "README.md"), await readFile(path.join(root, "browser", "README.md"), "utf8"));
console.log("Interfacie de navigator compilat in dist/browser");
