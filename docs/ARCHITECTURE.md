# Arhitectura Bootstrap

Stage 1 nu construiește anticipat monstrul final. Arhitectura curentă conține doar elemente neutre care pot găzdui creșterea istorică ulterioară.

`src/monster_base.ijs` definește contextul de invocare, dispatcherul de faze, validarea de bază, erorile deterministe și starea observațională. Contextul este creat pentru o singură invocare și nu se reutilizează între apeluri.

`src/calendar_spaghetti.ijs` este numai intrarea de producție Bootstrap. Ea validează tipul de intrare, creează contextul și declară explicit că motorul istoric nu este încă integrat. Nu apelează referința normativă.

`test/normative_reference.ijs` conține oracle-ul curat, test-only. El nu este încărcat de fișierele de producție.

`test/stage01_tests.ijs` verifică proprietățile normative locale, catalogul de limbă-sursă și faptul că scheletul de producție nu importă oracle-ul.

Orice manager, flag, cache sau rută specifică unui defect viitor este interzisă în această etapă.

## Stage 2 — DISCOVERY 01

Modulul src/stage02_rest_vechi.ijs păstrează modulo obișnuit cu M pozitiv, inclusiv zero la multipli. Dispecerul legacy este apelat de ruta publică de salvare, iar calendarDateSpaghettiBootstrap stochează rezultatul pentru ziua de calcul în semanticPending (index 9). Fiecare apel are context separat. Nu se importă oracle-ul; nu se introduce PATCH 01. Testele verifică explicit divergența cerută și controlul M+1. NOT_INTEGRATED rămâne obligatoriu.

DISCOVERY 01 este acceptat nativ în starea EXPECTED_RED la sursa 4c93da154362e5f9ce0e9da4a9196760eb587a37. Martorii și regresiile sunt verificate; PATCH 01 rămâne etapa următoare, neimplementată. Vezi DEVELOPMENT_STAGE.md.
