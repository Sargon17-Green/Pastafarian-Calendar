# ਪੜਾਅ 1 — ਸਥਾਨਕ test ਰਿਪੋਰਟ

## Runtime

Tests LibreOffice Basic / StarBasic runtime ਵਿੱਚ headless mode ਨਾਲ ਚਲਾਏ ਗਏ। ਕਿਸੇ ਹੋਰ programming-language runtime ਨੂੰ calculation, fixture generation, oracle ਜਾਂ test execution ਲਈ ਨਹੀਂ ਬੁਲਾਇਆ ਗਿਆ।

## ਨਤੀਜਾ

```text
OVERALL=PASS
```

## ਮੁੱਖ coverage

Tests arbitrary-precision normalization, addition, subtraction, multiplication, division, modulo, `2^127`, `SAVE`, Foundation ਦੇ ਦੋਵੇਂ ਪਾਸਿਆਂ ਦੇ day counts, native `Long` ਤੋਂ ਵੱਡੇ answer-stream offset, permutation ranks 1 ਅਤੇ 720, bounded compositions, filtered cutlet partitions, distinct-name unranking, small exact month weaving, frozen 17+47 catalog indices, invocation-local context isolation ਅਤੇ neutral production skeleton ਨੂੰ verify ਕਰਦੇ ਹਨ।

`OracleGateIndexAtOrBefore` ਲਈ Foundation index string ਰੂਪ ਵਿੱਚ verify ਕੀਤਾ ਗਿਆ। Absolute logical gate index code arbitrary-precision string ਵਰਤਦਾ ਹੈ; physical cache allocation native boundary ਤੋਂ ਪਹਿਲਾਂ explicit machine error ਨਾਲ ਰੁਕਦੀ ਹੈ, wraparound ਨਾਲ ਨਹੀਂ।

## ਉਮੀਦ ਕੀਤਾ ਨਤੀਜਾ

Stage 1 ਲਈ ਸਾਰੇ bootstrap regressions ਹਰੇ ਹੋਣੇ ਚਾਹੀਦੇ ਹਨ ਅਤੇ ਕੋਈ future-patch regression ਅਜੇ ਮੌਜੂਦ ਨਹੀਂ ਹੋਣਾ ਚਾਹੀਦਾ।

## ਅਸਲ ਨਤੀਜਾ

ਸਾਰੇ ਮੌਜੂਦਾ Stage 1 tests pass ਹੋਏ ਅਤੇ final marker `OVERALL=PASS` ਮਿਲਿਆ।
