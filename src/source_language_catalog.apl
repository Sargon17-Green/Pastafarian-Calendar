⍝ Quellsprachkatalog Deutsch, Version 1. Nach Stufe 1 unveränderlich.
⍝ Die Position ist der canonicalIndex. Textsortierung ist semantisch verboten.

∇ SourceLanguageCatalogInit
  ⎕IO←1
  SOURCE_LANGUAGE_CATALOG_VERSION←1
  SOURCE_LANGUAGE_CATALOG_FROZEN←1
  CUTLET_NAMES←'Bronze' 'Fuchs' 'Niere' 'Lagasch' 'Gedanke' 'Vier Neuntel' 'Palgurasch' 'Binse' 'Traube' 'Skorpion' 'Asche' 'Weizen' 'Fluss' 'Lachen' 'Akkad' 'Horn' 'Der leere Krug'
  MONTH_NAMES←'Ton' 'Granatapfel' 'Ellenbogen' 'Neid' 'Eridu' 'Zahnpasta' 'Drei Fünftel' 'Karschumav' 'Leopard' 'Zinn' 'Nebel' 'Weihrauch' 'Spindel' 'Rippe' 'Johannisbrot' 'Uruk' 'Scham' 'Kamel' 'Kupfer' 'Brunnen' 'Eigelb' 'Stern' 'Honig' 'Milz' 'Kalkstein' 'Freude' 'Feige' 'Ninive' 'Frosch' 'Teer' 'Kerze' 'Die geschlossene Tür' 'Sesam' 'Nacken' 'Silber' 'Lilie' 'Sturm' 'Esel' 'Mehl' 'Reue' 'Babylon' 'Zunge' 'Flachs' 'Salz' 'Birne' 'Bogen' 'Sand'
  CUTLET_CANONICAL_INDEX←⍳17
  MONTH_CANONICAL_INDEX←⍳47
∇

∇ z←SourceLanguageCatalogSnapshot
  z←(⊂SOURCE_LANGUAGE_CATALOG_VERSION),(⊂SOURCE_LANGUAGE_CATALOG_FROZEN),(⊂CUTLET_CANONICAL_INDEX),(⊂MONTH_CANONICAL_INDEX),(⊂CUTLET_NAMES),(⊂MONTH_NAMES)
∇

∇ z←SourceLanguageCatalogValidateCandidate candidate;version;frozen;cutletIndex;monthIndex;cutletNames;monthNames
  :If 6≠⍴candidate ⋄ z←0 ⋄ :Return ⋄ :EndIf
  version←⊃candidate[1] ⋄ frozen←⊃candidate[2]
  cutletIndex←⊃candidate[3] ⋄ monthIndex←⊃candidate[4]
  cutletNames←⊃candidate[5] ⋄ monthNames←⊃candidate[6]
  z←1
  :If version≠1 ⋄ z←0 ⋄ :Return ⋄ :EndIf
  :If frozen≠1 ⋄ z←0 ⋄ :Return ⋄ :EndIf
  :If ~cutletIndex≡⍳17 ⋄ z←0 ⋄ :Return ⋄ :EndIf
  :If ~monthIndex≡⍳47 ⋄ z←0 ⋄ :Return ⋄ :EndIf
  :If ~cutletNames≡'Bronze' 'Fuchs' 'Niere' 'Lagasch' 'Gedanke' 'Vier Neuntel' 'Palgurasch' 'Binse' 'Traube' 'Skorpion' 'Asche' 'Weizen' 'Fluss' 'Lachen' 'Akkad' 'Horn' 'Der leere Krug' ⋄ z←0 ⋄ :Return ⋄ :EndIf
  :If ~monthNames≡'Ton' 'Granatapfel' 'Ellenbogen' 'Neid' 'Eridu' 'Zahnpasta' 'Drei Fünftel' 'Karschumav' 'Leopard' 'Zinn' 'Nebel' 'Weihrauch' 'Spindel' 'Rippe' 'Johannisbrot' 'Uruk' 'Scham' 'Kamel' 'Kupfer' 'Brunnen' 'Eigelb' 'Stern' 'Honig' 'Milz' 'Kalkstein' 'Freude' 'Feige' 'Ninive' 'Frosch' 'Teer' 'Kerze' 'Die geschlossene Tür' 'Sesam' 'Nacken' 'Silber' 'Lilie' 'Sturm' 'Esel' 'Mehl' 'Reue' 'Babylon' 'Zunge' 'Flachs' 'Salz' 'Birne' 'Bogen' 'Sand' ⋄ z←0 ⋄ :Return ⋄ :EndIf
∇

∇ z←SourceLanguageCatalogValidate;snapshot
  snapshot←SourceLanguageCatalogSnapshot
  z←SourceLanguageCatalogValidateCandidate snapshot
∇

∇ z←CutletNameByIndex i
  :If ~SourceLanguageCatalogValidate ⋄ ⎕ERROR 'Ungültiger oder veränderter deutscher Quellsprachkatalog.' ⋄ :EndIf
  :If (i<1)∨i>17 ⋄ ⎕ERROR 'Ungültiger oder veränderter deutscher Quellsprachkatalog.' ⋄ :EndIf
  z←⊃CUTLET_NAMES[i]
∇

∇ z←MonthNameByIndex i
  :If ~SourceLanguageCatalogValidate ⋄ ⎕ERROR 'Ungültiger oder veränderter deutscher Quellsprachkatalog.' ⋄ :EndIf
  :If (i<1)∨i>47 ⋄ ⎕ERROR 'Ungültiger oder veränderter deutscher Quellsprachkatalog.' ⋄ :EndIf
  z←⊃MONTH_NAMES[i]
∇
