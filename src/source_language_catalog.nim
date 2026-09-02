type
  CatalogEntry* = object
    canonicalIndex*: int
    text*: string

const
  SourceLanguageCatalogVersion* = "hu-1"

  CutletCatalog* = [
    CatalogEntry(canonicalIndex: 1, text: "bronz"),
    CatalogEntry(canonicalIndex: 2, text: "róka"),
    CatalogEntry(canonicalIndex: 3, text: "vese"),
    CatalogEntry(canonicalIndex: 4, text: "Lákis"),
    CatalogEntry(canonicalIndex: 5, text: "gondolat"),
    CatalogEntry(canonicalIndex: 6, text: "négy kilenced"),
    CatalogEntry(canonicalIndex: 7, text: "Palguras"),
    CatalogEntry(canonicalIndex: 8, text: "sás"),
    CatalogEntry(canonicalIndex: 9, text: "fürt"),
    CatalogEntry(canonicalIndex: 10, text: "skorpió"),
    CatalogEntry(canonicalIndex: 11, text: "hamu"),
    CatalogEntry(canonicalIndex: 12, text: "búza"),
    CatalogEntry(canonicalIndex: 13, text: "folyó"),
    CatalogEntry(canonicalIndex: 14, text: "nevetés"),
    CatalogEntry(canonicalIndex: 15, text: "Akkád"),
    CatalogEntry(canonicalIndex: 16, text: "szarv"),
    CatalogEntry(canonicalIndex: 17, text: "az üres korsó")
  ]

  MonthCatalog* = [
    CatalogEntry(canonicalIndex: 1, text: "agyag"),
    CatalogEntry(canonicalIndex: 2, text: "gránátalma"),
    CatalogEntry(canonicalIndex: 3, text: "könyök"),
    CatalogEntry(canonicalIndex: 4, text: "irigység"),
    CatalogEntry(canonicalIndex: 5, text: "Eridu"),
    CatalogEntry(canonicalIndex: 6, text: "fogkrém"),
    CatalogEntry(canonicalIndex: 7, text: "háromötöd"),
    CatalogEntry(canonicalIndex: 8, text: "Karsumab"),
    CatalogEntry(canonicalIndex: 9, text: "leopárd"),
    CatalogEntry(canonicalIndex: 10, text: "ón"),
    CatalogEntry(canonicalIndex: 11, text: "köd"),
    CatalogEntry(canonicalIndex: 12, text: "tömjén"),
    CatalogEntry(canonicalIndex: 13, text: "orsó"),
    CatalogEntry(canonicalIndex: 14, text: "borda"),
    CatalogEntry(canonicalIndex: 15, text: "szentjánoskenyér"),
    CatalogEntry(canonicalIndex: 16, text: "Uruk"),
    CatalogEntry(canonicalIndex: 17, text: "szégyen"),
    CatalogEntry(canonicalIndex: 18, text: "teve"),
    CatalogEntry(canonicalIndex: 19, text: "réz"),
    CatalogEntry(canonicalIndex: 20, text: "kút"),
    CatalogEntry(canonicalIndex: 21, text: "tojássárgája"),
    CatalogEntry(canonicalIndex: 22, text: "csillag"),
    CatalogEntry(canonicalIndex: 23, text: "méz"),
    CatalogEntry(canonicalIndex: 24, text: "lép"),
    CatalogEntry(canonicalIndex: 25, text: "mészkő"),
    CatalogEntry(canonicalIndex: 26, text: "öröm"),
    CatalogEntry(canonicalIndex: 27, text: "füge"),
    CatalogEntry(canonicalIndex: 28, text: "Ninive"),
    CatalogEntry(canonicalIndex: 29, text: "béka"),
    CatalogEntry(canonicalIndex: 30, text: "kátrány"),
    CatalogEntry(canonicalIndex: 31, text: "gyertya"),
    CatalogEntry(canonicalIndex: 32, text: "a zárt ajtó"),
    CatalogEntry(canonicalIndex: 33, text: "szezám"),
    CatalogEntry(canonicalIndex: 34, text: "tarkó"),
    CatalogEntry(canonicalIndex: 35, text: "ezüst"),
    CatalogEntry(canonicalIndex: 36, text: "liliom"),
    CatalogEntry(canonicalIndex: 37, text: "vihar"),
    CatalogEntry(canonicalIndex: 38, text: "szamár"),
    CatalogEntry(canonicalIndex: 39, text: "liszt"),
    CatalogEntry(canonicalIndex: 40, text: "megbánás"),
    CatalogEntry(canonicalIndex: 41, text: "Babilon"),
    CatalogEntry(canonicalIndex: 42, text: "nyelv"),
    CatalogEntry(canonicalIndex: 43, text: "len"),
    CatalogEntry(canonicalIndex: 44, text: "só"),
    CatalogEntry(canonicalIndex: 45, text: "körte"),
    CatalogEntry(canonicalIndex: 46, text: "íj"),
    CatalogEntry(canonicalIndex: 47, text: "homok")
  ]

proc cutletText*(canonicalIndex: int): string =
  if canonicalIndex < 1 or canonicalIndex > CutletCatalog.len:
    raise newException(IndexDefect, "E_CUTLET_CATALOG_INDEX")
  CutletCatalog[canonicalIndex - 1].text

proc monthText*(canonicalIndex: int): string =
  if canonicalIndex < 1 or canonicalIndex > MonthCatalog.len:
    raise newException(IndexDefect, "E_MONTH_CATALOG_INDEX")
  MonthCatalog[canonicalIndex - 1].text
