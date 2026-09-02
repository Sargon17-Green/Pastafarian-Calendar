namespace PastafariLean

structure CatalogEntry where
  canonicalIndex : Nat
  sourceText : String
  deriving Repr, BEq

structure SourceLanguageCatalog where
  version : Nat
  languageTag : String
  languageName : String
  cutlets : Array CatalogEntry
  months : Array CatalogEntry
  frozen : Bool
  deriving Repr

private def indexed (xs : Array String) : Array CatalogEntry := Id.run do
  let mut out := #[]
  for i in [0:xs.size] do
    out := out.push { canonicalIndex := i + 1, sourceText := xs[i]! }
  return out

private def cutletTexts : Array String := #[
  "bronse",
  "rev",
  "nyre",
  "Lagash",
  "tanke",
  "fire deler av ni",
  "Palgurasj",
  "siv",
  "klase",
  "skorpion",
  "aske",
  "hvete",
  "elv",
  "latter",
  "Akkad",
  "horn",
  "den tomme krukken"
]

private def monthTexts : Array String := #[
  "leire",
  "granateple",
  "albue",
  "misunnelse",
  "Eridu",
  "tannkrem",
  "tre deler av fem",
  "Karsjumab",
  "leopard",
  "tinn",
  "tåke",
  "virak",
  "håndtein",
  "ribbein",
  "johannesbrød",
  "Uruk",
  "skam",
  "kamel",
  "kobber",
  "brønn",
  "eggeplomme",
  "stjerne",
  "honning",
  "milt",
  "kalkstein",
  "glede",
  "fiken",
  "Ninive",
  "frosk",
  "tjære",
  "lys",
  "den lukkede døren",
  "sesam",
  "nakke",
  "sølv",
  "lilje",
  "storm",
  "esel",
  "mel",
  "anger",
  "Babylon",
  "tunge",
  "lin",
  "salt",
  "pære",
  "bue",
  "sand"
]

def sourceLanguageCatalog : SourceLanguageCatalog := {
  version := 1
  languageTag := "nb"
  languageName := "norsk bokmål"
  cutlets := indexed cutletTexts
  months := indexed monthTexts
  frozen := true
}

def lookupCatalogEntry (entries : Array CatalogEntry) (canonicalIndex : Nat) : Option CatalogEntry :=
  if canonicalIndex == 0 || canonicalIndex > entries.size then
    none
  else
    some entries[canonicalIndex - 1]!

def cutletNameByCanonicalIndex (canonicalIndex : Nat) : Option String :=
  match lookupCatalogEntry sourceLanguageCatalog.cutlets canonicalIndex with
  | some e => some e.sourceText
  | none => none

def monthNameByCanonicalIndex (canonicalIndex : Nat) : Option String :=
  match lookupCatalogEntry sourceLanguageCatalog.months canonicalIndex with
  | some e => some e.sourceText
  | none => none

def catalogIndicesAreStable (entries : Array CatalogEntry) : Bool := Id.run do
  let mut ok := true
  for i in [0:entries.size] do
    if entries[i]!.canonicalIndex != i + 1 then
      ok := false
  return ok

def sourceLanguageCatalogIsValid : Bool :=
  sourceLanguageCatalog.version == 1 &&
  sourceLanguageCatalog.languageTag == "nb" &&
  sourceLanguageCatalog.languageName == "norsk bokmål" &&
  sourceLanguageCatalog.frozen &&
  sourceLanguageCatalog.cutlets.size == 17 &&
  sourceLanguageCatalog.months.size == 47 &&
  catalogIndicesAreStable sourceLanguageCatalog.cutlets &&
  catalogIndicesAreStable sourceLanguageCatalog.months

end PastafariLean
