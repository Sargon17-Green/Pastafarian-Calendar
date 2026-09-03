# JavaScript + Interlingue browser target-cutlet locator v15

Base branch HEAD before this delta: `201484299f625e98fed0cfef545710ea4abc223a`.

This delta fixes the remaining initial-cutlet selection path. The direct five-field Pastafarian conversion is now authoritative before a cutlet view is requested. `dayInCutlet` determines the exact expected cutlet start JDN, and the browser requests `getCutletView()` at that start instead of asking a target-JDN lookup to choose the containing cutlet.

The returned view must prove all of the following before it can render or scroll:

- its `startJdn` equals `targetJdn - (dayInCutlet - 1)`;
- its `year` and `cutletName` equal the direct five-part result;
- the view is selected at its own start (`selectedIndex === 0`);
- day 1 is really day 1 of that same year/cutlet;
- the target is at index `dayInCutlet - 1`, has the requested JDN, and matches all five semantic fields.

Rendered cutlet sections now carry raw `year` and `cutletName` metadata. `_scrollSelectedIntoView(year, cutletName, dayInCutlet, monthName, dayInMonth)` requires the exact five-field card plus the target JDN and verifies that its containing section has the expected cutlet start and identity before scrolling.

No semantic core source, root package contract, workflow, cache namespace or public calendar calculation API is changed.

Local verification:

- `node tests/browser-interface-all.js` — PASS
- `node scripts/build-browser.js` — PASS
- browser build ID: `2f8beede962fde247e344fc5`
- classic-script parse checks — PASS
- raw Hebrew scan in modified `.js` — PASS
- `tests/browser-built-artifacts.js` passes its updated static artifact assertions, then the real heavy core witness exceeded the local execution window; GitHub CI remains the runtime gate.
