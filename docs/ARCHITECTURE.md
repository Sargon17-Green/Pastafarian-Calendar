# Arhitectura Bootstrap

Stage 1 nu construiește anticipat monstrul final. Arhitectura curentă conține doar elemente neutre care pot găzdui creșterea istorică ulterioară.

`src/monster_base.ijs` definește contextul de invocare, dispatcherul de faze, validarea de bază, erorile deterministe și starea observațională. Contextul este creat pentru o singură invocare și nu se reutilizează între apeluri.

`src/calendar_spaghetti.ijs` este numai intrarea de producție Bootstrap. Ea validează tipul de intrare, creează contextul și declară explicit că motorul istoric nu este încă integrat. Nu apelează referința normativă.

`test/normative_reference.ijs` conține oracle-ul curat, test-only. El nu este încărcat de fișierele de producție.

`test/stage01_tests.ijs` verifică proprietățile normative locale, catalogul de limbă-sursă și faptul că scheletul de producție nu importă oracle-ul.

Orice manager, flag, cache sau rută specifică unui defect viitor este interzisă în această etapă.

## Stage 2 — integrare incrementala

`src/stage02_counts.ijs` implementeaza separat in productie etichete de zile, distanta inclusiva, suma si directia. `calendarDateSpaghettiBootstrap` le calculeaza dupa validarea intrarii si le depoziteaza in campul `semanticPending` al contextului. `MONSTER_STATUS_NOT_INTEGRATED` ramane obligatoriu pana la integrarea intregului calcul de data. `test/stage02_tests.ijs` testeaza aceasta cale prin valori asteptate explicite, fara importul oracle-ului normativ in productie.
