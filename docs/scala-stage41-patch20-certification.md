# Stage41 — PATCH20: confine iniziale della cotoletta

**Lingua di programmazione:** Scala 2.13.18. **Lingua naturale:** Italiano.

## Regola corretta

Per un vettore di durate dei varchi `gaps` (ciascuno 42..963),
una partizione positiva in 6..17 cotolette e un offset del giorno
`d` nell'anno, siano `start(i)` gli inizi cumulativi zero-based.

```text
cutletId(d) = max { i | start(i) <= d }  [ID 1-based]
dayInCutlet(d) = d - start(cutletId(d)) + 1
```

Il giorno esattamente uguale a `start(i)` appartiene quindi alla
nuova cotoletta. L'errore storico della DISCOVERY20 usa la
disuguaglianza stretta `d > start(i)`. Il wrapper
`Patch20CutletOpenBoundaryWrapper.cutletBoundaryPatch` invoca
il vecchio adapter e conserva integralmente la sua risposta nel
rapporto, insieme alla risposta corretta.

## Integrazione e validazione

Il manager attraversa BOOT, DISCOVERY20 e PATCH20 nella stessa
richiesta. Lo snapshot degli input, la trace, lo stato, il flag di
patch e le metriche sono verificati. Il validator indipendente non
richiama l'implementazione della patch o l'oracolo dei test:
ricostruisce la durata di ogni cotoletta sommando gli intervalli
dei varchi e ricalcola il risultato storico e quello corretto.

La suite `src/test/scala/pastafari/Stage41Tests.scala` comprende
56 verifiche: tutti i giorni delle durate 252, 714 e 5778,
4096 prove casuali deterministiche sul wrapper e 4096 su due
manager indipendenti, richieste ripetute, BigInt, input errati,
manomissioni e assenza di pubblicazione dopo un fallimento.

## Evidenze Native

| Oggetto | Evidenza |
| --- | --- |
| Commit di implementazione | `a7da3ccfafa89ed2ae5122ffebb6873e4902e13c` |
| Commit rafforzamento test | `cdb881ff165be86b68918f149b5aa9052a19160e` |
| CI implementazione | https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39602548231 |
| CI test rafforzati | https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39602625776 |
| Esito | 42/42 lavori SUCCESS in entrambe le run |
| Stage41 | 56 PASS, 0 FAIL |
| Stage40 storico | 44 PASS, 3 FAIL intenzionali |

La scelta della partizione e degli intervalli è un input
diagnostico già determinato, non il calcolo annuale reale
a partire dalla salsa. La verifica tra implementazioni
(soak) e il rilascio rimangono compiti separati. Nessun
cambiamento al catalogo congelato e nessuna modifica a main.
