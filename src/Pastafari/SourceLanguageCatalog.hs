module Pastafari.SourceLanguageCatalog
  ( CatalogEntry(..)
  , cutletCatalog
  , monthCatalog
  , cutletNameByIndex
  , monthNameByIndex
  , catalogFrozenVersion
  ) where

import Data.List (find)

data CatalogEntry = CatalogEntry
  { canonicalIndex :: Int
  , czechText :: String
  } deriving (Eq, Ord, Show)

catalogFrozenVersion :: String
catalogFrozenVersion = "cs-stage01-v1"

cutletCatalog :: [CatalogEntry]
cutletCatalog =
  [ CatalogEntry 1 "bronz"
  , CatalogEntry 2 "liška"
  , CatalogEntry 3 "ledvina"
  , CatalogEntry 4 "Lagaš"
  , CatalogEntry 5 "myšlenka"
  , CatalogEntry 6 "čtyři devítiny"
  , CatalogEntry 7 "Palguraš"
  , CatalogEntry 8 "šáchor"
  , CatalogEntry 9 "hrozen"
  , CatalogEntry 10 "štír"
  , CatalogEntry 11 "popel"
  , CatalogEntry 12 "pšenice"
  , CatalogEntry 13 "řeka"
  , CatalogEntry 14 "smích"
  , CatalogEntry 15 "Akkad"
  , CatalogEntry 16 "roh"
  , CatalogEntry 17 "prázdný džbán"
  ]

monthCatalog :: [CatalogEntry]
monthCatalog =
  [ CatalogEntry 1 "jíl"
  , CatalogEntry 2 "granátové jablko"
  , CatalogEntry 3 "loket"
  , CatalogEntry 4 "závist"
  , CatalogEntry 5 "Eridu"
  , CatalogEntry 6 "zubní pasta"
  , CatalogEntry 7 "tři pětiny"
  , CatalogEntry 8 "Karšumav"
  , CatalogEntry 9 "tygr"
  , CatalogEntry 10 "cín"
  , CatalogEntry 11 "mlha"
  , CatalogEntry 12 "kadidlo"
  , CatalogEntry 13 "vřeteno"
  , CatalogEntry 14 "žebro"
  , CatalogEntry 15 "karob"
  , CatalogEntry 16 "Uruk"
  , CatalogEntry 17 "stud"
  , CatalogEntry 18 "velbloud"
  , CatalogEntry 19 "měď"
  , CatalogEntry 20 "studna"
  , CatalogEntry 21 "žloutek"
  , CatalogEntry 22 "hvězda"
  , CatalogEntry 23 "med"
  , CatalogEntry 24 "slezina"
  , CatalogEntry 25 "vápenec"
  , CatalogEntry 26 "radost"
  , CatalogEntry 27 "fík"
  , CatalogEntry 28 "Ninive"
  , CatalogEntry 29 "žába"
  , CatalogEntry 30 "dehet"
  , CatalogEntry 31 "svíčka"
  , CatalogEntry 32 "zavřené dveře"
  , CatalogEntry 33 "sezam"
  , CatalogEntry 34 "zátylek"
  , CatalogEntry 35 "stříbro"
  , CatalogEntry 36 "lilie"
  , CatalogEntry 37 "bouře"
  , CatalogEntry 38 "osel"
  , CatalogEntry 39 "mouka"
  , CatalogEntry 40 "lítost"
  , CatalogEntry 41 "Babylón"
  , CatalogEntry 42 "jazyk"
  , CatalogEntry 43 "len"
  , CatalogEntry 44 "sůl"
  , CatalogEntry 45 "hruška"
  , CatalogEntry 46 "luk"
  , CatalogEntry 47 "písek"
  ]

lookupName :: [CatalogEntry] -> Int -> Maybe String
lookupName entries idx = czechText <$> find ((== idx) . canonicalIndex) entries

cutletNameByIndex :: Int -> Maybe String
cutletNameByIndex = lookupName cutletCatalog

monthNameByIndex :: Int -> Maybe String
monthNameByIndex = lookupName monthCatalog
