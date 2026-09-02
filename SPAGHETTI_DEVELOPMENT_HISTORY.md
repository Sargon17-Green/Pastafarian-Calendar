# Historie vývoje špagetového monstra

## Fáze 1 — zavedení

Byl vytvořen nový prázdný implementační strom pro Haskell a češtinu. V této fázi ještě nebyla zavedena žádná historická chybná domněnka a nebyla přidána žádná záplata z pozdějších fází.

Vznikla pouze obecná infrastruktura: základní kontext jednoho volání, neutrální dispečer, validátor vstupu, obal deterministické chyby a nesémantický sběrač metrik. Tyto vrstvy nemění normativní výsledek, protože produkční normativní cesta ještě není aktivní a žádná z těchto vrstev nečte observabilní stav jako sémantický vstup.

Normativní reference byla zapsána samostatně v Haskellu jako testovací zdroj pravdy pro tuto větev. Produkční kostra ji nevolá a neimportuje.
