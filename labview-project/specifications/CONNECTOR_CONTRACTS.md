# Contratos de conetor per VIs de Bootstrap

## Conveni jeneral

Cada VI de matematica e oracle usa `error in` e `error out` en la cadeia normal. Inputs semantical no depende de error text, logs o metrics. Errors no cambia un resulta valida a un otra resulta.

## `CalendarDateNormative.vi`

Inputs:

- `calculationDay : BigInt`
- `targetDay : BigInt`
- `error in`

Outputs:

- `result : CalendarDateFive`
- `error out`

La output ave esata sinco campos: numero de anio, index de cutlet, dia en cutlet, index de mes, dia en mes. La resolve a strings elefen es separada.

## `SourceLanguageCatalog.vi`

Input:

- `kind : enum {CUTLET, MONTH}`
- `canonicalIndex : U16`

Output:

- `sourceString : string`
- `valid : Boolean`

Lo no ordina, no compara strings, e no participa en rank/unrank.

## `SAVE.vi`

Input `x : BigInt`; output `saved : BigNat`, con rango `1..M`. Multiples de `M` retorna `M`.

## `ChooseRank.vi`

Inputs `stream : AnswerStream`, `N : BigNat`; output `rank1 : BigNat`. `N=0` es error.
