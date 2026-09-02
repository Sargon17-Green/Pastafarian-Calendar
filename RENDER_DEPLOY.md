# Render deployment — Celeritas per Sepulcra HTTP API

This deployment layer does not alter Pastafarian calendar semantics.

## Files

- `Dockerfile` builds `pastafari-http` against the real `src/monster.cpp`.
- `render.yaml` declares one public Render Web Service.

## Deploy

1. Commit `Dockerfile` and `render.yaml` to branch `Celeritas-per-Sepulcra`.
2. In Render, create a new Blueprint from:
   `https://github.com/Sargon17-Green/Pastafarian-Calendar`
3. Select branch `Celeritas-per-Sepulcra` if Render asks for a branch.
4. Render reads `render.yaml` and creates `pastafari-celeritas-api`.
5. Wait until `/v1/health` is healthy.
6. Render assigns a public HTTPS hostname such as:
   `https://pastafari-celeritas-api.onrender.com`

## First public checks

Replace `HOST` below with the assigned Render host.

```sh
curl -fsS https://HOST/v1/health

curl -fsS   -H 'Origin: https://bwtbdyqtmsprytgydym-cpu.github.io'   'https://HOST/v1/date?date=2026-09-02&language=la'
```

Browser preflight:

```sh
curl -i -X OPTIONS   -H 'Origin: https://bwtbdyqtmsprytgydym-cpu.github.io'   -H 'Access-Control-Request-Method: GET'   https://HOST/v1/date
```

Expected:
- HTTP 204 for allowed preflight.
- `Access-Control-Allow-Origin: https://bwtbdyqtmsprytgydym-cpu.github.io`
- `/v1/health` returns a successful response.

## Notes

The service binds to `0.0.0.0` and uses Render's `PORT` variable.
The public-site origin is explicitly allowlisted; wildcard CORS is not used.
The initial Render configuration uses the free plan for deployment testing.
