# Render deployment — Celeritas per Sepulcra HTTP API

The public service accepts the Pastafarian GitHub Pages origin and, explicitly, opaque `Origin: null` requests so an HTML file opened directly with `file://` can use the API.

`Origin: null` is broader than local files: sandboxed/data documents can also have an opaque origin. The API therefore keeps this as a separate switch and does not enable credentials.

## Render environment

```text
PASTAFARI_CORS_ORIGINS=https://bwtbdyqtmsprytgydym-cpu.github.io
PASTAFARI_CORS_ALLOW_NULL_ORIGIN=1
```

To disable local/opaque-origin access later, set:

```text
PASTAFARI_CORS_ALLOW_NULL_ORIGIN=0
```

## Verification

```sh
curl -i -X OPTIONS \
  -H 'Origin: null' \
  -H 'Access-Control-Request-Method: GET' \
  https://HOST/v1/date
```

Expected:

```text
HTTP/... 204
Access-Control-Allow-Origin: null
```

The service still rejects an ordinary unlisted web origin such as `https://alien.example`.

## Long calculations and health checks

The historical calendar calculation can occupy the semantic worker for many seconds. The HTTP transport therefore accepts connections concurrently while serializing every non-health protocol call behind one transport mutex. `GET /v1/health` bypasses that semantic gate and remains responsive during a long calculation.

This is required for Render: its HTTP health checks must answer quickly even while a date request is still computing. The semantic engine itself is not made concurrent, and Pair Tomb ownership remains single-owner.
