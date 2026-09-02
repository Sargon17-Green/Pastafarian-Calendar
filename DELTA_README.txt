Initial browser-interface upload for JavaScript + Interlingue.

Purpose:
- port the old external <pastafari-date> browser interface;
- keep the new calendar implementation a black box;
- do not copy the old authoritative/fast dual-engine verifier;
- leave an explicit CalendarMemory seam for later memoization;
- start with only two complete UI locales: Interlingue and English.

Apply:
1. Overlay this package at the repository root on branch JavaScript+Interlingue.
2. Delete every path listed in DELETE_PATHS.txt.
3. Do NOT run DELTA_apply-package-json.mjs and do not add esbuild.
4. Keep the root package.json unchanged.
5. Run:
   node tests/verify-stage-01.js
   node tests/browser-interface-all.js
   node scripts/build-browser.js
   node tests/browser-built-artifacts.js
6. Push only after all four commands pass.

Important semantic boundary:
The browser layer calls only calendarDateSpaghetti(calculationDay, targetDay). It must not read calendarDateSpaghettiWithContext(), context.structure, Stage 58 internals, managers, scars, or private catalog structures.

Language boundary:
The `lang` attribute changes only UI chrome and ARIA text. `value`, `ready`, `pastafari-change`, cutletName and monthName remain the exact semantic result returned by the branch core. This intentionally avoids positional translation against the incompatible old calendar-name tables.
