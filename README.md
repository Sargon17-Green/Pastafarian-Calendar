# Calendarul Pastafarian — J + română

Acest arbore continuă Stage 1 (Bootstrap) prin Stage 2 (DISCOVERY 01) al unei linii de implementare independente, pornite de la zero. Limbajul de programare al întregii linii este J, iar limba-sursă umană este româna.

## Scopul Stage 1

Stage 1 fixează catalogul de limbă-sursă, construiește referința normativă de test direct din specificația încorporată, pregătește infrastructura neutră a monstrului și definește un ham de test local. Stage 1 nu conținea defecte legacy sau patch-uri; Stage 2 introduce exclusiv restul istoric.

## Reguli de independență

Codul activ este derivat din specificația originală și din baza J Stage 1 acceptată. Documentația unei alte linii a fost consultată în timpul căutării istorice, dar nu este sursa codului sau testelor. Nu s-au copiat teste, fixture-uri, rezultate așteptate, tabele generate, urme sau hash-uri de la o altă linie. Referința normativă din `test/normative_reference.ijs` este scrisă pentru această linie exclusiv din specificația Stage 1.

## Rulare

Din rădăcina proiectului, cu un runtime J 9.7.x, finalizarea Stage 1 se face printr-o singură comandă:

```text
jconsole test/complete_stage01.ijs
```

Runnerul generează `test/stage01_fixtures.tsv`, execută suita locală și actualizează `DEVELOPMENT_STAGE.md` numai după succes. Generatorul folosește numai referința normativă J din această linie. Pentru detalii, vedeți `HANDOFF_STAGE_01.md`.

## Precizie numerică

Toate calculele normative folosesc întregi extinși J (`x`) și, unde este necesară o împărțire intermediară, operatori exacți care păstrează domeniul întreg/rational. Nu se folosește aritmetică în virgulă mobilă pentru decizii normative.

## Starea dezvoltării

Vezi `DEVELOPMENT_STAGE.md`. Stage 1 și Stage 2 DISCOVERY 01 sunt acceptate; următoarea etapă este Stage 3 PATCH 01.

## Realiniere canonica Stage 2

Dupa auditul specificatiei originale, istoricul anterior este conservat la commit 842f6044b2689f20b39a28afad56be5da23c893e. Nu se ruleaza din nou v16/v17. Pentru noul DISCOVERY 01 se ruleaza separat generatorul de fixtures Stage 1, testele Stage 1 si test/stage02_discovery01_tests.ijs cu J9.7.1. Nu se foloseste complete_stage01.ijs, deoarece acesta rescrie starea etapei. Se cer trei RED normative si un control GREEN, cu martori si regresii GREEN. Stage 2 acceptat nativ: 63/63 regresii, 18/18 martori, trei RED intenționate și un control GREEN. Vezi DEVELOPMENT_STAGE.md. PATCH 01 nu este încă implementat.
