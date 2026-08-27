# Matris de provas de Stage 1

La provas debe es VIs G. No script estranjer pote jenera expected values.

## Enteros esata

- adicion e sutrae con carry/borrow tra plu limbs
- multia con produida plu ca 128 bits
- division e modulo con divisores peti e grande
- floor division negativa coreta
- no floating point en alga path normativa

## Constantes

- `TABLETS_DAY = -278522`
- `FOUNDATION_DAY = -15055671`
- diferentia = `14777149`
- `M = 2^127 - 1`
- `YEAR_MAX_DAYS = 5778`

## SAVE

- `SAVE(1)=1`
- `SAVE(M-1)=M-1`
- `SAVE(M)=M`
- `SAVE(M+1)=1`
- `SAVE(2M)=M`

## Conte de dia

- Foundation -> 1
- un dia pos Foundation -> 3
- un dia ante Foundation -> 2
- `distance(c,c)=1`
- direction 1/2/3 secun ordina cronolojical

## Catalogo

- 17 indexes CUTLET es unica e contigua
- 47 indexes MONTH es unica e contigua
- no string duplicada debe cambia identia canonica
- sort alfabetal de strings no es usada en semantica
- resolve de cada index retorna la string congelada

## Oracle smoke

La provas inicial debe cubre al min `SAVE`, `DayCount`, `WorkCounts`, `BuildStones`, ordina de permuta 1 e 720, e la regla 1A de post-stir:

`savedStirSum = SAVE(sum(oldBowls) + 149 * stirNumber)`

Un expected value complida de calendario debe es jenerada sola par la oracle G pos la oracle es implementada e auditada.
