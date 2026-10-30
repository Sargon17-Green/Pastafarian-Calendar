# Stadio 54 — DISCOVERY27: lunghezza della cotoletta aggregata

**Stato:** contratto di ricerca, non implementazione né risultato Native. Baseline verificata: `78d89ca31ebc1b1d4401ae688c1288ddb27d30d5`; Stage53/PATCH26 chiuso. Autorizzazione alla definizione autonoma del contratto: 2026-10-30. Non modificare `main`.

## Motivazione indipendente
La regola già codificata in `Patch26GateToCutletProjection.scala` è che una cotoletta comprende uno o più gate consecutivi secondo `cutletPartition`. L'ordinalità locale del giorno è stata corretta in Stage53. Qui si verifica **un'altra grandezza**: la lunghezza totale della cotoletta.

Dati `gaps = g[1..G]`, `partition = p[1..C]`, `sum(p)=G`, per una cotoletta `c` (indicizzazione 1-based) definire:
`start(c)=sum(p[1..c-1])`;
`L(c)=sum(g[start(c)+1..start(c)+p[c]])`.

**Ipotesi legacy diagnostica da introdurre soltanto nello stadio di scoperta:** `oldCutletSpan(c)=g[c]`, ovvero una porta per cotoletta. È un modello deliberatamente errato da sperimentare, **non un bug preesistente dimostrato**. Non alterare il risultato `Patch26` né il catalogo canonico.

## Vettori controllabili a mano
`gaps = Vector.fill(9)(42)`, `partition=Vector(2,1,2,1,1,2)` (378 giorni).
Per cotolette 1..6 l'oracolo indipendente dà `[84,42,84,42,42,84]`; legacy `[42,42,42,42,42,42]`.
EXPECTED_RED **soltanto** su c=1,3,6; controlli verdi c=2,4,5.
Calcolo indipendente del contratto: 6/6 valori confermati con somma per sottovettori, 3 disaccordi previsti. Questo **non è** un esito di Scala Native.

## Lavoro richiesto
1. Predisporre un adapter legacy isolato e un report `DISCOVERY_27` che passa per il dispatch/validator esistente; mantenere intatta la cicatrice di Stage52 e il risultato PATCH26.
2. Scrivere un oracolo test-only distinto dal codice legacy; usare i sei vettori sopra, bordi di ogni cotoletta, 2048 partizioni seminate entro 6..47 gate, 6..17 cotolette e anno 252..5778 giorni, inclusi istanti ai limiti del range.
3. Dimostrare rifiuto di input invalidi, snapshot intatto, nessuna scrittura di risultati futuri e regressioni Stage53.
4. Eseguire Scala Native + verifica nomi sullo **stesso nuovo SHA**. L'EXPECTED_RED è accettato solo se i tre fallimenti sono quelli normativi previsti, senza errori di compilatione, formato o regressione; registrare esattamente test count e job conclusion senza dichiarare genericamente SUCCESS.
5. Solo dopo questa evidenza chiudere Stage54 come EXPECTED_RED. NON introdurre PATCH27 o Stage55 anticipatamente.

## Vincoli di onestà
Se l'implementazione mostra semantica o integrazione incompatibili, fermarsi, documentare la controprova e correggere il contratto prima di procedere. Il presente documento autorizza il lavoro di Stage54, ma **non certifica** un difetto reale di codice né un CI PASS.
