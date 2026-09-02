# Calendarul Pastafarian — J + română

Acest arbore reprezintă Stage 1 (Bootstrap) al unei linii de implementare independente, pornite de la zero. Limbajul de programare al întregii linii este J, iar limba-sursă umană este româna.

## Scopul Stage 1

Stage 1 fixează catalogul de limbă-sursă, construiește referința normativă de test direct din specificația încorporată, pregătește infrastructura neutră a monstrului și definește un ham de test local. Niciun defect legacy și niciun patch din etapele 2–53 nu este prezent aici.

## Reguli de independență

Nu s-a clonat și nu s-a consultat nicio altă implementare a calendarului. Nu s-au copiat teste, fixture-uri, rezultate așteptate, tabele generate, urme sau hash-uri de la o altă linie. Referința normativă din `test/normative_reference.ijs` este scrisă pentru această linie exclusiv din specificația Stage 1.

## Rulare

Din rădăcina proiectului, cu un runtime J 9.7.x, finalizarea Stage 1 se face printr-o singură comandă:

```text
jconsole test/complete_stage01.ijs
```

Runnerul generează `test/stage01_fixtures.tsv`, execută suita locală și actualizează `DEVELOPMENT_STAGE.md` numai după succes. Generatorul folosește numai referința normativă J din această linie. Pentru detalii, vedeți `HANDOFF_STAGE_01.md`.

## Precizie numerică

Toate calculele normative folosesc întregi extinși J (`x`) și, unde este necesară o împărțire intermediară, operatori exacți care păstrează domeniul întreg/rational. Nu se folosește aritmetică în virgulă mobilă pentru decizii normative.

## Starea dezvoltării

Vezi `DEVELOPMENT_STAGE.md`. Etapa următoare după un Bootstrap valid este Stage 2 — DISCOVERY 01.
