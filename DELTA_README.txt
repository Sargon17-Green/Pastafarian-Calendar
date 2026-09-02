Browser-interface localization correction for JavaScript + Interlingue.

Purpose:
- make visible cutlet and month names use the selected UI language;
- preserve the current calendar engine as an opaque black box;
- map translations by exact semantic source identity, not by old positional tables;
- fail explicitly if a locale lacks a current cutlet/month name.

Apply:
1. Overlay this package at the repository root on branch JavaScript+Interlingue.
2. Do not delete or change any other file.
3. Keep root package.json, src/**, DEVELOPMENT_STAGE.md and workflows unchanged.
4. Run:
   node tests/verify-stage-01.js
   node tests/browser-interface-all.js
   node scripts/build-browser.js
   node tests/browser-built-artifacts.js
5. Push only after all four commands pass.

Semantic boundary:
The browser layer still calls only calendarDateSpaghetti(calculationDay, targetDay). Calendar display translation occurs after the raw black-box result is returned. Raw `value`, `ready`, and `pastafari-change` semantics do not change with `lang`.

Coverage rule:
A locale is valid only when its calendar maps exactly cover the current SourceLanguageCatalog source texts (17 cutlets and 47 months). The tests compare key sets against src/source-language-catalog.js and include regressions for larice/Larch and leopard/Leopard, so old lagash/tiger/susa positional identities cannot slip back in silently.
