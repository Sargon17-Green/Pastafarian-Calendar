# Istoria dezvoltării monstrului spaghetti

## Stage 1 — Bootstrap

### Ce exista la început

Nimic. Linia J + română a fost pornită într-un arbore gol, exclusiv din specificația furnizată pentru această linie.

### Ce s-a construit

S-au introdus numai mecanisme generale, neutre: un context de invocare, un dispatcher de faze, un validator de bază, un înveliș determinist pentru erori, un registru de metrici și jurnalizare ne-semantică. Niciunul nu conține cunoaștere despre defectele legacy sau despre patch-urile 01–26.

S-a creat și referința normativă de test în J, separată de scheletul de producție. Referința nu este disponibilă ca fallback pentru producție.

### Catalogul de limbă-sursă

Catalogul românesc este înghețat în Stage 1. Ordinea semantică este definită exclusiv de `canonicalIndex`; textul românesc nu participă la sortare, rank, unrank, cache-uri semantice sau selecții.

### Stratul de monstru adăugat

Stratul adăugat este intenționat modest și neutru: context + dispatcher + validator + error wrapper + metrici. El este observațional sau structural și nu schimbă niciun rezultat normativ.

Nu există încă secțiuni pentru patch-uri. Ele vor fi adăugate numai atunci când etapele istorice respective vor avea loc.

## Stage 2 — DISCOVERY 01 — realiniere canonica

Specificația independentă originală, 06-implementation-prompt.md, 2026-08-26, fixează succesiunea DISCOVERY 01/PATCH 01. Ipoteza veche este că modulo obișnuit este SAVE; la M, 2M și 3M rezultă zero în loc de M, iar la M+1 rezultatul coincide. Producția păstrează restVechi, dispecerRestVechi și ruta calendarSalvareSpaghete; contextul public observă rezultatul, fără a pretinde integrarea datei. Nu există corecția PATCH 01. Aserțiunile normative sunt separate și se cer trei RED exacte și un control GREEN. Execuția nativă a confirmat starea EXPECTED_RED; DISCOVERY 01 este acceptat.

Istoricul anterior, inclusiv rezultatul nativ v17 (115/115), este păstrat integral prin părintele 842f6044b2689f20b39a28afad56be5da23c893e. Baza canonică activă este Stage 1 acceptat, 7c23a7e46b521adf2b52c42987366fb17aa901ee. Acceptarea istorică a rezultatelor nu este anulată; conformitatea ordinală a etapelor 2–4 a fost infirmată de specificație. Nu se introduc etape viitoare.

### Acceptare nativă

2026-11-28 — DISCOVERY 01 ACCEPTAT nativ, în starea intenționată EXPECTED_RED. Arhiva results(20261128-094801).zip, SHA256=12b2aee364bc300fed8ea8d5b4002a4b4ab009202aa638e2204d61e92a495818; CRC PASS; 27/27 înregistrări manifest verificate independent; patru loguri finale goale sunt în afara manifestului. Sursa executată: 4c93da154362e5f9ce0e9da4a9196760eb587a37, tree 048d84901bcd57bd7cffc7c6459663a4d5d89647; jurnalul runnerului confirmă 20/20 Git blob IDs (fișierele sursă nu sunt incluse în arhiva de rezultate). J9.7.1 j64 Windows; probe -js fără marker, fallback stdin reușit. 63/63 regresii Stage1, 17 fixtures, 18/18 martori Stage2, RED 0,1,2, control GREEN 3, receipt PASSED, exit 0. Contorizare independentă din stdout, stderr gol. Wrapper v19, runner intern v18. LAST_COMPLETED_STAGE=2. Etapa următoare: Stage 3 PATCH 01, păstrarea intactă a restVechi și a martorilor, strat suplimentar 0→M; nu a fost implementată. Data publică NOT_INTEGRATED. Nu se repetă v18/v19.
