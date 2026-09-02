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
