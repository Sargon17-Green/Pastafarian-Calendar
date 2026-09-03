# JavaScript + Interlingue browser correctness + persistent cache delta

Base branch: `JavaScript+Interlingue`  
Base HEAD: `9931b6e23ca0272f9e242935a0beb7123c78338c`

Ti delta corrige li failure-class u li direct five-field conversion e li cutlet-view posse diverger por li sam `(calculationDay,targetDay)`.

## Correctness

- `CalendarService.convert()` es nu li authority por li exact target; un cutlet-view ne posse plu repopular o superscrir li direct conversion cache.
- `getCutletView()` compara li selected day del view contra li direct five-field result ante display o cache.
- Si li unesim view diverge, li single Worker es recreat e li cutlet-view es calculat un vez denov ex un clean black-box core instance.
- Si li clean retry ancor diverge, li service falli cludet con `ERR_CALENDAR_INCONSISTENCY`, purga li calculation cache e ne monstra/cacha null arbitrari side.
- Li build-artefact test pinna li observat semantic witness: project-day `739862` deve esser `(5000, bronze, 677, sand, 32)`.

## Persistent browser cache

- Li shared browser service usa `PersistentCalendarMemory`, con bounded hot memory + bounded `localStorage` persistence.
- Direct conversions e exact requested cutlet-views survive un nov page load sur li sam computer/browser origin.
- Persistent cutlet data es compact serialisat; quota failures degrada silentmen a in-memory cache.
- Li persistent namespace include un SHA-256 fingerprint del exact bundled semantic core plus un cache schema version. Un core change ne posse reutilisar semantic cache entries de un old build.
- Default direct `new CalendarService()` resta backward-compatible con `BoundedCalendarMemory`; persistence es li default solmen por li shared browser service.

## Files

- `browser/calendar-memory.js`
- `browser/calendar-service.js`
- `scripts/build-browser.js`
- `tests/browser-interface-service.js`
- `tests/browser-consistency-cache.js` (new)
- `tests/browser-interface-all.js`
- `tests/browser-built-artifacts.js`

Null `src/**`, root `package.json`, generated `browser/dist/**` o HANDOFF file es includet.
