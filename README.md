# Stage 59 — persistent server memoization

Ti directorie adjunte un long-lived Node.js calculation service supra li existent JavaScript + Interlingue core. Li core semantic ne es duplicat e ne es reimplementat: un Worker thread charge `src/index.js` un sol vez e usa exclusivmen `calendarDateSpaghetti(calculationDay, targetDay)` quam authority.

## Quo es memorizat

Stage 59 have tri layers.

1. **Final result cache** — li exact `(calculationDay,targetDay)` five-part tuple es persistet per semantic fingerprint. Un exact hit ne entra in li calculation Worker.
2. **Single-flight** — concurrent misses por li sam exact request comparte un unic Worker calculation.
3. **Persistent Stage 58 intermediate snapshots** — li public Stage 57 manager su bounded strong caches es hydratat ante li unesim calculation e rescribet solmen pos un successful calculation. Li persistet scopes es:
   - shared gate days;
   - shared gate gaps;
   - Year 5000 anchors;
   - adjacent-year transitions;
   - authoritative year histories;
   - semantic structures keyed per lor full fingerprint;
   - integrated selection/rejection results;
   - Stage 56 sauce results, hydratat per un bounded shadow LRU ante que li existent WeakRef cache es consultat.

Weak `LegalMonthWeavingDP` e `VirtualLegacyList` backends ne es persistet in ti unesim server stage. Ili resta warm-process WeakRef caches, nam serialisar runtime object graphs con custom prototypes vell esser un semantic risk. Li server process resta long-lived, talmen ti weak caches continua esser reutilisat inter requests quam in Stage 58.

## Correctness boundary

Cache keys es namespaced per un semantic fingerprint. Per default Stage 59 calcula SHA-256 de `src/index.js` e usa li unesim 32 hex characters. Un changed core source ergo ne posse accidentalmen leger final o intermediate data del anterior namespace. `PASTAFARI_SEMANTIC_FINGERPRINT` existe solmen por controlled deployment systems quel ja possede un versioned semantic fingerprint.

Un failed calculation ne persiste null nov Stage 58 snapshot e ne crea un final cache entry. Cache read/write failure es fail-open: li authoritative calculation continua; cache es un optimization, ne authority.

## Storage

Si `PASTAFARI_REDIS_URL` existe, Stage 59 usa Redis. Li server package usa `redis` 6.2.1 o compatibil plu recent in li 6.x range. Si Redis ne es configurat, li default es un server-side persistent JSON file in `.pastafari-cache/stage59.json`; ti mode es destinat por un unic process/host. Por plu quam un replica, usa Redis.

## API

- `GET /healthz`
- `GET /metrics`
- `GET /v1/calendar?calculationDay=...&targetDay=...`
- `POST /v1/calendar` con JSON `{ "calculationDay": "...", "targetDay": "..." }`

Omni integers in JSON output es decimal strings. Li response include `X-Pastafari-Cache: MISS|HIT|COALESCED` e `X-Pastafari-Semantic-Fingerprint`.

## Local execution

Without Redis:

```sh
node server/index.js
```

Con Redis:

```sh
cd server
npm install
PASTAFARI_REDIS_URL=redis://127.0.0.1:6379 node index.js
```

Docker + Redis:

```sh
docker compose -f server/compose.yaml up --build
```

## Verification

Ti delta include tests quel usa un deterministic fake core por provar li cache/server mechanics sin pagar un heavyweight calendar calculation:

```sh
node tests/server-stage59-cache.js
node tests/server-stage59-http.js
```

Li important witnesses include concurrent single-flight, exact final hit, file-backed restart, hydration de intermediate Stage 58 snapshots, semantic-fingerprint isolation, failure-not-cached e HTTP cache headers.

Pos integration in li real branch, li next benchmark deve comparar: cold new namespace, warm Worker, exact persistent hit, nearby request pos process restart, e nearby request pos Redis hydration. Li canonical five-part result deve esser identic in omni profiles.
