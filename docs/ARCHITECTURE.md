# Arkitektur i Bootstrap

Trinn 1 etablerer bare et minimum av nøytral monsterinfrastruktur.

`MonsterContext` tilhører nøyaktig én påkalling. Semantiske mellomresultater som senere legges til, skal eies av denne konteksten eller av eksplisitt frosne tabeller. Observasjonsdata er adskilt fra semantiske data og kan ikke brukes som beslutningsgrunnlag.

`BaseDispatcher` kjenner bare generelle Bootstrap-faser. Den har ingen kunnskap om legacy-feil, lappenumre, kompatibilitetsmodi eller fremtidige snarveier.

`ValidationBoundary` kan avvise en ugyldig grunnkontekst, men kan ikke normalisere eller erstatte et normativt resultat. `MetricsShell` og `LogShell` er observasjonelle beholdere; innholdet deres leses aldri av den normative referansen.

Den normative referansen er testkode og er fysisk skilt fra produksjonsskallet. Produksjonskoden kan ikke kalle referansen som fallback.
