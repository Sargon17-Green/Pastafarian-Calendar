# Stage 59 server persistent memoization — initial implementation

Expected base HEAD: `3e6fe2bb035a300b02d33534015e4011ea767019`.

Ti delta adjunte un server Node long-lived sin modificar li semantic core o li browser implementation.

## Implementat

- HTTP API por exact Pastafarian conversions.
- Dedicated warm calculation Worker, talmen un heavyweight synchronous core call ne bloca li HTTP event loop.
- Exact final-result persistent cache per `(calculationDay,targetDay)`.
- Per-request single-flight: concurrent exact misses comparte un calculation.
- Per-initialization single-flight: concurrent first requests ne posse crear plu quam un Worker.
- Semantic namespace per SHA-256 fingerprint de `src/index.js` (o explicit controlled override).
- Persistent hydration/snapshot del actual Stage 58 strong caches del public Stage 57 route:
  - shared gate days;
  - shared gate gaps;
  - Year 5000 anchors;
  - adjacent-year transitions;
  - authoritative year histories;
  - semantic structures;
  - integrated selection/rejection results;
  - Stage 56 sauce results via a bounded persistent shadow ante li existent WeakRef cache.
- Only portable values es persistet. Custom-prototype runtime objects es ignorat quam optimization misses in vice de esser reconstruet incorrectmen.
- Failed calculations ne publica null nov intermediate snapshot e ne crea final cache entries.
- Redis storage por production/multi-replica; persistent file fallback por un unic host.
- Docker Compose con Redis AOF.
- Metrics por hits, misses, coalescing, worker calls, cache failures e intermediate snapshot I/O.

Weak DP backends resta process-local in ti version; li long-lived Worker conserva lor existent Stage 58 reuse. Ili ne es serialisat ancor.

## Local verification executet sur li delta

- `node tests/server-stage59-cache.js` — PASS
- `node tests/server-stage59-http.js` — PASS
- `node tests/server-stage59-all.js` — PASS

Ti tests verifica BigInt-safe codec, single-flight, exact final hits, restart persistence, Stage 58 snapshot hydration, semantic namespace isolation, failed-call non-caching, HTTP output e cache headers.

`tests/server-stage59-real-benchmark.js --run-heavy` es destinat por execution pos merge in li complet repository. It usa li normative witness `calendarDateSpaghetti(739862n,739862n) -> [5000n,"bronze",677n,"sand",32n]` e compara cold, warm final hit, restart final hit e nearby post-restart calculation.
