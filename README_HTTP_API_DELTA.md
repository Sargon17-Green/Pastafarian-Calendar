# Cicatrix HTTP API — superpositio pro `Celeritas-per-Sepulcra`

Copia huius directorii in radicem rami Celeritas ponenda est. Fasciculus non continet `HANDOFF_*` neque exemplum alterius machinae.

Addit:

- conversionem calendarii ad axem Celeritas;
- diem computationis implicitum per transitum inferiorem Veneris apud Kisurra;
- parser JSON strictum qui numeros magnos a catenis distinguit;
- `GET/POST /v1/date`, `POST /v1/dates`, `/v1/health`, `/v1/meta`;
- campum optionalem `language` ad nomina segmentorum et mensium praesentanda; nunc sola lingua `la` publice sustinetur, sed stratum expansioni futurae praeparatum est;
- adapter additivum ad `calendarDateSpaghetti` sine mutatione structurae historicae;
- ministrum synchronous Boost.Beast;
- CORS restrictum pro navigatore: origo situs publici implicite admittitur, `OPTIONS`/preflight tractatur, wildcard `*` non adhibetur, et allowlist per `PASTAFARI_CORS_ORIGINS` mutari potest;
- primam cicatricem accelerationis `L0 Pair Tomb` (4096 loca direct-mapped), cum bypass/fallback integro;
- probationes et CI quae realem `src/monster.cpp` conectunt.

Vide `docs/HTTP_API_V1.md` et `docs/HTTP_API_BUILD.md`.
