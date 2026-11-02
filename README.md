# Calendarul Pastafarian - J + romana

Aceasta este o linie de implementare independenta, pornita de la zero. Limbajul de programare este J, iar limba-sursa umana este romana. Stage 1 si Stage 2 au fost acceptate prin executii native; Stage 3 / PATCH 01 este pregatit pentru verificare nativa si nu este inca acceptat.

## Scopul Stage 1

Stage 1 fixeaza catalogul de limba-sursa, construieste referinta normativa de test direct din specificatia incorporata, pregateste infrastructura neutra a monstrului si defineste un ham de test local. Niciun defect legacy si niciun patch din etapele 2-53 nu este prezent in scheletul initial.

## Reguli de independenta

Nu s-a clonat si nu s-a consultat nicio alta implementare a calendarului. Nu s-au copiat teste, fixture-uri, rezultate asteptate, tabele generate, urme sau hash-uri de la o alta linie. Referinta normativa din `test/normative_reference.ijs` este scrisa pentru aceasta linie exclusiv din specificatia Stage 1.

## Rulare

Pentru verificarea nativa Windows, folositi pachetul Native QA versionat pregatit pentru etapa curenta. Runtime-ul J 9.7.1 este descarcat si verificat SHA256 de runner.

Comanda locala de baza pentru Stage 1 ramane:

```text
jconsole test/complete_stage01.ijs
```

## Precizie numerica

Toate calculele normative folosesc intregi extinsi J (`x`) si, unde este necesara o impartire intermediara, operatori exacti care pastreaza domeniul intreg/rational. Nu se foloseste aritmetica in virgula mobila pentru decizii normative. PATCH 01 normalizeaza zilele intregi acceptate, inclusiv intrarile rational cu numitor 1, la extended integer inainte de calculul celor cinci valori de lucru.

## Starea dezvoltarii

Stage 1: 63/63 Native PASS. Stage 2: 17/17 Native PASS. Stage 3 / PATCH 01: pregatit pentru Native QA, in asteptarea rezultatelor; calea publica ramane `NOT_INTEGRATED`.
