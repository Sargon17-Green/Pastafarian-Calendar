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

## Stage 2 — DISCOVERY 01 (in curs)

A fost introdusa o noua cale de productie J independenta pentru cinci valori de lucru: eticheta zilei de calcul, eticheta zilei tinta, distanta inclusiva, suma si directia. Rezultatul ramane doar in semanticPending din context, iar API-ul de calendar continua sa declare NOT_INTEGRATED: nu exista inca cele cinci componente finale de data.

Testele Stage 2 sunt separate de cele 63 de verificari Stage 1 si au valori asteptate explicite, inclusiv directie inversa, traversarea fundatiei si numere intregi extinse. Nu exista import de oracle in productie. Etapa ramane neacceptata pana la probe native.
