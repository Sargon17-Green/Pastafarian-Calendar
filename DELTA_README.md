# Browser-interface v11 — automatic lingue e compact status

Aplica ti delta al branche `JavaScript+Interlingue` super HEAD
`784a3f94b29a5d362cdf7416a6b2499d3dc69605`.

Ti actualisation ne modifica li semantic core.

## Lingue

Li public `index.html` ne fixa plu `lang="ie"` sur `<pastafari-date>`.
Li selection de lingue usa ti prioritá:

1. un explicit `lang` dat per un integrator;
2. un manual selection memorisat localmen;
3. `navigator.languages`;
4. Interlingue quam final fallback.

Un manual selection es conservat sub `pastafari.browser.locale`.
Si `localStorage` es prohibit o indisponibil, li selector e automatic detection
continua functionar.

## Loading e error

Li loading/error state ne conserva plu li old target-beacon, toolbar o viewport
visibil detra li status-panel. Ti evita que un old target-ring projecta se circum
li loading panel durante un recalculation.

Li status-panel es nu bounded a max. 42 rem, have null artificial 19-rem
min-height, e usa un compact horizontal layout sur larg ecranes. Sur strett
ecranes it reflu a un compact vertical layout.

Li public page anc remove li artificial `min-height: 100vh` del
`pastafari-date` host. Li page-background continua ocupar li viewport, ma li
component self ne reserva plu un grand vacui area.

## Contracte

Li raw API result, `ready`, `refresh()`, `pastafari-change`, `value`,
`date`, `calculation-date`, `headless`, `no-editor` e explicit `lang`
contractes resta compatibil.

Li change de presentation ne modifica li current 47 distinct saturated
month-themes ni li fort target indication de v10.
