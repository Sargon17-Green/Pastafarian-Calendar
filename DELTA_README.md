# Browser-interface v10 — correction de visibilitá, colores e localisation

Aplica ti delta al branche `JavaScript+Interlingue`.

Ti actualisation ne modifica li semantic core. It ameliora solmen li browser-interface e su regression-tests.

## Principal changes

- Li cercat die es marcat mult plu fortmen in li cutlet-grid, con fort contrast, extern ring e target-badge.
- Li target-beacon anc usa un plu fort visual treatment.
- Li old pastel month-themes es removet.
- Chascun del 47 actual semantic month names have un distinct, saturat visual theme con fort edge e secondary pattern, por maximisar li visual separation inter months.
- Li localisation de cutlet- e month-nómines es audit contra li actual Interlingue semantic source-text, ne contra li old positional catalog.
- Semanticmen incorrect o inconsistent translations es corriget in li activ locales.
- Additional regression witnesses protege actual identities tal quam `larice`, `Palgursh`, `papirus`, `Karshumb`, `leopard`, `candel`, `lilie`, `gudron` e `oliban`.
- Li Hebrew localisation resta representat in source per Unicode escape-sequenties, por conservar li Stage 01 source-purity invariant.

## Contracte conservat

Li raw API result resta exactmen li black-box core result.
`ready`, `refresh()`, `pastafari-change`, `value`, `lang`, `date`, `calculation-date`, `no-editor` e `headless` ne es semanticmen changeat.

Null file sub `src/**` es modificat per ti delta.
