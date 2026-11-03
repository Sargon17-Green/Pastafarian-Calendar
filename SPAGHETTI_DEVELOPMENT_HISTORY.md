# Istoria dezvoltarii monstrului spaghetti

## Stage 1 - Bootstrap - acceptat

### Starea initiala

Nimic. Linia J + romana a fost pornita intr-un arbore gol, exclusiv din specificatia furnizata pentru aceasta linie.

### Ce s-a construit

S-au introdus numai mecanisme generale, neutre: un context de invocare, un dispatcher de faze, un validator de baza, un invelis determinist pentru erori, un registru de metrici si jurnalizare ne-semantica. Niciunul nu contine cunoastere despre defectele legacy sau despre patch-urile 01-26.

S-a creat si referinta normativa de test in J, separata de scheletul de productie. Referinta nu este disponibila ca fallback pentru productie.

### Catalogul de limba-sursa

Catalogul romanesc este inghetat in Stage 1. Ordinea semantica este definita exclusiv de `canonicalIndex`; textul romanesc nu participa la sortare, rank, unrank, cache-uri semantice sau selectii.

### Stratul de monstru

Stratul adaugat este intentionat modest si neutru: context + dispatcher + validator + error wrapper + metrici. El este observational sau structural si nu schimba niciun rezultat normativ.

## Stage 2 - DISCOVERY 01 - acceptat

A fost introdusa o cale de productie J independenta pentru cinci valori de lucru: eticheta zilei de calcul, eticheta zilei tinta, distanta inclusiva, suma si directia. Rezultatul ramane doar in `semanticPending` din context, iar API-ul de calendar continua sa declare `NOT_INTEGRATED`: cele cinci componente finale de data nu exista inca.

Testele Stage 2 sunt separate de cele 63 de verificari Stage 1 si au valori asteptate explicite, inclusiv directie inversa, traversarea fundatiei si numere intregi extinse. Nu exista import de oracle in productie. Stage 2 a fost acceptat prin executie nativa J9.7.1 pe Windows: Stage 1 63/63, Stage 2 17/17, exit code 0, manifest 26/26 si 19/19 Git blobs verificate.

## Stage 3 - PATCH 01 - acceptat

Revizuirea independenta a codului Stage 2 a identificat un defect de reprezentare: validatorul accepta intrari rational exacte a caror valoare este intreaga, dar calculele mixte pastreaza/promoveaza tipul rational (128). Astfel, cele cinci valori de lucru pot fi rational in loc de extended integer (64), desi valorile lor sunt intregi exacte.

PATCH 01 canonizeaza fiecare zi dupa validare: `2 x:` extrage numaratorul si numitorul ca extended integers, numitorul este verificat ca 1, iar ziua este stocata ca extended integer in context si in calculele de productie. Formulele Stage 2 nu se schimba. Referinta normativa ramane test-only, iar calea publica ramane `NOT_INTEGRATED`.

Noua suita `test/stage03_patch01_tests.ijs` acopera tipul fixture-ului, rezultatele inainte/inapoi/aceeasi zi, un rational intreg mare, tipul 64 pentru rezultate si zilele din context, respingerea fractiilor si pastrarea `NOT_INTEGRATED`. Stage 3 a fost acceptat prin Windows Native J9.7.1: manifest 29/29, Stage 1 63/63, Stage 2 17/17, Stage 3 11/11, exit 0.

## Stage 4 - DISCOVERY 02 - implementat, nu acceptat

Primitiva exacta SAVE pentru stari de sauce foloseste modulul M=2^127-1 si da valori in 1..M, inclusiv pentru zero, negative, multipli M si rationali integrali. Helperul stage04SaveCounts reduce doar vectori de cinci valori de lucru; nu modifica public calendar date, care ramane NOT_INTEGRATED. Suita Stage4 are 24 de verificari. Executia Windows Native J9.7.1 nu a avut inca loc; LAST_COMPLETED_STAGE=3. Fara main/merge/publicare.
