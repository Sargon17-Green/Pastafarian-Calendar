# Kalaallisut source-language audit — Stage 1

## Scope and authority

All 64 names derive from the locked meanings and indexes in
`catalog/NORMATIVE_NAME_WITNESS.csv` (the original Scroll's sections
T/W at `main@56bc4173aae4975ded019ef5ab5a36249f1424df`).

The `catalog_review_queue.csv` contains **research suggestions only**.
The normative Maltese witness is a review aid, never the displayed
source-language catalog. An independent Kalaallisut-qualified reviewer
must approve the final spelling and meaning before any index is
locked. A dictionary entry alone is not sufficient.

## Lexical research dossier, 2026-10-22

| Index | Canonical meaning | Proposed Kalaallisut | Source | Needed review |
|---|---|---|---|---|
| cutlet 1 | Bronze | `bronze` | [Greenlandic noun entry](https://kaikki.org/dictionary/All%20languages%20combined/meaning/b/br/bronze.html) | Borrowed from Danish; verify register, natural use as metal rather than color, and Greenlandic orthography |
| month 39 | Flour | `qajuusat` | [English–Greenlandic dictionary translation](https://kaikki.org/dictionary/English/meaning/f/fl/flour.html) | Verify flour as ingredient and the native plural/mass-noun use |
| cutlet 2 | Fox | `terianniaq` | [Wiktionary](https://en.wiktionary.org/wiki/terianniaq) | Has Arctic-fox specificity; is this the natural unqualified general name in Kalaallisut? |
| cutlet 13 | River | `kuuk` | [Greenlandic dictionary extraction](https://kaikki.org/dictionary/All%20languages%20combined/meaning/k/ku/kuuk.html) | Confirm native standalone nominative usage |
| cutlet 16 | Horn | `nassuk` | [Greenlandic noun senses](https://kaikki.org/dictionary/Greenlandic/pos-noun/nasaq--nittaalaq.html) | Includes antler; confirm whether canonical horn broadly includes other kinds |
| month 22 | Star | `ulloriaq` | [Dictionary extraction](https://kaikki.org/dictionary/Greenlandic/meaning/u/ul/ulloriaq.html) | Confirm common noun and spelling; distinguished from stellar proper nouns |
| month 44 | Salt | `taratsut` | [Greenlandic noun sense](https://kaikki.org/dictionary/Greenlandic/meaning/t/ta/taratsut.html) | Plural-only; confirm natural label. `tarajoq` is *salt water* and must not be substituted; `tarajuaqqat` is specifically *table salt* |
| month 47 | Sand | `sioqqat` | [Greenlandic Russian-dictionary extraction](https://kaikki.org/ruwiktionary/All%20languages%20combined/meaning/s/si/sioqqat.html) | Verify plural/mass noun, orthography, and acceptability with a native-language source |

## Review protocol, per name

1. Verify the locked semantic index and exact meaning; do not infer
   order from spelling or Unicode collation.
2. Consult the [University of Chicago and Oqaasileriffik
   2018 Greenlandic–English dictionary](https://daka.gl/2018-kal-eng/)
   and the [Oqaasileriffik resources](https://oqaasileriffik.gl/en/resources/).
   Look for the actual term and morphological analyses, not only a
   search-engine snippet.
3. Check lexical scope (animal species, material noun, physiological
   or anatomical horn, salt vs salt water), count and word class.
4. Check orthographic acceptability and Unicode NFC. Use a consistent
   transliteration protocol for invented names and an explicit policy
   for ancient place names.
5. Fractions cutlet 6 (4/9) and month 7 (3/5) must be **full natural
   Kalaallisut names**, not bare Arabic-digit fractions.
6. Record source references, reviewer identity or qualified audit
   attestation, review decision and exact UTF-8 string. Do not mark
   `APPROVED` with any evidence field missing.
7. Once all 64 are approved, check no unintended collisions, save a
   canonical UTF-8 catalog, compute its SHA-256, and freeze the
   indexed strings. Presentation locales may subsequently vary,
   but algorithmic ranks must never depend on text.

**Current state:** 8 proposed strings; 0/64 approved; no catalog freeze;
Stage 1 remains IN_PROGRESS. The present dossier has not undergone
native-language quality assurance.
