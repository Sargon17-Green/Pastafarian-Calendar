# Accessus ex `file://`

Pagina HTML aperta directe ex disco (`file://...`) originem HTTP ordinariam non habet. Navigatores moderni eam plerumque originem opacam tractant et petitiones CORS cum `Origin: null` mittunt.

Cicatrix HTTP igitur duas regulas separatas habet:

- origines HTTP/HTTPS exactae: `PASTAFARI_CORS_ORIGINS`;
- origo opaca `null`: `PASTAFARI_CORS_ALLOW_NULL_ORIGIN`.

Default:

```text
PASTAFARI_CORS_ALLOW_NULL_ORIGIN=true
```

Ita JavaScript in fasciculo HTML locali API publicam per HTTPS vocare potest, dummodo navigator CORS ex `file://` ad HTTPS permittat.

Ad originem `null` prohibendam:

```sh
PASTAFARI_CORS_ALLOW_NULL_ORIGIN=0 ./pastafari-http
```

Valor invalidus configurationem repudiat et minister non incipit.

## Nota securitatis

`Origin: null` non significat exclusive "fasciculum localem". Origines opacae, inter quas documenta `data:` et quaedam iframe sandboxed, eodem valore serializantur. Quam ob rem haec licentia separata est et facile disable potest.

API v1 credentials CORS non admittit nec `Access-Control-Allow-Credentials` mittit. Wildcard `*` non adhibetur.

## Transportus scripti (`GET /v1/date.js`)

Quaedam retia corporativa vel systemata browser-isolation responsum JSON ex `fetch` HTML involvunt. In tali ambitu CORS iam recte permissum esse potest, sed JavaScript clientis corpus JSON legere non potest.

Ad hunc casum via additiva `GET /v1/date.js` eandem calculationem publicam facit, sed responsum ut JavaScript exsecutabile reddit. Exempli gratia:

```text
/v1/date.js?date=2026-09-02&calendar=gregorian&language=la&callback=pastafariDateCallback
```

Responsum:

```javascript
pastafariDateCallback({"apiVersion":"1", ... });
```

Haec via ad `<script src="...">` destinatur et CORS ad corpus legendum non requirit. `callback` simplex identificator JavaScript ASCII esse debet: primum character littera, `_` vel `$`; reliqui litterae, numeri, `_` vel `$`; longitudo maxima 64. Puncta, parentheses et alia signa vetantur.

Errores semantici post callback validatum etiam per callback redduntur ut JavaScript HTTP 200, cum capite `X-Pastafari-Application-Status` statum applicationis originalem (exempli gratia `422`) continente. Cliens igitur `result.error` examinare debet. Callback invalidus aut absens normalem errorem HTTP JSON (`400`) reddit, quia nulla functio tuto vocari potest.

Via `/v1/date.js` nihil in machina calendarii mutat: eadem `CalendarService`, idem `calendarDateSpaghetti(c,t)`, idem Stage 56, eadem lingua nominum et eadem resolutio calculationis adhibentur. Tantum repraesentatio transportus mutatur.
