⍝ Quellsprachkatalog Deutsch, Version 1. Nach Stage 1 unveränderlich.
⍝ Die Position ist der canonicalIndex. Textsortierung ist semantisch verboten.

∇ SourceLanguageCatalogInit
  SOURCE_LANGUAGE_CATALOG_VERSION←1
  SOURCE_LANGUAGE_CATALOG_FROZEN←1
  CUTLET_NAMES←'Bronze' 'Fuchs' 'Niere' 'Lagasch' 'Gedanke' 'Vier Neuntel' 'Palgurasch' 'Binse' 'Traube' 'Skorpion' 'Asche' 'Weizen' 'Fluss' 'Lachen' 'Akkad' 'Horn' 'Der leere Krug'
  MONTH_NAMES←'Ton' 'Granatapfel' 'Ellenbogen' 'Neid' 'Eridu' 'Zahnpasta' 'Drei Fünftel' 'Karschumab' 'Leopard' 'Zinn' 'Nebel' 'Weihrauch' 'Spindel' 'Rippe' 'Johannisbrot' 'Uruk' 'Scham' 'Kamel' 'Kupfer' 'Brunnen' 'Eigelb' 'Stern' 'Honig' 'Milz' 'Kalkstein' 'Freude' 'Feige' 'Ninive' 'Frosch' 'Teer' 'Kerze' 'Die geschlossene Tür' 'Sesam' 'Nacken' 'Silber' 'Lilie' 'Sturm' 'Esel' 'Mehl' 'Reue' 'Babylon' 'Zunge' 'Flachs' 'Salz' 'Birne' 'Bogen' 'Sand'
  CUTLET_CANONICAL_INDEX←⍳17
  MONTH_CANONICAL_INDEX←⍳47
∇

∇ z←CutletNameByIndex i
  z←⊃CUTLET_NAMES[i]
∇

∇ z←MonthNameByIndex i
  z←⊃MONTH_NAMES[i]
∇
