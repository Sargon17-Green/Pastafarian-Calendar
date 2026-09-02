module Pastafari.SourceLanguageCatalog exposing
    ( CatalogEntry
    , cutletEntries
    , cutletName
    , monthEntries
    , monthName
    , version
    )


type alias CatalogEntry =
    { canonicalIndex : Int
    , sourceId : String
    , text : String
    }


version : String
version =
    "1.0.0"


cutletEntries : List CatalogEntry
cutletEntries =
    [ { canonicalIndex = 1, sourceId = "BRONZE", text = "brons" }
    , { canonicalIndex = 2, sourceId = "FOX", text = "refur" }
    , { canonicalIndex = 3, sourceId = "KIDNEY", text = "nýra" }
    , { canonicalIndex = 4, sourceId = "LARCH", text = "lerki" }
    , { canonicalIndex = 5, sourceId = "THOUGHT", text = "hugsun" }
    , { canonicalIndex = 6, sourceId = "FOUR_NINTHS", text = "fjórir níundu hlutar" }
    , { canonicalIndex = 7, sourceId = "PALGURASH", text = "Palgúrasj" }
    , { canonicalIndex = 8, sourceId = "SEDGE", text = "sef" }
    , { canonicalIndex = 9, sourceId = "CLUSTER", text = "klasi" }
    , { canonicalIndex = 10, sourceId = "SCORPION", text = "sporðdreki" }
    , { canonicalIndex = 11, sourceId = "ASH", text = "aska" }
    , { canonicalIndex = 12, sourceId = "WHEAT", text = "hveiti" }
    , { canonicalIndex = 13, sourceId = "RIVER", text = "á" }
    , { canonicalIndex = 14, sourceId = "LAUGHTER", text = "hlátur" }
    , { canonicalIndex = 15, sourceId = "AKKAD", text = "Akkad" }
    , { canonicalIndex = 16, sourceId = "HORN", text = "horn" }
    , { canonicalIndex = 17, sourceId = "EMPTY_JUG", text = "tóma kannan" }
    ]


monthEntries : List CatalogEntry
monthEntries =
    [ { canonicalIndex = 1, sourceId = "CLAY", text = "leir" }
    , { canonicalIndex = 2, sourceId = "POMEGRANATE", text = "granatepli" }
    , { canonicalIndex = 3, sourceId = "ELBOW", text = "olnbogi" }
    , { canonicalIndex = 4, sourceId = "ENVY", text = "öfund" }
    , { canonicalIndex = 5, sourceId = "ERIDU", text = "Erídú" }
    , { canonicalIndex = 6, sourceId = "TOOTHPASTE", text = "tannkrem" }
    , { canonicalIndex = 7, sourceId = "THREE_FIFTHS", text = "þrír fimmtu hlutar" }
    , { canonicalIndex = 8, sourceId = "KARSHUMAB", text = "Karsjúmab" }
    , { canonicalIndex = 9, sourceId = "TIGER", text = "tígrisdýr" }
    , { canonicalIndex = 10, sourceId = "TIN", text = "tin" }
    , { canonicalIndex = 11, sourceId = "FOG", text = "þoka" }
    , { canonicalIndex = 12, sourceId = "FRANKINCENSE", text = "reykelsi" }
    , { canonicalIndex = 13, sourceId = "SPINDLE", text = "snælda" }
    , { canonicalIndex = 14, sourceId = "RIB", text = "rif" }
    , { canonicalIndex = 15, sourceId = "CAROB", text = "jóhannesarbrauð" }
    , { canonicalIndex = 16, sourceId = "URUK", text = "Úrúk" }
    , { canonicalIndex = 17, sourceId = "SHAME", text = "skömm" }
    , { canonicalIndex = 18, sourceId = "CAMEL", text = "úlfaldi" }
    , { canonicalIndex = 19, sourceId = "COPPER", text = "kopar" }
    , { canonicalIndex = 20, sourceId = "WELL", text = "brunnur" }
    , { canonicalIndex = 21, sourceId = "YOLK", text = "eggjarauða" }
    , { canonicalIndex = 22, sourceId = "STAR", text = "stjarna" }
    , { canonicalIndex = 23, sourceId = "HONEY", text = "hunang" }
    , { canonicalIndex = 24, sourceId = "SPLEEN", text = "milta" }
    , { canonicalIndex = 25, sourceId = "LIMESTONE", text = "kalksteinn" }
    , { canonicalIndex = 26, sourceId = "JOY", text = "gleði" }
    , { canonicalIndex = 27, sourceId = "FIG", text = "fíkja" }
    , { canonicalIndex = 28, sourceId = "NINEVEH", text = "Níníve" }
    , { canonicalIndex = 29, sourceId = "FROG", text = "froskur" }
    , { canonicalIndex = 30, sourceId = "TAR", text = "tjara" }
    , { canonicalIndex = 31, sourceId = "CANDLE", text = "kerti" }
    , { canonicalIndex = 32, sourceId = "CLOSED_DOOR", text = "lokaða hurðin" }
    , { canonicalIndex = 33, sourceId = "SESAME", text = "sesam" }
    , { canonicalIndex = 34, sourceId = "NAPE", text = "hnakki" }
    , { canonicalIndex = 35, sourceId = "SILVER", text = "silfur" }
    , { canonicalIndex = 36, sourceId = "LILY", text = "lilja" }
    , { canonicalIndex = 37, sourceId = "STORM", text = "stormur" }
    , { canonicalIndex = 38, sourceId = "DONKEY", text = "asni" }
    , { canonicalIndex = 39, sourceId = "FLOUR", text = "mjöl" }
    , { canonicalIndex = 40, sourceId = "REGRET", text = "eftirsjá" }
    , { canonicalIndex = 41, sourceId = "BABYLON", text = "Babýlon" }
    , { canonicalIndex = 42, sourceId = "TONGUE", text = "tunga" }
    , { canonicalIndex = 43, sourceId = "FLAX", text = "hör" }
    , { canonicalIndex = 44, sourceId = "SALT", text = "salt" }
    , { canonicalIndex = 45, sourceId = "PEAR", text = "pera" }
    , { canonicalIndex = 46, sourceId = "BOW", text = "bogi" }
    , { canonicalIndex = 47, sourceId = "SAND", text = "sandur" }
    ]


cutletName : Int -> Maybe String
cutletName canonicalIndex =
    resolve canonicalIndex cutletEntries


monthName : Int -> Maybe String
monthName canonicalIndex =
    resolve canonicalIndex monthEntries


resolve : Int -> List CatalogEntry -> Maybe String
resolve canonicalIndex entries =
    entries
        |> List.filter (\entry -> entry.canonicalIndex == canonicalIndex)
        |> List.head
        |> Maybe.map .text
