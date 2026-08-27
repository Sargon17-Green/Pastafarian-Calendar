# SourceLanguageCatalog 1.0.0 — Ido

Ca katalogo esas la sola fonto-linguo katalogo por ca implemento. Ol esas frozita pos Stage 1. La normala ordino dependas nur de `canonicalIndex`; la Ido-teksto esas nur prezental datumo e nultempe povas influar ranko, unranko, selekto, cache-key o semantiko.

La traduko-regulo esas ca:

1. Vorto kun ordinara semantiko esas tradukita per Ido-vorto o natura Ido-frazo kun la sama senco.
2. Propra nomo, loko-nomo o intence sensenca son-serio esas transliterita deterministe per Latina literaro.
3. Fraza nomo restas un sola nomo.
4. La translitero uzas nur Latina literi sen diakriti; `sh` reprezentas la sono /ʃ/ en la du sensenca nomi. Stabiligita formo nultempe esas reordigita per alfabetala kolaciono.

## Koteleto-nomi

| canonicalIndex | Ido fonto-nomo | speco |
|---:|---|---|
| 1 | Ard | translitero |
| 2 | vulpo | traduko |
| 3 | reno | traduko |
| 4 | larico | traduko |
| 5 | penso | traduko |
| 6 | quar de non egala parti | traduko |
| 7 | Palgurash | translitero |
| 8 | papiruso | traduko |
| 9 | grapolo | traduko |
| 10 | skorpiono | traduko |
| 11 | cindro | traduko |
| 12 | tritiko | traduko |
| 13 | rivero | traduko |
| 14 | rido | traduko |
| 15 | Akad | propra nomo |
| 16 | korno | traduko |
| 17 | la vakua krucho | traduko |

## Monato-nomi

| canonicalIndex | Ido fonto-nomo | speco |
|---:|---|---|
| 1 | argilo | traduko |
| 2 | granato | traduko |
| 3 | kubito | traduko |
| 4 | invidio | traduko |
| 5 | Eridu | propra nomo |
| 6 | dentopasto | traduko |
| 7 | tri de kin egala parti | traduko |
| 8 | Karshumav | translitero |
| 9 | tigro | traduko |
| 10 | stano | traduko |
| 11 | nebulo | traduko |
| 12 | olibano | traduko |
| 13 | spindelo | traduko |
| 14 | kosto | traduko |
| 15 | karobo | traduko |
| 16 | Uruk | propra nomo |
| 17 | honto | traduko |
| 18 | kamelo | traduko |
| 19 | kupro | traduko |
| 20 | puto | traduko |
| 21 | ovoflavo | traduko |
| 22 | stelo | traduko |
| 23 | mielo | traduko |
| 24 | spleno | traduko |
| 25 | kalkopetro | traduko |
| 26 | joyo | traduko |
| 27 | figo | traduko |
| 28 | Ninive | propra nomo |
| 29 | rano | traduko |
| 30 | bitumo | traduko |
| 31 | kandelo | traduko |
| 32 | la klozita pordo | traduko |
| 33 | sezamo | traduko |
| 34 | nuko | traduko |
| 35 | arjento | traduko |
| 36 | lilio | traduko |
| 37 | tempesto | traduko |
| 38 | asno | traduko |
| 39 | farino | traduko |
| 40 | regreto | traduko |
| 41 | Babilono | propra nomo |
| 42 | lango | traduko |
| 43 | lino | traduko |
| 44 | salo | traduko |
| 45 | piro | traduko |
| 46 | arko | traduko |
| 47 | sablo | traduko |

## Regulo por futura locales

La sola permesita fluado esas:

`semantiko -> canonicalIndex -> Ido fonto-nomo -> traduko de locale`

Nultempe esas permesita:

`locale-teksto -> ordino/ranko/selektado -> semantiko`
