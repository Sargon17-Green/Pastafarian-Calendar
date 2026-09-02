# SourceLanguageCatalog v1 - English

This catalog is frozen at Stage 1. Canonical ordering is determined only by `canonicalIndex`. English strings never participate in ranking, unranking, cache keys, combinatorial ordering, selection, or any other normative decision.

## Translation and transliteration rule

Literal semantic names are translated by meaning into natural English. Established historical place names use their conventional English forms. Invented sound strings without a semantic meaning use a deterministic readable transliteration: consonants follow their ordinary modern Hebrew sound values, `sh` represents the shin sound, and written vowel marks are represented by the closest simple English vowel spelling. This rule is used only for names identified by the embedded source as invented or non-semantic; it is never used in place of semantic translation.

The two invented source strings in this catalog are frozen as `Palgurash` and `Karshumav`. Established place names are frozen as `Lagash`, `Akkad`, `Eridu`, `Uruk`, `Nineveh`, and `Babylon`.

## Cutlet names

| canonicalIndex | English source string |
| ---: | --- |
| 1 | Bronze |
| 2 | Fox |
| 3 | Kidney |
| 4 | Lagash |
| 5 | Thought |
| 6 | Four Parts of Nine |
| 7 | Palgurash |
| 8 | Papyrus Sedge |
| 9 | Cluster |
| 10 | Scorpion |
| 11 | Ash |
| 12 | Wheat |
| 13 | River |
| 14 | Laughter |
| 15 | Akkad |
| 16 | Horn |
| 17 | The Empty Jar |

## Month names

| canonicalIndex | English source string |
| ---: | --- |
| 1 | Clay |
| 2 | Pomegranate |
| 3 | Elbow |
| 4 | Envy |
| 5 | Eridu |
| 6 | Toothpaste |
| 7 | Three Parts of Five |
| 8 | Karshumav |
| 9 | Tiger |
| 10 | Tin |
| 11 | Fog |
| 12 | Frankincense |
| 13 | Spindle |
| 14 | Rib |
| 15 | Carob |
| 16 | Uruk |
| 17 | Shame |
| 18 | Camel |
| 19 | Copper |
| 20 | Well |
| 21 | Yolk |
| 22 | Star |
| 23 | Honey |
| 24 | Spleen |
| 25 | Limestone |
| 26 | Joy |
| 27 | Fig |
| 28 | Nineveh |
| 29 | Frog |
| 30 | Tar |
| 31 | Candle |
| 32 | The Closed Door |
| 33 | Sesame |
| 34 | Nape |
| 35 | Silver |
| 36 | Lily |
| 37 | Storm |
| 38 | Donkey |
| 39 | Flour |
| 40 | Regret |
| 41 | Babylon |
| 42 | Tongue |
| 43 | Flax |
| 44 | Salt |
| 45 | Pear |
| 46 | Bow |
| 47 | Sand |

## Locale rule

Any future locale is presentation-only and must follow this direction:

```text
canonical semantics -> canonicalIndex -> English source string -> locale translation
```

A locale string must never be used to recover or reorder canonical semantics.
