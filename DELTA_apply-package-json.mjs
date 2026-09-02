import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const packagePath = path.resolve(process.cwd(), "package.json");
const raw = await readFile(packagePath, "utf8");
const pkg = JSON.parse(raw);

if (pkg.name !== "pastafari-calendar-javascript-interlingue-occidental") {
  throw new Error(`Ínexpectat nómine de package: ${pkg.name}`);
}
if (!pkg.scripts || typeof pkg.scripts !== "object") {
  throw new Error("package.json ne have un object scripts.");
}

const additions = {
  "build:browser": "node scripts/build-browser.mjs",
  "test:browser-interface": "node tests/browser-interface-service.js && node tests/browser-interface-contract.js && node tests/browser-interface-black-box.js && node tests/browser-core-smoke.js",
  "test:browser-core-smoke": "node tests/browser-core-smoke.js",
  "pretest": "npm run test:browser-interface",
};
for (const [key, value] of Object.entries(additions)) {
  if (pkg.scripts[key] != null && pkg.scripts[key] !== value) {
    throw new Error(`Refusante superscrir li conflictent package-script ${key}.`);
  }
  pkg.scripts[key] = value;
}

pkg.devDependencies ??= {};
if (pkg.devDependencies.esbuild != null && pkg.devDependencies.esbuild !== "0.28.2") {
  throw new Error(`Refusante substituer li existent version de esbuild ${pkg.devDependencies.esbuild}.`);
}
pkg.devDependencies.esbuild = "0.28.2";

await writeFile(packagePath, `${JSON.stringify(pkg, null, 2)}\n`, "utf8");
console.log("package.json actualisat por li delta del interfacie de navigator.");
