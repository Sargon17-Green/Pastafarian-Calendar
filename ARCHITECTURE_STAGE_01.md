# ਪੜਾਅ 1 ਦੀ architecture

## ਮਕਸਦ

ਇਸ ਪੜਾਅ ਵਿੱਚ monster architecture ਦਾ ਸਿਰਫ਼ ਨਿਰਪੱਖ ਅਧਾਰ ਬਣਾਇਆ ਗਿਆ ਹੈ। ਕਿਸੇ future defect, legacy scar, compatibility detour ਜਾਂ patch-specific flag ਨੂੰ ਪਹਿਲਾਂ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ।

## Semantic state ਦੀ ਮਲਕੀਅਤ

`BootstrapNewContext` ਹਰ invocation ਲਈ ਵੱਖਰਾ context ਬਣਾਉਂਦਾ ਹੈ। `calculationDay` ਅਤੇ `targetDay` arbitrary-precision normalized decimal strings ਵਜੋਂ context ਵਿੱਚ ਰੱਖੇ ਜਾਂਦੇ ਹਨ। Mutable semantic context ਦੋ invocations ਵਿੱਚ ਸਾਂਝਾ ਨਹੀਂ ਹੁੰਦਾ।

`metrics`, `log count` ਅਤੇ diagnostics observability state ਹਨ। ਉਹ normative calculation ਵਿੱਚ ਮੁੜ input ਵਜੋਂ ਨਹੀਂ ਪੜ੍ਹੇ ਜਾਂਦੇ।

## ਨਿਰਪੱਖ layers

- `BootstrapNewContext` — invocation-local base context।
- `BootstrapDispatch` — base dispatcher shell।
- `BootstrapValidateContext` — base invariant validator।
- `BootstrapWrapError` — machine-readable error wrapper।
- `BootstrapMetricBump` ਅਤੇ `BootstrapLogBump` — non-semantic observability shell।
- `CalendarSpaghetti` — production entry-point skeleton; ਪੜਾਅ 1 ਤੋਂ ਅੱਗੇ ਦੀ semantics ਨਹੀਂ ਬਣਾਉਂਦਾ।

## Oracle isolation

`Oracle` test-only reference ਹੈ। Production skeleton oracle ਨੂੰ call ਨਹੀਂ ਕਰਦਾ, oracle result ਨੂੰ fallback ਵਜੋਂ ਨਹੀਂ ਵਰਤਦਾ ਅਤੇ ਕੋਈ runtime comparison ਨਹੀਂ ਕਰਦਾ। Oracle ਦੀ ਆਪਣੀ state production semantic state ਤੋਂ ਵੱਖਰੀ ਹੈ।

## Integer model

Absolute semantic integers decimal strings ਹਨ। Native `Long` ਸਿਰਫ਼ specification ਨਾਲ ਛੋਟੇ bound ਵਾਲੇ local counters ਲਈ ਵਰਤਿਆ ਜਾਂਦਾ ਹੈ। Answer-stream offset ਅਤੇ logical gate index ਨੂੰ arbitrary-precision string ਵਿੱਚ ਬਦਲਿਆ ਗਿਆ ਹੈ। Gate cache physical allocation ਤੋਂ ਪਹਿਲਾਂ explicit resource-limit check ਕਰਦਾ ਹੈ; native wraparound ਮਨਜ਼ੂਰ ਨਹੀਂ।

## ਪੜਾਅ 1 ਵਿੱਚ ਜਾਣ-ਬੁੱਝ ਕੇ ਗੈਰਹਾਜ਼ਰ ਚੀਜ਼ਾਂ

26 defects ਵਿੱਚੋਂ ਕੋਈ legacy function, patch wrapper, late filter, ghost path, alias layer, latch, bad cache key ਜਾਂ virtual legacy family production ਵਿੱਚ ਮੌਜੂਦ ਨਹੀਂ ਹੈ। ਇਹ ਚੀਜ਼ਾਂ ਆਪਣੇ ਇਤਿਹਾਸਕ DISCOVERY/PATCH ਪੜਾਅ ਤੋਂ ਪਹਿਲਾਂ ਨਹੀਂ ਆਉਣਗੀਆਂ।
