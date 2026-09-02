module Pastafari.SourceLanguageCatalog
  ( CatalogEntry
  , cutletCatalog
  , monthCatalog
  , cutletNameByCanonicalIndex
  , monthNameByCanonicalIndex
  , catalogVersion
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe)

catalogVersion :: String
catalogVersion = "ne-NP-source-v1"

type CatalogEntry =
  { canonicalIndex :: Int
  , sourceText :: String
  }

cutletCatalog :: Array CatalogEntry
cutletCatalog =
  [ { canonicalIndex: 1, sourceText: "काँस्य" }
  , { canonicalIndex: 2, sourceText: "स्याल" }
  , { canonicalIndex: 3, sourceText: "मिर्गौला" }
  , { canonicalIndex: 4, sourceText: "लगश" }
  , { canonicalIndex: 5, sourceText: "विचार" }
  , { canonicalIndex: 6, sourceText: "नौमध्ये चार भाग" }
  , { canonicalIndex: 7, sourceText: "पल्गुराश" }
  , { canonicalIndex: 8, sourceText: "नर्कट" }
  , { canonicalIndex: 9, sourceText: "गुच्छा" }
  , { canonicalIndex: 10, sourceText: "बिच्छी" }
  , { canonicalIndex: 11, sourceText: "खरानी" }
  , { canonicalIndex: 12, sourceText: "गहुँ" }
  , { canonicalIndex: 13, sourceText: "नदी" }
  , { canonicalIndex: 14, sourceText: "हाँसो" }
  , { canonicalIndex: 15, sourceText: "अक्काद" }
  , { canonicalIndex: 16, sourceText: "सिङ" }
  , { canonicalIndex: 17, sourceText: "खाली घडा" }
  ]

monthCatalog :: Array CatalogEntry
monthCatalog =
  [ { canonicalIndex: 1, sourceText: "माटो" }
  , { canonicalIndex: 2, sourceText: "अनार" }
  , { canonicalIndex: 3, sourceText: "कुहिनो" }
  , { canonicalIndex: 4, sourceText: "ईर्ष्या" }
  , { canonicalIndex: 5, sourceText: "एरिडु" }
  , { canonicalIndex: 6, sourceText: "दन्तमञ्जन" }
  , { canonicalIndex: 7, sourceText: "पाँचमध्ये तीन भाग" }
  , { canonicalIndex: 8, sourceText: "कर्शुमाब" }
  , { canonicalIndex: 9, sourceText: "बाघ" }
  , { canonicalIndex: 10, sourceText: "टिन" }
  , { canonicalIndex: 11, sourceText: "कुहिरो" }
  , { canonicalIndex: 12, sourceText: "लोबान" }
  , { canonicalIndex: 13, sourceText: "तकुवा" }
  , { canonicalIndex: 14, sourceText: "करङ" }
  , { canonicalIndex: 15, sourceText: "क्यारोब" }
  , { canonicalIndex: 16, sourceText: "उरुक" }
  , { canonicalIndex: 17, sourceText: "लाज" }
  , { canonicalIndex: 18, sourceText: "ऊँट" }
  , { canonicalIndex: 19, sourceText: "तामा" }
  , { canonicalIndex: 20, sourceText: "इनार" }
  , { canonicalIndex: 21, sourceText: "अण्डाको पहेँलो भाग" }
  , { canonicalIndex: 22, sourceText: "तारा" }
  , { canonicalIndex: 23, sourceText: "मह" }
  , { canonicalIndex: 24, sourceText: "प्लीहा" }
  , { canonicalIndex: 25, sourceText: "चुनढुङ्गा" }
  , { canonicalIndex: 26, sourceText: "आनन्द" }
  , { canonicalIndex: 27, sourceText: "अञ्जिर" }
  , { canonicalIndex: 28, sourceText: "निनवे" }
  , { canonicalIndex: 29, sourceText: "भ्यागुतो" }
  , { canonicalIndex: 30, sourceText: "अलकत्रा" }
  , { canonicalIndex: 31, sourceText: "मैनबत्ती" }
  , { canonicalIndex: 32, sourceText: "बन्द ढोका" }
  , { canonicalIndex: 33, sourceText: "तिल" }
  , { canonicalIndex: 34, sourceText: "गर्दनको पछाडिको भाग" }
  , { canonicalIndex: 35, sourceText: "चाँदी" }
  , { canonicalIndex: 36, sourceText: "लिली" }
  , { canonicalIndex: 37, sourceText: "आँधी" }
  , { canonicalIndex: 38, sourceText: "गधा" }
  , { canonicalIndex: 39, sourceText: "पीठो" }
  , { canonicalIndex: 40, sourceText: "पछुतो" }
  , { canonicalIndex: 41, sourceText: "बेबिलोन" }
  , { canonicalIndex: 42, sourceText: "जिब्रो" }
  , { canonicalIndex: 43, sourceText: "सन" }
  , { canonicalIndex: 44, sourceText: "नुन" }
  , { canonicalIndex: 45, sourceText: "नासपाती" }
  , { canonicalIndex: 46, sourceText: "धनुष" }
  , { canonicalIndex: 47, sourceText: "बालुवा" }
  ]

cutletNameByCanonicalIndex :: Int -> Maybe String
cutletNameByCanonicalIndex i = _.sourceText <$> Array.find (\x -> x.canonicalIndex == i) cutletCatalog

monthNameByCanonicalIndex :: Int -> Maybe String
monthNameByCanonicalIndex i = _.sourceText <$> Array.find (\x -> x.canonicalIndex == i) monthCatalog
