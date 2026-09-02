# SourceLanguageCatalog — română, versiunea 1

Catalogul este sursa unică de prezentare pentru cele 17 nume de chiftele și cele 47 de nume de luni. Fiecărui element îi corespunde un `canonicalIndex` fix, numerotat de la 1 în ordinea specificației.

## Regulă semantică

Un nume cu sens lexical este tradus în română după sens. Un nume de loc sau un nume propriu folosește forma românească consacrată atunci când există. Un nume inventat sau un șir fonetic fără sens este transliterat determinist; pentru sunetul redat prin litera ebraică șin se folosește `ș`, iar vocalele sunt păstrate cât mai direct după forma dată de specificație.

Formele inventate înghețate în această versiune sunt `Palguraș` și `Karșumab`. Formele consacrate folosite pentru toponime sunt `Lagaș`, `Akkad`, `Eridu`, `Uruk`, `Ninive` și `Babilon`.

## Interdicție de collation semantic

Textul românesc nu este sortat pentru a decide sensul. Nicio operație normativă nu depinde de ordinea alfabetică românească, Unicode, case-folding sau locale collation. `canonicalIndex` este singura ordine normativă.

## Înghețare

Catalogul este înghețat după Stage 1. O schimbare ulterioară necesită o modificare explicită a specificației.
