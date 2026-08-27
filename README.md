# Calendario Pastafari — LabVIEW/G + Elefen

Esta repositorio comensa de zero. Lo no copia, tradui, executa, compara, o usa un otra implementa de la calendario.

La lingua de programa unica es LabVIEW/G. La lingua umana canonica unica es Lingua Franca Nova (Elefen). Tota nomes canonica usa `canonicalIndex`; la testo elefen es sola un representa de presenta e no participa en ordina, rank, unrank, cache, o seleje.

## Estado de Stage 1

Esta paceta conteni la base de repositorio, la catalogo de lingua fonte, la arquitetura de Bootstrap, la manifesta de VIs, la contratos de conetores, la matriz de provas, e la projeto LabVIEW. La VIs binaria autentica no pote es creada sin LabVIEW. Donce la Stage 1 no es ancora `GREEN`: la parte G debe es creada e executada en un ambiente LabVIEW.

No file `.vi` falsa es incluineda. No runtime de un otra lingua es usada como sustitua.

## Reglas xef

- `M = 2^127 - 1` con enteros esata.
- `FOUNDATION_DAY = -15055671`.
- `TABLETS_DAY = -278522`.
- `YEAR_MAX_DAYS = 5778`.
- La oracle de prova debe es un implementa G direta de la referensa normativa.
- La produi no pote apela la oracle.
- La Stage 1 pote crea sola infraestrutura monstruosa jeneral: contexto base, dispatcher base, validor base, error wrapper base, e shell de metrics/logs.
- No mecanismo de patch 01–26 pote apare en Stage 1.

## Fontes de lingua

La catalogo usa vocabulo elefen moderna cuando lo es disponible. Per nomes propre e nomes sin sinifia, la catalogo usa un regula de transcrive deterministe documentada en `docs/SOURCE_LANGUAGE_POLICY.md`.
