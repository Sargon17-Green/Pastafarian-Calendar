DELTA DEL INTERFACIE DE NAVIGATOR PASTAFARIAN
============================================
Repository de basa: Sargon17-Green/Pastafarian-Calendar
Branche de basa: JavaScript+Interlingue
Commit de basa: c40cfae3b75d8daeb283e1fb4fd8b319b6fcb1c0

Ti livraison ne fa alcun push e ne modifica GitHub directmen.

Aplicar desde un checkout de ti branche:
  1. Copiar browser/, scripts/ e tests/ ex ti pacca al radice del repository.
  2. Copiar temporarimen DELTA_apply-package-json.mjs al radice del repository.
  3. Executer: node DELTA_apply-package-json.mjs
  4. Deleter DELTA_apply-package-json.mjs ante li commit.
  5. Executer: npm install
  6. Executer: npm run test:browser-interface
     (ti comande include li smoke-test contra li real core.)
  7. Executer: npm run build:browser
  8. Executer li existent complet suite del branche: npm test

DELTA_README.txt e DELTA_apply-package-json.mjs es auxiliari files de livraison, ne files del repository.
Li semantic core sub src/ resta intentionatmen intact.
Li generat dist/browser es un artefact de compilation; commit it solmen si li politica del repository demanda it.

Architectura:
  <pastafari-date> -> CalendarService -> PastafariEngineClient -> Worker
  -> calendarDateSpaghetti(calculationDay, targetDay)

Null router de du motores, statu de verification, comparation fast/authoritative, motor revers,
o solver de restrictiones es copiat.

Futur memorisation es injectet detra CalendarService tra CalendarMemory. Li DOM-cache de quin
cutlets del component resta un separat cache de presentation e ne deve devenir semantic statu.
