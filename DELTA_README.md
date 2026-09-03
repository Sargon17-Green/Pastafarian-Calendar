# JavaScript + Interlingue browser target-selection delta v14

Base branch: `JavaScript+Interlingue`

Base HEAD: `c41ec2fd87abbcfe57eee542ebe8ad081955d0c3`

Expected browser build ID after construction: `ecd78d6244845a3ee5458c4f`

## Problema cludet

Li target card esset marcat per JDN solmen. `_scrollSelectedIntoView()` poy seleccionat `[aria-current="date"]`, talmen li scrolling self ne verificat li quin semantic partes del Pastafarian date.

Ti delta transforma li target selection in un five-part semantic operation:

1. Li direct conversion result fornece `year`, `cutletName`, `dayInCutlet`, `monthName`, e `dayInMonth` al scrolling function.
2. Omni rendered day card publica ti quin raw semantic values in `data-*` attributes.
3. `_scrollSelectedIntoView(year, cutletName, dayInCutlet, monthName, dayInMonth)` exige exactmen omni quin partes e sercha un unic full-tuple match.
4. JDN ne es plu li selector del target. It resta un consistency check pos li full semantic match.
5. Un card con li searched JDN ma un different five-part tuple fail cludet con `ERR_CALENDAR_RENDER_INCONSISTENCY` ante rendering.
6. `aria-current="date"` es basat sur li full semantic tuple, ne sur JDN solmen.

## Regression witness

`tests/browser-component-runtime.js` construe du cards con li sam JDN `739862`:

- stale: `5000 / bronze / 677 / costa / 12`
- authoritative: `5000 / bronze / 677 / sand / 32`

Li scrolling function es invocat con li quin authoritative partes. Li prova exige que solmen `sand / 32` posse devenir `aria-current` e recever `scrollIntoView()`.

Un separat prova verifica que un cutlet view con JDN `739862` ma `costa / 12`, contra li direct `sand / 32`, fail cludet mem si null duplicat JDN card existe.

## Local verification

- `node tests/browser-interface-all.js` — PASS
- `node scripts/build-browser.js` — PASS
- classic-script parse del relevant generated `.js` — PASS
- old JDN-only target selector absent ex generated standard bundle — PASS
- raw Hebrew scan in `.js/.json/.md` — PASS
- semantic core files resta byte-identic al known base core hashes

`tests/browser-built-artifacts.js` passa su li static generated-asset assertions, ma li local execution esset stoppat per timeout durant li existent cold core witness. Li exact heavy witness deve restar un CI gate.

## Scope

Ti package ne include generated `dist/` files, semantic core files, `package.json`, workflow files, o un handoff.
