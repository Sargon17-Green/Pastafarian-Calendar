# Stadio 55 — PATCH27: lunghezza normativa della cotoletta

**Stato:** contratto implementativo, in attesa di prova Native. La scoperta Stage54 e stata chiusa con 29 PASS e tre divergenze volute (CUTLET1/CUTLET3/CUTLET6) su SHA 67664926189b71847e3c578a1000770a7e83d3fe, run 41126590506 (55/55 jobs). Non e un difetto preesistente provato: il legacy di Stage54 fu introdotto come ipotesi diagnostica deliberatamente errata.

## Ingresso, uscita e norma

Ingresso: g=gateGaps di 6..47 elementi, ogni g[i] in 42..963; p=cutletPartition di 6..17 gruppi positivi, sum(p)=|g|; somma dei giorni 252..5778; c da 1 a |p|. Calcolo e target day sono BigInt da preservare. I gruppi sono contigui e 1-based per l'identificazione esterna.

La grandezza normativa e L(c)=sum(g[k]) per k nel gruppo c, con firstGate=sum(p[1..c-1]). Il legacy separato rimane oldCutletSpan(c)=g[c]. Non modificare il catalogo e le cinque componenti del calendario; nessun dato di altro ramo o oracolo di produzione.

Uscita: report immutabile con legacySpan, correctedSpan, dati sorgente, flag, fase, stato e trace. Bootstrap -> DISCOVERY_27_CUTLET_SPAN -> PATCH_27_CUTLET_SPAN; il validator ricalcola indipendentemente aggregando ogni gruppo tramite un cursore, senza chiamare wrapper o oracolo test-only. Errore di input: IllegalArgumentException incapsulato in WrappedMonsterError; errore di stato: IllegalStateException. Non pubblicare campi patch parziali dopo mutazione.

## Esempi e criteri verificabili

g=Vector.fill(9)(42); p=(2,1,2,1,1,2). Risultati normativi per c=1..6: (84,42,84,42,42,84); legacy (42,42,42,42,42,42). Copertura test: sei vettori, estremi 252/5778, fino a 47 gate e 17 cutlet, 2048 partizioni seminate con oracle distinto, invarianti di somma e assenza di mutation, rifiuto degli input invalidi, validator falsificato, metriche isolate, snapshot BigInt, regressione Stage53 e Stage54.

Native: eseguire la nuova job stage55-patch e tutte le precedenti sullo stesso nuovo SHA, verify/Names Lock inclusi. PASS dello Stage55 soltanto con 0 FAIL, conteggio dichiarato effettivamente coincidente e workflow completamente successful. Non dichiarare il programma completo soltanto in base a test statici, run queued o successo Stage54 precedente. Niente merge main.
