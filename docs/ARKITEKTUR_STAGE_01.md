# Arkitektur efter etap 1

Produktionsdelen er bevidst lille på dette tidspunkt. Historisk kompleksitet må ikke foregribes.

Den neutrale grundstruktur består af en kaldsejet kontekst, en dispatcherregistrering, en validator, en fejlwrapper uden gendannelseslogik og en måleskal. Ingen af disse komponenter indeholder kalendersemantik eller en kommende historisk lap.

Det normative orakel ligger udelukkende under `test/`. Produktionskoden må ikke indlæse eller kalde det. Oraklet bruger præcise heltal, 1-baserede normative indeks og eksakte tællere for ordnede familier.

Den eneste mutable kalendercache i etap 1 findes inde i test-oraklet og bruges til portindeks. Den er ikke produktionstilstand. Produktionskonteksten oprettes på ny for hver kald og deles ikke mellem kald.
