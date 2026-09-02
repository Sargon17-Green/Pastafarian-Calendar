⍝ Testgerüst für Stufe 1. Alle Meldungen sind deutsch; alle Projektberechnungen laufen ausschließlich in APL.

∇ AssertEqual args;expected;actual;label
  expected←⊃args[1] ⋄ actual←⊃args[2] ⋄ label←⊃args[3]
  :If ~expected≡actual
      ⎕←'FEHLER: ',label
      ⎕←'Erwartet:' ⋄ ⎕←expected
      ⎕←'Tatsächlich:' ⋄ ⎕←actual
      ⎕ERROR 'Stufe-1-Test fehlgeschlagen.'
  :EndIf
∇

∇ AssertTrue args;condition;label
  condition←⊃args[1] ⋄ label←⊃args[2]
  :If ~condition
      ⎕←'FEHLER: ',label
      ⎕ERROR 'Stufe-1-Test fehlgeschlagen.'
  :EndIf
∇

∇ RunStage01OwnershipTests;ctxA0;ctxB0;a1;a2;a3;b1;b2;b3;retryBase;r0;r1;r2;rAfterFailure;quiet;noisy;initialSemantic;ec;tampered;semanticCopy
  ctxA0←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY+10
  ctxB0←(FOUNDATION_DAY+100) MonsterNewContext FOUNDATION_DAY+120

  AssertTrue (⊂MonsterBaseValidate ctxA0) (⊂'Der erste neutrale Aufrufskontext ist strukturell gültig')
  AssertTrue (⊂MonsterBaseValidate ctxB0) (⊂'Der zweite neutrale Aufrufskontext ist strukturell gültig')

  a1←MonsterBaseExecute ctxA0
  b1←MonsterBaseExecute ctxB0
  b2←MonsterBaseExecute ctxB0
  a2←MonsterBaseExecute ctxA0
  b3←MonsterBaseExecute ctxB0

  AssertEqual (⊂MonsterBaseSemanticState a1) (⊂MonsterBaseSemanticState a2) (⊂'Die semantische Ausgabe von Aufruf A hängt nicht davon ab, ob B dazwischen ausgeführt wurde')
  AssertEqual (⊂MonsterBaseSemanticState b1) (⊂MonsterBaseSemanticState b2) (⊂'Wiederholte Ausführung desselben Eingangs liefert denselben semantischen Zustand')
  AssertEqual (⊂MonsterBaseSemanticState b1) (⊂MonsterBaseSemanticState b3) (⊂'Auch die Reihenfolge B-A-B verändert den semantischen Zustand von B nicht')
  AssertEqual (⊂'NEW') (⊂⊃ctxA0[CTX_STATUS]) (⊂'Die Ausführung einer Kontextkopie verändert den ursprünglichen Kontext A nicht')
  AssertEqual (⊂'NEW') (⊂⊃ctxB0[CTX_STATUS]) (⊂'Die Ausführung von A verändert den noch nicht ausgeführten Kontext B nicht')
  AssertEqual (⊂2) (⊂⍴MonsterBaseSemanticState ctxB0) (⊂'Ein fremder Aufruf kann den bestätigten Zustand eines anderen Kontexts nicht erweitern')
  semanticCopy←MonsterBaseSemanticState a1
  semanticCopy[1]←semanticCopy[1]+999x
  AssertEqual (⊂FOUNDATION_DAY) (⊂(MonsterBaseSemanticState a1)[1]) (⊂'Eine veränderte Ergebniskopie kann nicht in den Kontext zurückschreiben')

  tampered←ctxA0
  tampered[CTX_CALCULATION_DAY]←⊂1.0
  AssertTrue (⊂~MonsterBaseValidate tampered) (⊂'Die Kontextvalidierung weist auch nachträglich eingeschleuste Gleitkommatage zurück')
  tampered←ctxA0
  tampered[CTX_COMMITTED]←⊂FOUNDATION_DAY (FOUNDATION_DAY+10) 999x 999x
  AssertTrue (⊂~MonsterBaseValidate tampered) (⊂'Ein verfälschter bestätigter Zustand wird vor weiterer Verarbeitung verworfen')
  tampered←ctxA0
  tampered[CTX_PENDING]←⊂FOUNDATION_DAY (FOUNDATION_DAY+10) 999x 999x
  AssertTrue (⊂~MonsterBaseValidate tampered) (⊂'Ein verfälschter ausstehender Zustand wird vor einer Bestätigung verworfen')
  tampered←ctxA0
  tampered[CTX_ROLLBACK]←⊂(FOUNDATION_DAY+1) (FOUNDATION_DAY+10)
  AssertTrue (⊂~MonsterBaseValidate tampered) (⊂'Eine Wiederherstellungskopie mit fremder Aufrufidentität wird verworfen')

  a3←MonsterBaseExecute a1
  AssertEqual (⊂MonsterBaseSemanticState a1) (⊂MonsterBaseSemanticState a3) (⊂'Eine erneute Ausführung eines bereits erfolgreichen Kontexts ändert dessen semantisches Ergebnis nicht')
  AssertTrue (⊂MonsterBasePendingIsEmpty a3) (⊂'Nach erfolgreicher Bestätigung bleibt kein ausstehender Zustand zurück')
  AssertTrue (⊂MonsterBaseRollbackIsEmpty a3) (⊂'Nach erfolgreicher Bestätigung bleibt keine Wiederherstellungskopie zurück')

  retryBase←(FOUNDATION_DAY-50) MonsterNewContext FOUNDATION_DAY+75
  initialSemantic←MonsterBaseSemanticState retryBase
  r0←retryBase MonsterBaseRunTransaction 0
  r1←retryBase MonsterBaseRunTransaction 1
  r2←retryBase MonsterBaseRunTransaction 2
  AssertEqual (⊂'NEW') (⊂⊃retryBase[CTX_STATUS]) (⊂'Wiederholungsversuche verändern den ursprünglichen Aufruferkontext nicht')
  AssertEqual (⊂initialSemantic) (⊂MonsterBaseSemanticState retryBase) (⊂'Wiederholungsversuche können vor einer Rückgabe keinen semantischen Zustand in den Aufrufer lecken')
  AssertEqual (⊂MonsterBaseSemanticState r0) (⊂MonsterBaseSemanticState r1) (⊂'Ein injizierter, wiederherstellbarer Fehler ändert das erfolgreiche semantische Ergebnis nicht')
  AssertEqual (⊂MonsterBaseSemanticState r0) (⊂MonsterBaseSemanticState r2) (⊂'Zwei injizierte, wiederherstellbare Fehler ändern das erfolgreiche semantische Ergebnis nicht')
  AssertEqual (⊂1) (⊂⊃r1[CTX_RECOVERY_DEPTH]) (⊂'Ein injizierter Fehler führt genau zu einer Wiederherstellung')
  AssertEqual (⊂2) (⊂⊃r2[CTX_RECOVERY_DEPTH]) (⊂'Zwei injizierte Fehler führen genau zu zwei Wiederherstellungen')
  AssertTrue (⊂MonsterBasePendingIsEmpty r2) (⊂'Auch nach erfolgreicher Wiederholung bleibt kein ausstehender Zustand zurück')
  AssertTrue (⊂MonsterBaseRollbackIsEmpty r2) (⊂'Auch nach erfolgreicher Wiederholung bleibt keine Wiederherstellungskopie zurück')

  ec←⎕EC 'retryBase MonsterBaseRunTransaction 3'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein überschrittenes Wiederholungsbudget wirft einen Fehler statt eine Ersatzantwort zu liefern')
  AssertEqual (⊂initialSemantic) (⊂MonsterBaseSemanticState retryBase) (⊂'Nach erschöpftem Wiederholungsbudget bleibt der zuletzt bestätigte Zustand des Aufrufers unverändert')
  AssertTrue (⊂MonsterBasePendingIsEmpty retryBase) (⊂'Ein fehlgeschlagener Wiederholungsversuch kann keinen ausstehenden Zustand in den Aufrufer lecken')
  AssertTrue (⊂MonsterBaseRollbackIsEmpty retryBase) (⊂'Ein fehlgeschlagener Wiederholungsversuch kann keine Wiederherstellungskopie in den Aufrufer lecken')
  rAfterFailure←MonsterBaseExecute retryBase
  AssertEqual (⊂MonsterBaseSemanticState r0) (⊂MonsterBaseSemanticState rAfterFailure) (⊂'Ein fehlgeschlagener Versuch vor einem erneuten Aufruf verändert das spätere erfolgreiche Ergebnis nicht')

  quiet←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY+33
  quiet[CTX_OBSERVATION_ENABLED]←⊂0
  quiet←MonsterBaseExecute quiet
  noisy←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY+33
  noisy[CTX_METRICS]←⊂987 654 321
  noisy[CTX_LOGS]←⊂,⊂'Vorbelegter Beobachtungszustand'
  noisy[CTX_BRANCH_TRACE]←⊂(⊂'Vorbelegte Spur')
  noisy[CTX_RECOVERY_DEPTH]←⊂77
  noisy←MonsterBaseExecute noisy
  AssertEqual (⊂MonsterBaseSemanticState quiet) (⊂MonsterBaseSemanticState noisy) (⊂'Vorbelegte Metriken und Protokolle sind keine semantischen Eingänge')

  ⎕←'BESITZTESTS PASS'
∇


∇ RunStage01OracleStateTests;positiveA;negativeA;positiveB;negativeB;sauceA1;sauceA2;sauceB;cutAfterFailure;weaveAfterFailure;ec;beforeGate
  GateReset
  AssertEqual (⊂,0) (⊂GATE_INDEX) (⊂'Ein zurückgesetzter Gate-Arbeitszustand enthält nur den Gründungsindex')
  AssertEqual (⊂,FOUNDATION_DAY) (⊂GATE_DAY) (⊂'Ein zurückgesetzter Gate-Arbeitszustand enthält nur den Gründungstag')
  ec←⎕EC 'GateGet 1'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein noch nicht erzeugter Gate-Index erzeugt einen Fehler statt eines kollidierenden Sentinelwerts')
  AssertEqual (⊂,0) (⊂GATE_INDEX) (⊂'Ein fehlgeschlagener Gate-Lesezugriff verändert den Gate-Arbeitszustand nicht')
  AssertEqual (⊂,FOUNDATION_DAY) (⊂GATE_DAY) (⊂'Ein fehlgeschlagener Gate-Lesezugriff verändert keinen gespeicherten Gate-Tag')

  EnsureGate 1
  positiveA←GateGet 1
  beforeGate←positiveA
  ec←⎕EC 'GatePut 1 (positiveA+1)'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein bereits erzeugter Gate-Index kann nicht mit einem abweichenden Wert überschrieben werden')
  AssertEqual (⊂beforeGate) (⊂GateGet 1) (⊂'Ein abgewiesener Gate-Überschreibungsversuch lässt den bestätigten Gate-Wert unverändert')
  EnsureGate ¯1
  negativeA←GateGet ¯1

  GateReset
  EnsureGate ¯1
  negativeB←GateGet ¯1
  EnsureGate 1
  positiveB←GateGet 1

  AssertEqual (⊂positiveA) (⊂positiveB) (⊂'Der positive Gate-Wert hängt nicht von der vorherigen Erzeugung der negativen Seite ab')
  AssertEqual (⊂negativeA) (⊂negativeB) (⊂'Der negative Gate-Wert hängt nicht von der vorherigen Erzeugung der positiven Seite ab')

  sauceA1←FOUNDATION_DAY Sauce FOUNDATION_DAY
  sauceB←(FOUNDATION_DAY+1) Sauce FOUNDATION_DAY-1
  sauceA2←FOUNDATION_DAY Sauce FOUNDATION_DAY
  AssertEqual (⊂sauceA1) (⊂sauceA2) (⊂'Ein anderer Sauce-Aufruf zwischen zwei gleichen Aufrufen verändert deren Ergebnis nicht')
  AssertTrue (⊂2=⍴sauceB) (⊂'Auch ein abweichender Sauce-Aufruf besitzt genau die beiden normativen Ergebnisbestandteile')

  ec←⎕EC 'CutletFamilyUnrank 6 3 2 5'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein erwarteter Schnitzel-DP-Fehler wird kontrolliert signalisiert')
  cutAfterFailure←CutletFamilyCount 6 3 2
  AssertEqual (⊂FIX_CUTLET_FILTERED_COUNT) (⊂cutAfterFailure) (⊂'Ein Schnitzel-DP-Fehler kann den nächsten unabhängigen DP-Aufruf nicht verunreinigen')

  ec←⎕EC 'WeavingUnrank (⊂1 1 1) 2'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein erwarteter Webungs-DP-Fehler wird kontrolliert signalisiert')
  weaveAfterFailure←WeavingCount 1 1 1
  AssertEqual (⊂FIX_WEAVING_111_COUNT) (⊂weaveAfterFailure) (⊂'Ein Webungs-DP-Fehler kann den nächsten unabhängigen DP-Aufruf nicht verunreinigen')

  ⎕←'REFERENZZUSTAND PASS'
∇

∇ RunStage01YearTests;anchor;anchorAgain;nextYear;previousYear;anchorLength;nextLength;previousLength
  GateReset
  anchor←Year5000 FOUNDATION_DAY
  AssertEqual (⊂5000x) (⊂anchor[1]) (⊂'Die Ankerjahresauswahl trägt die Jahresnummer 5000')
  AssertTrue (⊂(anchor[4]<FOUNDATION_DAY)∧FOUNDATION_DAY≤anchor[5]) (⊂'Das Ankerjahr enthält den Berechnungstag im offenen-geschlossenen Jahresintervall')
  anchorLength←anchor[5]-anchor[4]
  AssertTrue (⊂YearBoundsValid (anchor[3]-anchor[2]) anchorLength) (⊂'Das ausgewählte Ankerjahr erfüllt Gate- und Längengrenzen')
  EnsureGate 2+⌈/GATE_INDEX
  anchorAgain←Year5000 FOUNDATION_DAY
  AssertEqual (⊂anchor) (⊂anchorAgain) (⊂'Zusätzlich erzeugte, für die Auswahl irrelevante Gates verändern die Ankerjahresauswahl nicht')

  nextYear←FOUNDATION_DAY NextYear anchor
  AssertEqual (⊂5001x) (⊂nextYear[1]) (⊂'Der schrittweise Vorwärtsübergang erhöht die Jahresnummer genau um eins')
  AssertEqual (⊂anchor[3]) (⊂nextYear[2]) (⊂'Das nächste Jahr beginnt am Schließgate des Ankerjahres')
  nextLength←nextYear[5]-nextYear[4]
  AssertTrue (⊂YearBoundsValid (nextYear[3]-nextYear[2]) nextLength) (⊂'Auch das nächste Jahr erfüllt die normativen Jahresgrenzen')

  previousYear←FOUNDATION_DAY PreviousYear anchor
  AssertEqual (⊂4999x) (⊂previousYear[1]) (⊂'Der schrittweise Rückwärtsübergang vermindert die Jahresnummer genau um eins')
  AssertEqual (⊂anchor[2]) (⊂previousYear[3]) (⊂'Das vorherige Jahr endet am Öffnungsgate des Ankerjahres')
  previousLength←previousYear[5]-previousYear[4]
  AssertTrue (⊂YearBoundsValid (previousYear[3]-previousYear[2]) previousLength) (⊂'Auch das vorherige Jahr erfüllt die normativen Jahresgrenzen')
  GateReset
  ⎕←'JAHRESTESTS PASS'
∇

∇ RunStage01Tests;counts;ctx;s1;s2;stream;wcount;w1;cutCount1;cutCount2;cutCount3;catalogCopy;tamperedCatalog;tamperedNames;exact0;hidden;visible;bowls;pair;order46;fakeSauce;yearBounds;monthBounds;syntheticYear;syntheticCutlets;syntheticStructure;syntheticFinal;ec;i
  SourceLanguageCatalogInit
  MonsterBootstrapInit
  OracleInit
  Stage01FixturesInit

  AssertEqual (⊂1) (⊂SOURCE_LANGUAGE_CATALOG_VERSION) (⊂'Der Quellsprachkatalog trägt die feste Version eins')
  AssertEqual (⊂1) (⊂SOURCE_LANGUAGE_CATALOG_FROZEN) (⊂'Der Quellsprachkatalog ist in Stufe 1 eingefroren')
  AssertTrue (⊂SourceLanguageCatalogValidate) (⊂'Der eingefrorene Quellsprachkatalog stimmt byteunabhängig mit seiner kanonischen Definition überein')
  AssertEqual (⊂17) (⊂⍴CUTLET_NAMES) (⊂'Der Schnitzelkatalog enthält genau 17 Namen')
  AssertEqual (⊂47) (⊂⍴MONTH_NAMES) (⊂'Der Monatskatalog enthält genau 47 Namen')
  AssertEqual (⊂⍳17) (⊂CUTLET_CANONICAL_INDEX) (⊂'Die Schnitzelindizes sind unverändert 1 bis 17')
  AssertEqual (⊂⍳47) (⊂MONTH_CANONICAL_INDEX) (⊂'Die Monatsindizes sind unverändert 1 bis 47')
  AssertEqual (⊂'Weizen') (⊂CutletNameByIndex 12) (⊂'Die Bedeutung Weizen ist wirklich deutsch übersetzt')
  AssertEqual (⊂'Drei Fünftel') (⊂MonthNameByIndex 7) (⊂'Der Bruchname ist als deutscher Gesamtausdruck übersetzt')
  AssertEqual (⊂'Palgurasch') (⊂CutletNameByIndex 7) (⊂'Der Kunstname folgt der eingefrorenen deutschen Umschrift')
  AssertEqual (⊂'Karschumav') (⊂MonthNameByIndex 8) (⊂'Der zweite Kunstname bewahrt in der deutschen Umschrift den abschließenden v-Laut')
  :For i :In ⍳17
      AssertEqual (⊂⊃CUTLET_NAMES[i]) (⊂CutletNameByIndex i) (⊂'Jeder Schnitzel-canonicalIndex löst genau auf seinen eingefrorenen deutschen Quellnamen auf')
  :EndFor
  :For i :In ⍳47
      AssertEqual (⊂⊃MONTH_NAMES[i]) (⊂MonthNameByIndex i) (⊂'Jeder Monats-canonicalIndex löst genau auf seinen eingefrorenen deutschen Quellnamen auf')
  :EndFor
  catalogCopy←SourceLanguageCatalogSnapshot
  tamperedCatalog←catalogCopy
  tamperedNames←⊃tamperedCatalog[5]
  tamperedNames[1]←⊂'Manipulation'
  tamperedCatalog[5]←⊂tamperedNames
  AssertTrue (⊂~SourceLanguageCatalogValidateCandidate tamperedCatalog) (⊂'Eine veränderte Katalogkopie wird erkannt, ohne den eingefrorenen globalen Katalog zu mutieren')
  AssertTrue (⊂SourceLanguageCatalogValidate) (⊂'Der globale Quellsprachkatalog bleibt während der Negativprüfung unverändert gültig')

  ec←⎕EC 'OracleExactDay 1.0'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Die normative Referenz weist einen Gleitkommatag zurück')
  ec←⎕EC 'OracleExactDay 3 r 2'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Die normative Referenz weist einen gebrochenen Rationaltag zurück')
  ec←⎕EC 'MonsterExactDay 1.0'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Auch die Produktionsgrundlage weist einen Gleitkommatag zurück')

  AssertEqual (⊂M) (⊂Save M) (⊂'SAVE eines exakten Vielfachen von M ergibt M')
  AssertEqual (⊂M) (⊂Save 2×M) (⊂'SAVE von 2M ergibt M')
  AssertEqual (⊂1x) (⊂Save M+1) (⊂'SAVE von M plus eins ergibt eins')

  AssertEqual (⊂1x) (⊂DayCount FOUNDATION_DAY) (⊂'Der Gründungstag hat Tageszählung eins')
  AssertEqual (⊂3x) (⊂DayCount FOUNDATION_DAY+1) (⊂'Der Tag nach der Gründung hat ungerade Zählung drei')
  AssertEqual (⊂2x) (⊂DayCount FOUNDATION_DAY-1) (⊂'Der Tag vor der Gründung hat gerade Zählung zwei')

  counts←FOUNDATION_DAY WorkCounts FOUNDATION_DAY
  AssertEqual (⊂FIX_WORK_COUNTS_FOUNDATION) (⊂counts) (⊂'Die fünf Arbeitszählungen am Gründungstag entsprechen dem festen Prüfdatensatz')
  AssertEqual (⊂1x) (⊂counts[3]) (⊂'Gleiche Tage haben Distanz eins')
  AssertEqual (⊂2x) (⊂counts[5]) (⊂'Gleiche Tage haben Richtung zwei')

  AssertEqual (⊂FIX_STONE_ROW_2) (⊂STONES[2;]) (⊂'Alle fünf zweiten Steine stammen aus derselben alten Momentaufnahme')
  AssertEqual (⊂FIX_POST_STIR_A1_SUM) (⊂PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1) (⊂'Die A1-Lesart speichert Summe plus 149 mal Rührnummer als einen einzigen Wert')

  hidden←BuildHidden counts
  AssertEqual (⊂7) (⊂⍴hidden) (⊂'Die normative Referenz erzeugt genau sieben verborgene Tropfen')
  AssertTrue (⊂∧/(1≤hidden)∧hidden≤M) (⊂'Alle verborgenen Tropfen liegen im gespeicherten Bereich eins bis M')
  visible←counts BuildVisible hidden
  AssertEqual (⊂46) (⊂⍴visible) (⊂'Die normative Referenz erzeugt genau 46 sichtbare Tropfen')
  AssertTrue (⊂∧/(1≤visible)∧visible≤M) (⊂'Alle sichtbaren Tropfen liegen im gespeicherten Bereich eins bis M')
  bowls←InitialBowls counts
  pair←bowls ApplyVisible visible
  order46←⊃pair[2]
  AssertTrue (⊂(order46[⍋order46])≡⍳6) (⊂'Die gespeicherte Ordnung des 46. Tropfens ist eine vollständige Permutation der sechs Schüsseln')
  fakeSauce←(⊂1x 2x 3x 4x 5x 6x),(⊂6 2 4 1 5 3)
  AssertEqual (⊂6) (⊂fakeSauce NextBowlInDrop46Order 3) (⊂'Ist die abgefragte Schüssel zuletzt, wird die erste Schüssel derselben Tropfen-46-Ordnung als Nachfolger verwendet')

  AssertEqual (⊂FIX_PERMUTATION_FIRST) (⊂PermutationUnrank1 1) (⊂'Permutationsrang eins ist die aufsteigende Ordnung')
  AssertEqual (⊂FIX_PERMUTATION_LAST) (⊂PermutationUnrank1 720) (⊂'Permutationsrang 720 ist die absteigende Ordnung')
  ec←⎕EC 'PermutationUnrank1 0'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein Permutationsrang null wird ausdrücklich abgewiesen')
  AssertEqual (⊂FIX_FALLING_FACTORIAL_ZERO) (⊂FallingFactorial 17 0) (⊂'Eine partielle Permutation der Länge null besitzt exakt eine Möglichkeit')

  stream←1x 1
  AssertEqual (⊂1x) (⊂stream ChooseRank 10x) (⊂'Kurze Auswahl mit erster Antwort eins wählt Rang eins')
  AssertEqual (⊂1x) (⊂stream ChooseRank M) (⊂'Kurze Auswahl funktioniert am Rand N gleich M')
  AssertEqual (⊂M+1) (⊂stream ChooseRank M+1) (⊂'Breite Auswahl funktioniert unmittelbar oberhalb von M ohne Gleitkomma')
  stream←M 1
  AssertEqual (⊂1x) (⊂stream ChooseRank 10x) (⊂'Kurze Rejection schreitet im selben Antwortring weiter')
  stream←1x ¯1
  AssertEqual (⊂M) (⊂stream AnswerAt 1) (⊂'Rückwärtsrichtung umschließt den Antwortring exakt')

  AssertEqual (⊂1x) (⊂BoundedCount 12 3 4 4) (⊂'Die einzige 4-4-4-Komposition wird exakt gezählt')
  AssertEqual (⊂FIX_BOUNDED_444) (⊂BoundedUnrank 12 3 4 4 1) (⊂'Die 4-4-4-Komposition wird lexikographisch geöffnet')
  ec←⎕EC 'BoundedUnrank 12 3 4 4 2'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein Rang außerhalb der begrenzten Kompositionsfamilie wird abgewiesen')
  AssertEqual (⊂FIX_DISTINCT_FIRST_3) (⊂17 UnrankDistinct 3 1) (⊂'Der erste Rang verschiedener Namen beginnt mit 1 2 3')
  ec←⎕EC '17 UnrankDistinct 3 0'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein Rang null für verschiedene Namen wird abgewiesen')

  cutCount1←CutletFamilyCount 6 3 2
  cutCount2←CutletFamilyCount 6 3 0
  cutCount3←CutletFamilyCount 6 3 2
  AssertEqual (⊂FIX_CUTLET_FILTERED_COUNT) (⊂cutCount1) (⊂'Der gefilterte Schnitzel-DP zählt eine vorgeschriebene innere Grenze exakt')
  AssertEqual (⊂FIX_CUTLET_UNFILTERED_COUNT) (⊂cutCount2) (⊂'Ohne innere Grenze bleiben alle positiven Dreierkompositionen erhalten')
  AssertEqual (⊂cutCount1) (⊂cutCount3) (⊂'Ein anderer DP-Aufruf kann den späteren Schnitzelzählwert nicht verunreinigen')
  ec←⎕EC 'CutletFamilyUnrank 6 3 2 5'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein Rang außerhalb der gefilterten Schnitzelpartitionsfamilie wird abgewiesen')

  wcount←WeavingCount 1 1 1
  AssertEqual (⊂FIX_WEAVING_111_COUNT) (⊂wcount) (⊂'Drei einfache Monatsfäden haben genau eine zulässige Webung')
  w1←WeavingUnrank (⊂1 1 1) 1
  AssertEqual (⊂FIX_WEAVING_111) (⊂w1) (⊂'Die einfache Webung ist 1 2 3')
  wcount←WeavingCount 2 2
  AssertEqual (⊂FIX_WEAVING_22_COUNT) (⊂wcount) (⊂'Zwei Fäden mit Länge zwei besitzen genau zwei zulässige Webungen')
  w1←WeavingCount 1 1 1
  AssertEqual (⊂1x) (⊂w1) (⊂'Ein nachfolgender Webungs-DP beginnt mit eigenem Memo-Zustand')
  AssertEqual (⊂2x) (⊂WeavingCount 2 2) (⊂'Die Reihenfolge verschiedener Webungsaufrufe ändert keinen Zählwert')
  ec←⎕EC 'WeavingUnrank (⊂1 1 1) 2'
  AssertEqual (⊂0) (⊂ec[1]) (⊂'Ein Rang außerhalb der Webungsfamilie wird abgewiesen')

  GateReset
  exact0←ExactGateIndex FOUNDATION_DAY
  AssertEqual (⊂1 0) (⊂exact0) (⊂'Gate-Index null ist ein gültiger exakter Treffer und kein Abwesenheits-Sentinel')

  yearBounds←YearBoundsValid 6 252
  AssertEqual (⊂FIX_YEAR_BOUNDS_MIN) (⊂yearBounds) (⊂'Eine Jahreslänge von 252 Tagen mit sechs Gate-Abständen ist zulässig')
  yearBounds←YearBoundsValid 6 5778
  AssertEqual (⊂FIX_YEAR_BOUNDS_MAX) (⊂yearBounds) (⊂'Eine Jahreslänge von 5778 Tagen ist zulässig')
  yearBounds←YearBoundsValid 6 5779
  AssertEqual (⊂FIX_YEAR_BOUNDS_TOO_LONG) (⊂yearBounds) (⊂'Eine Jahreslänge von 5779 Tagen ist bereits unzulässig')
  AssertEqual (⊂0) (⊂YearBoundsValid 5 252) (⊂'Weniger als sechs Gate-Abstände können kein gültiges Jahr bilden')
  monthBounds←MonthCountBounds 252
  AssertEqual (⊂FIX_MONTH_BOUNDS_252) (⊂monthBounds) (⊂'Für 252 Jahrestage ergeben sich exakt die zulässigen Monatsanzahlgrenzen drei bis 47')

  syntheticYear←5000x 0 6 100x 106x
  syntheticCutlets←2 4⍴0x
  syntheticCutlets[1;]←0 3 101x 103x
  syntheticCutlets[2;]←3 6 104x 106x
  syntheticStructure←(⊂syntheticYear),(⊂3 3),(⊂1 12),(⊂syntheticCutlets),(⊂3 3),(⊂1 2 1 2 1 2),(⊂1 7)
  syntheticFinal←ResolveCalendarFields (⊂syntheticStructure),104x
  AssertEqual (⊂FIX_FINAL_SYNTHETIC) (⊂syntheticFinal) (⊂'Die Endauflösung liefert genau fünf Felder und zählt getrennte Monatsvorkommen einschließlich des Zieltags')

  s1←FOUNDATION_DAY Sauce FOUNDATION_DAY
  s2←FOUNDATION_DAY Sauce FOUNDATION_DAY
  AssertTrue (⊂s1≡s2) (⊂'Der normative Sauce-Lauf ist deterministisch')
  AssertEqual (⊂6) (⊂⍴⊃s1[1]) (⊂'Der Sauce-Lauf endet mit genau sechs Schüsseln')
  AssertEqual (⊂6) (⊂⍴⊃s1[2]) (⊂'Der Sauce-Lauf bewahrt genau die Ordnung von Tropfen 46')

  ctx←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY
  AssertTrue (⊂MonsterBaseValidate ctx) (⊂'Der neutrale Basiskontext ist gültig')
  ctx←MonsterBaseExecute ctx
  AssertEqual (⊂'BOOTSTRAP_OK') (⊂⊃ctx[CTX_STATUS]) (⊂'Der neutrale Dispatcher erreicht den Bootstrap-Endzustand')

  RunStage01OwnershipTests
  RunStage01OracleStateTests
  RunStage01YearTests

  ⎕←'STAGE01 PASS'
∇
