# Stadio 9 — DISCOVERY 05: kanona interliga sumo

**Stato (2026-10-31):** la koda HEAD finis ambaŭ CI-pordegojn verda; Stage09 fermiĝis laŭ koda pruvo, sed ĉi tiu posta dokumenta HEAD devas ricevi propran CI antaŭ plena dokumenta konfirmo.

## Enigo, eligo, sendependa orakolo

Enigo: `bootstrap.MonsterContext(calculation_day: Int, target_day: Int, ...)`.
Eligo ĉe valida kunteksto: `Ok(Discovery05Output(context, action_count, target_count, connection))`; ĉe malvalida kunteksto: ekzistantaj `InvalidRetryBudget` / `InvalidRecoveryDepth` kun la sama prioritato kiel `bootstrap.dispatch_context`.

La kanona `test/reference/core.gleam::work_counts(a,b)` difinas:
- `action = day_count(a)`
- `target = day_count(b)`
- **`connection = action + target`**

La nova produktmodulo `src/pastafari/discovery_05_connection.gleam` kunmetas la jam proprabrancxe korektitan `discovery_02_day_tag.day_tag_patch` por la du tagoj kaj sumigas la rezultojn. Ĝi ne importas la testan referencon. La orakolo en `test/discovery_05_test.gleam` uzas nur `core.work_counts(a,b).connection` por atendataj valoroj kaj komparas ankaŭ limkazan aritmetikon. Ĉi tio estas sendependa testa orakolo, kvankam la produkta sumo reuzas sian propran ekzistantan produkttagmarkon.

## Normigaj atestoj

Kun `F = -15_055_671`: `connection(F,F)=2`, `connection(F,F-1)=3`, `connection(F,F+1)=4`, `connection(F-2,F+2)=9`.
Kontrolu ambaŭ direktojn, nulon kaj negativajn tagojn, grandajn kontraŭsignajn entjerojn, simetrion, du laŭpaŝajn diferencojn de +2, izolitajn kuntekstojn kaj ĉiujn tri invalid-kuntekstajn prioritatojn.
Matematika BigInt-antaŭkontrolo: 10/10 elektitaj paroj, nur aritmetiko, ne Gleam Native.
Neniu historie pruvita bugo aŭ EXPECTED_RED estas asertata.

## Akceptopordegoj

1. Antaŭa Stage08 dokumenta HEAD `99bbd52ace9e96f33c9972e38ef33140151cb560`: Native 41184325448 completed/success, Gleam 1.18.1 / OTP 28, formato kaj 65/65 testoj PASS; Canonical Names Lock 41184325509 completed/success sur sama SHA.
2. Aldonu unu diagnozan produktmodulon kaj 13 novajn testojn, sen ŝanĝi la kvin finajn datokomponantojn, `test/reference/core.gleam`, `main`, aŭ ekzistantajn nomlistojn. Antaŭa regresa bazo: 65; kalkulita nova celo: 78 PASS / 0 FAIL, **ne mezurita**.
3. `gleam format --check src test`, `gleam test`, kaj Canonical Names Lock ĉe la sama nova commit. Analizu precizan logon antaŭ korekto; formato aŭ testoj ne estas PASS ĝis efektiva CI.
4. Konservu SHA, run ID, job ID, nombrojn de testoj, kaj artefaktan hash. `LAST_COMPLETED_STAGE=8` ĝis ambaŭ novaj pordegoj pasis.
5. La skopo estas diagnozo de `work_counts.connection`, ne kompleta datkalkulo, ne nova sesa komponento, ne kunfando al `main`.

## Fakta fermo post la antaŭa plano — 2026-10-31

- Komita SHA: `f4e2d142c062effa521f4cd8add2da7a5d1c0745` sur branĉo `Gleam+Esperanto`, egalita per viva branĉa kontrolo.
- Native run 41187241735, job 124496538248: `completed/success`, Gleam 1.18.1 / OTP 28, `gleam format --check src test` PASS, `gleam test`: **78 passed, no failures**.
- Canonical Names Lock run 41187241745, job 124496538192: `completed/success` sur la sama SHA.
- Native evidence artifact 13037855387, GitHub-raportita SHA256 `f8afc907e1b2f164333b10cf033faec78e85a59032cc9405c7d53cfc109732ac`.
- La originala akcepta celo de 78 estis prognozo kiam la antaŭa kontrakto estis verkita; la supra 78 estas efektive mezurita per Native CI. Neniu plena datokonverto aŭ main-merge estas asertata.
