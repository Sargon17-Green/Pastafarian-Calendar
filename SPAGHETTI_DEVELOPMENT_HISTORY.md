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

Specificația independentă originală, 06-implementation-prompt.md, 2026-08-26, fixează succesiunea DISCOVERY 01/PATCH 01. Ipoteza veche este că modulo obișnuit este SAVE; la M, 2M și 3M rezultă zero în loc de M, iar la M+1 rezultatul coincide. Producția păstrează restVechi, dispecerRestVechi și ruta calendarSalvareSpaghete; contextul public observă rezultatul, fără a pretinde integrarea datei. Nu există corecția PATCH 01. Aserțiunile normative sunt separate și se cer trei RED exacte și un control GREEN. Execuția nativă rămâne NOT_RUN.

Istoricul anterior, inclusiv rezultatul nativ v17 (115/115), este păstrat integral prin părintele 842f6044b2689f20b39a28afad56be5da23c893e. Baza canonică activă este Stage 1 acceptat, 7c23a7e46b521adf2b52c42987366fb17aa901ee. Acceptarea istorică a rezultatelor nu este anulată; conformitatea ordinală a etapelor 2–4 a fost infirmată de specificație. Nu se introduc etape viitoare.
