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

The historical calendar calculation can occupy the semantic worker for many seconds. The HTTP transport therefore accepts connections concurrently while keeping the historical semantic engine and Pair Tomb single-owner.

Only semantic routes (`/v1/date`, `/v1/date.js`, `/v1/dates`) compete for that owner. Control-plane routes such as `GET /v1/health` and `GET /v1/meta` never wait behind a long calculation.

A second semantic request is not queued. While the semantic owner is occupied it receives `503 ENGINE_BUSY` immediately, with `Retry-After: 5`. This prevents upstream 502 responses or disconnected clients from leaving invisible request threads queued for later execution.
