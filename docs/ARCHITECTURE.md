# Arhitectura Bootstrap

Stage 1 nu construieste anticipat monstrul final. Arhitectura curenta contine doar elemente neutre care pot gazdui cresterea istorica ulterioara.

`src/monster_base.ijs` defineste contextul de invocare, dispatcherul de faze, validarea de baza, erorile deterministe si starea observationala. Contextul este creat pentru o singura invocare si nu se reutilizeaza intre apeluri.

`src/calendar_spaghetti.ijs` este numai intrarea de productie Bootstrap. Ea valideaza tipurile de intrare, creeaza contextul si declara explicit ca motorul istoric nu este inca integrat. Nu apeleaza referinta normativa.

`test/normative_reference.ijs` contine oracle-ul curat, test-only. El nu este incarcat de fisierele de productie.

`test/stage01_tests.ijs` verifica proprietatile normative locale, catalogul de limba-sursa si faptul ca scheletul de productie nu importa oracle-ul.

## Stage 2 - calea incrementala pentru valorile de lucru

`src/stage02_counts.ijs` implementeaza in productie etichetele zilelor, distanta inclusiva, suma si directia. `calendarDateSpaghettiBootstrap` le calculeaza dupa validarea intrarii si le stocheaza in campul `semanticPending` al contextului. `MONSTER_STATUS_NOT_INTEGRATED` ramane obligatoriu pana la integrarea calculului complet al datei. `test/stage02_tests.ijs` testeaza aceasta cale cu valori asteptate explicite, fara importarea oracle-ului normativ in productie.

## Stage 3 - PATCH 01: canonizarea zilelor intregi

Validatorul accepta numere rational exacte atunci cand valoarea lor este intreaga. In J, o valoare rationala ramane in domeniul rational la operatii precum `floor`; aritmetica mixta promoveaza operanzii extended integer la rational. Fara canonizare, o intrare valida precum `_15055671r1` poate face ca cele cinci valori de lucru sa aiba tipul 128 in loc de tipul extended integer 64 cerut de contract.

`stage02CanonicalDay` extrage numaratorul si numitorul exact cu `2 x:`, verifica numitorul 1 si returneaza numaratorul ca extended integer. `stage02CountForDay` si `stage02WorkCounts` folosesc forma canonica; intrarea publica inlocuieste si valorile zilelor din context cu aceasta forma dupa validare. Nu se foloseste aritmetica in virgula mobila, cele cinci formule nu se schimba, iar oracle-ul nu este importat in productie.

`test/stage03_patch01_tests.ijs` verifica faptul ca fixture-urile sunt realmente de tip rational 128, ca rezultatele si zilele din context sunt extended integer, comportamentul inainte/inapoi/aceeasi zi, un rational intreg mare, respingerea fractiilor si pastrarea `NOT_INTEGRATED`. Stage 3 ramane in asteptarea Native QA pe Windows.
