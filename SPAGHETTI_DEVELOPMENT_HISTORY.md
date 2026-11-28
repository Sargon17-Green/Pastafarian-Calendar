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

## Stage 3 — PATCH 01

Învelișul `salvarePatch01` cheamă dispecerul istoric, înlocuiește doar restul zero cu M și păstrează orice alt rest. Fișierul legacy rămâne intact. Ruta publică folosește noul înveliș; martorii istorici verifică dispecerul, iar aserțiunile normative neschimbate sunt obligatoriu GREEN. Execuția nativă este ACCEPTAT GREEN; Stage 3 este ultima etapă acceptată.

2026-11-28 — Stage 3 PATCH 01 ACCEPTAT nativ pe J9.7.1 Windows x64, runner v20. Sursa executată: 8adc978d973f01669ba45ef0243be94885457c62, tree 855d1eb71ef9d909aacfdaddbaaecfd1e5fa7537. Rezultate: 63/63 Stage1, 17 fixtures, 18/18 martori, 6/6 PATCH01, GREEN 0,1,2,3, zero RED; exit 0, receipt PASSED, stderr gol. CRC PASS, manifest 27/27 verificat independent; 21/21 blob IDs conform jurnalului runnerului (sursa nu este în arhivă). LAST_COMPLETED_STAGE=3. Data publică NOT_INTEGRATED. Stage 4 nu a fost început; nu se repetă v20.

## Stage 4 — DISCOVERY 02

Ipoteza greșită: eticheta zilei este întotdeauna 2 × distanța absolută față de Fundație. Modulul nou `src/stage04_eticheta_veche.ijs` păstrează exact această formulă, iar ruta publică introduce etichetele de calcul și țintă în context, la indicii 11 și 12, fără a modifica indexul SAVE. Oracolul de test și regresiile precedente rămân neschimbate. Pentru offseturile -2, -1, 0, +1, +2, rezultatele legacy sunt 4, 2, 0, 2, 4, iar cele normative sunt 4, 2, 1, 3, 5. Se cer controalele GREEN 0,1 și RED intenționate 2,3,4, 33 verificări Stage4 și toate regresiile anterioare. Nu există PATCH 02, nici integrarea datei publice. Execuția nativă încă nu a avut loc; LAST_COMPLETED_STAGE=3.

2026-11-28 — Stage 4 DISCOVERY 02 ACCEPTAT nativ în starea EXPECTED_RED, J9.7.1 Windows x64, runner v22. Sursa executată: 2d980a1021896b92b2d4a446517d140f3de1d820, tree b22be59a91400bb1ba7b1ed673bb110132cb807a. Rezultate recuperate fără o nouă execuție: results.zip SHA256=37907439d6dd8ed30e7e472fc9f2d9b6cf5712d2ad2953b65491ecbafee0721e; arhiva de recuperare SHA256=dfab6945d33968c25de10d654af3bdadeccd245a1dc0ee0d62ceab78bdec104a. CRC PASS pentru ambele, manifest 29/29 verificat independent, 23/23 blob IDs conform jurnalului runnerului (sursa nu este inclusă în rezultate). Stage1 63/63 și 17 fixtures, Stage2 18/18 și GREEN 0,1,2,3, Stage3 6/6, Stage4 33/33, GREEN 0,1 și RED intenționat 2,3,4; receipt PASSED, native=true, exit 0, stderr gol. LAST_COMPLETED_STAGE=4. Data publică NOT_INTEGRATED. Stage5 nu a fost început; nu se repetă v22.

## Stage 5 — PATCH 02

Învelișul `etichetaZiPatch02` apelează dispecerul legacy intact. Pentru ziua Fundației și zilele ulterioare adaugă 1; păstrează separat garda istorică de la Fundație. Ruta publică folosește învelișul, iar martorii istorici verifică în continuare valorile vechi. Se cer 33 verificări Stage4, cinci marcaje GREEN, zero RED, 20 verificări Stage5 și toate regresiile anterioare. Execuția nativă NU A AVUT LOC; LAST_COMPLETED_STAGE=4. Data publică NOT_INTEGRATED. Fără Stage 6.
