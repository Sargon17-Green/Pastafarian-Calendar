# Arhitectura Bootstrap

Stage 1 nu construiește anticipat monstrul final. Arhitectura curentă conține doar elemente neutre care pot găzdui creșterea istorică ulterioară.

`src/monster_base.ijs` definește contextul de invocare, dispatcherul de faze, validarea de bază, erorile deterministe și starea observațională. Contextul este creat pentru o singură invocare și nu se reutilizează între apeluri.

`src/calendar_spaghetti.ijs` este numai intrarea de producție Bootstrap. Ea validează tipul de intrare, creează contextul și declară explicit că motorul istoric nu este încă integrat. Nu apelează referința normativă.

`test/normative_reference.ijs` conține oracle-ul curat, test-only. El nu este încărcat de fișierele de producție.

`test/stage01_tests.ijs` verifică proprietățile normative locale, catalogul de limbă-sursă și faptul că scheletul de producție nu importă oracle-ul.

Orice manager, flag, cache sau rută specifică unui defect viitor este interzisă în această etapă.

## Stage 2 — DISCOVERY 01

Modulul src/stage02_rest_vechi.ijs păstrează modulo obișnuit cu M pozitiv, inclusiv zero la multipli. Dispecerul legacy este apelat de ruta publică de salvare, iar calendarDateSpaghettiBootstrap stochează rezultatul pentru ziua de calcul în semanticPending (index 9). Fiecare apel are context separat. Nu se importă oracle-ul; nu se introduce PATCH 01. Testele verifică explicit divergența cerută și controlul M+1. NOT_INTEGRATED rămâne obligatoriu.

DISCOVERY 01 este acceptat nativ în starea EXPECTED_RED la sursa 4c93da154362e5f9ce0e9da4a9196760eb587a37. Martorii și regresiile sunt verificate; PATCH 01 a fost implementat și acceptat ulterior. Vezi DEVELOPMENT_STAGE.md.

## Stage 3 — PATCH 01

`src/stage03_save_patch.ijs` este încărcat după modulul legacy. `calendarSalvareSpaghete` este redirecționat către `salvarePatch01`, care apelează dispecerul vechi și repară numai restul zero. Accesorul istoric al contextului păstrează numele și indexul 9; valoarea activă este acum SAVE. Nicio schimbare a oracolului sau a validării, nicio integrare completă a datei. Verificarea nativă este ACCEPTAT GREEN.

2026-11-28 — Stage 3 PATCH 01 ACCEPTAT nativ pe J9.7.1 Windows x64, runner v20. Sursa executată: 8adc978d973f01669ba45ef0243be94885457c62, tree 855d1eb71ef9d909aacfdaddbaaecfd1e5fa7537. Rezultate: 63/63 Stage1, 17 fixtures, 18/18 martori, 6/6 PATCH01, GREEN 0,1,2,3, zero RED; exit 0, receipt PASSED, stderr gol. CRC PASS, manifest 27/27 verificat independent; 21/21 blob IDs conform jurnalului runnerului (sursa nu este în arhivă). LAST_COMPLETED_STAGE=3. Data publică NOT_INTEGRATED. Stage 4 nu a fost început; nu se repetă v20.

## Stage 4 — DISCOVERY 02

Ipoteza greșită: eticheta zilei este întotdeauna 2 × distanța absolută față de Fundație. Modulul nou `src/stage04_eticheta_veche.ijs` păstrează exact această formulă, iar ruta publică introduce etichetele de calcul și țintă în context, la indicii 11 și 12, fără a modifica indexul SAVE. Oracolul de test și regresiile precedente rămân neschimbate. Pentru offseturile -2, -1, 0, +1, +2, rezultatele legacy sunt 4, 2, 0, 2, 4, iar cele normative sunt 4, 2, 1, 3, 5. Se cer controalele GREEN 0,1 și RED intenționate 2,3,4, 33 verificări Stage4 și toate regresiile anterioare. Nu există PATCH 02, nici integrarea datei publice. Execuția nativă încă nu a avut loc; LAST_COMPLETED_STAGE=3.

2026-11-28 — Stage 4 DISCOVERY 02 ACCEPTAT nativ în starea EXPECTED_RED, J9.7.1 Windows x64, runner v22. Sursa executată: 2d980a1021896b92b2d4a446517d140f3de1d820, tree b22be59a91400bb1ba7b1ed673bb110132cb807a. Rezultate recuperate fără o nouă execuție: results.zip SHA256=37907439d6dd8ed30e7e472fc9f2d9b6cf5712d2ad2953b65491ecbafee0721e; arhiva de recuperare SHA256=dfab6945d33968c25de10d654af3bdadeccd245a1dc0ee0d62ceab78bdec104a. CRC PASS pentru ambele, manifest 29/29 verificat independent, 23/23 blob IDs conform jurnalului runnerului (sursa nu este inclusă în rezultate). Stage1 63/63 și 17 fixtures, Stage2 18/18 și GREEN 0,1,2,3, Stage3 6/6, Stage4 33/33, GREEN 0,1 și RED intenționat 2,3,4; receipt PASSED, native=true, exit 0, stderr gol. LAST_COMPLETED_STAGE=4. Data publică NOT_INTEGRATED. Stage5 nu a fost început; nu se repetă v22.
