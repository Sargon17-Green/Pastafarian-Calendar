# Browser asset-coherence + unique-JDN render guard delta

Base branch: `JavaScript+Interlingue`  
Base HEAD: `10360f2781a833981c21f551afdbdde8286d93c5`

Ti delta clude li failure-class u un stale o mixt browser build posse coexister con un altri main/Worker build, e u duplicat cutlet data posse renderisar li sam JDN plu quam un vez.

## Asset coherence

- Li build crea un deterministic 24-hex browser build ID ex li exact browser/core build inputs.
- Li existent semantic-cache namespace resta derivat separatmen ex li semantic core. Por ti base it resta exactmen `pc-browser-core-368e258d1ca347f846f32d94`; ti delta ne invalida valid semantic cache solmen pro un UI/build change.
- Li public Pages HTML es generat quam `browser/dist/index.html` e carga `pastafari-date.js?v=<buildId>`.
- Li standard main bundle crea su Worker con `pastafari-worker.js?v=<buildId>`.
- Li main bundle include li expectat build ID in chascun Worker request; li Worker include su propri build ID in chascun response.
- Un nov main con un old Worker, o un old main con un nov Worker, falli cludet con `ERR_BROWSER_BUILD_MISMATCH` invez de continuar con mixt assets.
- Li Worker verifica li request build ID ante un semantic core call.
- `browser/dist/build-id.txt` es creat quam observable deployment diagnostic. It ne participa in calendar semantics.

## Unique JDN guard

- Ante DOM replacement, li component registra omni rendered day per exact JDN.
- Si li sam JDN apari denov con exactmen li sam quin semantic fields, li duplicat card es omisset.
- Si li sam JDN apari con diferent `year`, `cutletName`, `dayInCutlet`, `monthName` o `dayInMonth`, li component falli cludet con `ERR_CALENDAR_RENDER_INCONSISTENCY`.
- Pos render, li component anc verifica que ne existe plu quam un `[aria-current="date"]`.
- Ti es un data-correctness guard; li auto-scroll logic ne es usat por arbitrarmen selecter un del du resultates.

## Investigation conclusion

Li clean current HEAD ne reproducte li observat `sand 32` -> `costa 12` divergence in li public call sequence documentat in li handoff. Li previous main service at `9931b6e23ca0272f9e242935a0beb7123c78338c` posseva promoter un cutlet-view result al conversion cache; li current service ne posse plu far to.

Un real cache-coherence lacune esset confirmat: Pages cargat li main bundle e li main cargat li Worker per unversioned URLs, sin un shared runtime build handshake. Ma li exact browser-cache state del screenshots ne esset capturat, e li Worker del immediate parent Pages build es byte-identic al current Worker. Ergo li exact historic cause del screenshots ne es forensically provat; ti delta elimina li mixt-build lacune e rende omni futur same-JDN semantic split fail-closed.

Null speculative `src/index.js` correction es includet.

## Local validation

Passed:

- `node tests/browser-interface-all.js`
- `node scripts/build-browser.js`
- classic-script parse of changed/relevant `.js`
- raw-Hebrew source scan for `.js/.json/.md`
- byte identity of `src/index.js` and `src/source-language-catalog.js` against li verified base
- static built-asset coherence checks for generated HTML, main bundle and Worker

Final build ID in ti package test build: `caf64e842bc0963c57d3f1d3`.

Li real built-artifact witness `calendarDateSpaghetti(739862n,739862n)` esset startat localmen, ma li container ne completat li semantic calculation intra 15 minutes. Diagnostics confirma que li wait es intra li real `calendarDateSpaghetti` call, ne in li nov Worker protocol. Ti witness ne es declarat PASS localmen. Li unchanged base HEAD had passat li exact built witness in GitHub Actions; pos upload, CI deve rerun `tests/browser-built-artifacts.js` contra ti delta.

## Files

Ti package include solmen source/workflow/test replacements plus ti README e manifest. It exclude:

- `src/**`
- root `package.json`
- generated `browser/dist/**`
- generated Standalone bundles
- HANDOFF files
