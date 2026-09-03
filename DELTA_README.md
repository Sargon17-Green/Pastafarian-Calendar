# Persistent browser-cache invalidation — delta v13

Ti delta clude un restant browser-correctness lacune sin modificar li semantic core.

## Problema cludet

Li persistent browser memory acceptet schema 2 conversions quam direct authority. Si un obsolete browser session hat jam persistet un incorrect direct conversion, un nov page-load pos li asset-coherence correction posse reutilisar ti value sin recalculation per li engine.

Ti exact historic origine del observed divergence ne es declarat provat. Ti delta clude li confirmed persistence gap quel posse conservar un tal stale conversion si it existe.

## Correction

- `PERSISTENT_SCHEMA_VERSION` avansa de 2 a 3.
- Al prim construction con li existent `pc-browser-core-*` namespace, schema-2 storage es ignorat e removet per li existent namespace cleanup.
- Null semantic-core fingerprint es changeat.
- Li browser build fingerprint cambia automaticmen pro que `browser/calendar-memory.js` es un build input; talmen li generated main e Worker recive un nov shared build ID.

## Regression

`tests/browser-consistency-cache.js` nu sema un schema-2 conversion por JDN 739862 con li stale value `5000 / bronze / 677 / costa / 12`. Li prova exige que schema 3:

1. ne lee ti obsolete conversion;
2. remove li schema-2 storage key;
3. recalcula li direct result per li engine;
4. retorna e persiste solmen `5000 / bronze / 677 / sand / 32` sub schema 3.

## Local verification

- `node tests/browser-consistency-cache.js` — PASS
- `node tests/browser-interface-all.js` — PASS
- `node scripts/build-browser.js` — PASS
- generated browser build ID: `a51c85ecd1e7dd9bf262575d`
- generated Pages script URL: `pastafari-date.js?v=a51c85ecd1e7dd9bf262575d`
- `src/index.js` e `src/source-language-catalog.js` resta byte-identic al pre-delta source.
- Classic-script parse de li changed JavaScript files — PASS
- Raw Hebrew scan de li changed JS/JSON/MD files — PASS

`tests/browser-built-artifacts.js` ne finit localmen in li available execution environment durant li heavy real witness calculation. Ti sam heavy gate passat in GitHub Actions por v12 e deve esser executet denov per CI pos ti delta.

## Files

Ti ZIP contene solmen li files quel deve esser cargat por ti delta. Null generated `browser/dist`, null HANDOFF, null `package.json`, null semantic-core file e null workflow YAML es includet.
