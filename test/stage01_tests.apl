⍝ Stage-1-Testgerüst. Alle Meldungen sind deutsch; alle Berechnungen laufen in APL.

∇ AssertEqual args;expected;actual;label
  expected←⊃args[1] ⋄ actual←⊃args[2] ⋄ label←⊃args[3]
  :If ~expected≡actual
      ⎕←'FEHLER: ',label
      ⎕←'Erwartet:' ⋄ ⎕←expected
      ⎕←'Tatsächlich:' ⋄ ⎕←actual
      ⎕SIGNAL 11
  :EndIf
∇

∇ AssertTrue args;condition;label
  condition←⊃args[1] ⋄ label←⊃args[2]
  :If ~condition
      ⎕←'FEHLER: ',label
      ⎕SIGNAL 11
  :EndIf
∇

∇ RunStage01Tests;counts;ctx1;ctx2;s1;s2;stream;wcount;w1;w2
  SourceLanguageCatalogInit
  OracleInit

  AssertEqual (⊂1) (⊂SOURCE_LANGUAGE_CATALOG_VERSION) (⊂'Der Quellsprachkatalog trägt die feste Version eins')
  AssertEqual (⊂1) (⊂SOURCE_LANGUAGE_CATALOG_FROZEN) (⊂'Der Quellsprachkatalog ist in Stage 1 eingefroren')
  AssertEqual (⊂17) (⊂⍴CUTLET_NAMES) (⊂'Der Schnitzelkatalog enthält genau 17 Namen')
  AssertEqual (⊂47) (⊂⍴MONTH_NAMES) (⊂'Der Monatskatalog enthält genau 47 Namen')
  AssertEqual (⊂⍳17) (⊂CUTLET_CANONICAL_INDEX) (⊂'Die Schnitzelindizes sind unverändert 1 bis 17')
  AssertEqual (⊂⍳47) (⊂MONTH_CANONICAL_INDEX) (⊂'Die Monatsindizes sind unverändert 1 bis 47')
  AssertEqual (⊂'Weizen') (⊂CutletNameByIndex 12) (⊂'Die Bedeutung Weizen ist wirklich deutsch übersetzt')
  AssertEqual (⊂'Drei Fünftel') (⊂MonthNameByIndex 7) (⊂'Der Bruchname ist als deutscher Gesamtausdruck übersetzt')
  AssertEqual (⊂'Palgurasch') (⊂CutletNameByIndex 7) (⊂'Der Kunstname folgt der eingefrorenen deutschen Umschrift')

  AssertEqual (⊂M) (⊂Save M) (⊂'SAVE einer exakten Vielfachen von M ergibt M')
  AssertEqual (⊂M) (⊂Save 2×M) (⊂'SAVE von 2M ergibt M')
  AssertEqual (⊂1x) (⊂Save M+1) (⊂'SAVE von M plus eins ergibt eins')

  AssertEqual (⊂1) (⊂DayCount FOUNDATION_DAY) (⊂'Der Gründungstag hat Tageszählung eins')
  AssertEqual (⊂3) (⊂DayCount FOUNDATION_DAY+1) (⊂'Der Tag nach der Gründung hat ungerade Zählung drei')
  AssertEqual (⊂2) (⊂DayCount FOUNDATION_DAY-1) (⊂'Der Tag vor der Gründung hat gerade Zählung zwei')

  counts←FOUNDATION_DAY WorkCounts FOUNDATION_DAY
  AssertEqual (⊂1) (⊂counts[3]) (⊂'Gleiche Tage haben Distanz eins')
  AssertEqual (⊂2) (⊂counts[5]) (⊂'Gleiche Tage haben Richtung zwei')

  AssertEqual (⊂378x 1073x 2375x 6195x 10493x) (⊂STONES[2;]) (⊂'Alle fünf zweiten Steine stammen aus demselben alten Snapshot')

  AssertEqual (⊂1 2 3 4 5 6) (⊂PermutationUnrank1 1) (⊂'Permutationsrang eins ist die aufsteigende Ordnung')
  AssertEqual (⊂6 5 4 3 2 1) (⊂PermutationUnrank1 720) (⊂'Permutationsrang 720 ist die absteigende Ordnung')

  stream←1x 1
  AssertEqual (⊂1x) (⊂stream ChooseRank 10x) (⊂'Kurze Auswahl mit erster Antwort eins wählt Rang eins')
  AssertEqual (⊂1x) (⊂stream ChooseRank M) (⊂'Kurze Auswahl funktioniert am Rand N gleich M')

  AssertEqual (⊂1x) (⊂BoundedCount 12 3 4 4) (⊂'Die einzige 4-4-4-Komposition wird exakt gezählt')
  AssertEqual (⊂4 4 4) (⊂BoundedUnrank 12 3 4 4 1) (⊂'Die 4-4-4-Komposition wird lexikographisch geöffnet')
  AssertEqual (⊂1 2 3) (⊂17 UnrankDistinct 3 1) (⊂'Der erste Rang verschiedener Namen beginnt mit 1 2 3')

  wcount←WeavingCount 1 1 1
  AssertEqual (⊂1x) (⊂wcount) (⊂'Drei einfache Monatsfäden haben genau eine zulässige Webung')
  w1←WeavingUnrank (⊂1 1 1) 1
  AssertEqual (⊂1 2 3) (⊂w1) (⊂'Die einfache Webung ist 1 2 3')
  wcount←WeavingCount 2 2
  AssertEqual (⊂2x) (⊂wcount) (⊂'Zwei Fäden mit Länge zwei besitzen genau zwei zulässige Webungen')

  s1←FOUNDATION_DAY Sauce FOUNDATION_DAY
  s2←FOUNDATION_DAY Sauce FOUNDATION_DAY
  AssertTrue (⊂s1≡s2) (⊂'Der normative Sauce-Lauf ist deterministisch')
  AssertEqual (⊂6) (⊂⍴⊃s1[1]) (⊂'Der Sauce-Lauf endet mit genau sechs Schüsseln')
  AssertEqual (⊂6) (⊂⍴⊃s1[2]) (⊂'Der Sauce-Lauf bewahrt genau die Ordnung von Tropfen 46')

  ctx1←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY
  ctx2←FOUNDATION_DAY MonsterNewContext FOUNDATION_DAY+1
  AssertTrue (⊂MonsterBaseValidate ctx1) (⊂'Der neutrale Basiskontext ist gültig')
  ctx1←MonsterBaseExecute ctx1
  AssertEqual (⊂'BOOTSTRAP_OK') (⊂⊃ctx1[6]) (⊂'Der neutrale Dispatcher erreicht den Bootstrap-Endzustand')
  AssertTrue (⊂~ctx1≡ctx2) (⊂'Zwei Aufrufe besitzen getrennte Kontextwerte')

  ⎕←'STAGE01 PASS'
∇
