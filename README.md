# BASIC + ਪੰਜਾਬੀ (ਗੁਰਮੁਖੀ) — ਪੜਾਅ 1

ਇਹ implementation ਲਾਈਨ ਸਿਫ਼ਰ ਤੋਂ ਬਣਾਈ ਗਈ ਹੈ। ਇਸ ਨੇ ਕਿਸੇ ਹੋਰ programming language ਜਾਂ ਕਿਸੇ ਹੋਰ ਮਨੁੱਖੀ source-language implementation ਦਾ code, test, fixture, output, hash, snapshot ਜਾਂ oracle ਨਹੀਂ ਵਰਤਿਆ। ਇਸ ਪੜਾਅ ਦਾ ਇਕੱਲਾ semantic ਆਧਾਰ embedded normative reference ਹੈ।

## ਇਸ ਪੜਾਅ ਵਿੱਚ ਕੀ ਮੌਜੂਦ ਹੈ

- LibreOffice Basic / StarBasic ਵਿੱਚ arbitrary-precision ਪੂਰਨ ਅੰਕਾਂ ਲਈ decimal-string arithmetic।
- `M = 2^127 - 1` ਅਤੇ `SAVE` ਦੀ exact ਗਣਨਾ।
- test-only `Oracle` ਜੋ embedded normative reference ਨੂੰ ਸਾਫ਼ ਅਤੇ ਸਿੱਧੇ ਰੂਪ ਵਿੱਚ ਲਾਗੂ ਕਰਦਾ ਹੈ।
- `SourceLanguageCatalog` ਦਾ frozen `pa-Guru-1.0.0` ਰੂਪ: 17 ਕਟਲੈਟ ਨਾਂ ਅਤੇ 47 ਮਹੀਨਾ ਨਾਂ।
- `canonicalIndex`-ਆਧਾਰਿਤ semantic ordering; translated text sorting, ranking, unranking ਜਾਂ cache key ਨੂੰ ਪ੍ਰਭਾਵਿਤ ਨਹੀਂ ਕਰਦਾ।
- ਨਿਰਪੱਖ invocation-local context, base dispatcher, validator, error wrapper ਅਤੇ observability shell।
- `calendarDateSpaghetti` ਦਾ production skeleton, ਜੋ ਪੜਾਅ 1 ਵਿੱਚ ਜਾਣ-ਬੁੱਝ ਕੇ calendar result ਨਹੀਂ ਦਿੰਦਾ ਅਤੇ ਕੋਈ ਭਵਿੱਖਲਾ legacy defect ਜਾਂ patch ਪਹਿਲਾਂ ਨਹੀਂ ਲਿਆਉਂਦਾ।
- ਇਸੇ BASIC ਲਾਈਨ ਦੇ independently derived fixtures ਅਤੇ test harness।

## ਪੂਰਨ ਅੰਕਾਂ ਦੀ ਸੁਰੱਖਿਆ

Normative ਮੁੱਲ decimal strings ਵਜੋਂ ਰੱਖੇ ਜਾਂਦੇ ਹਨ। `Long` ਸਿਰਫ਼ ਉਹਨਾਂ ਸਥਾਨਕ ਮਾਪਾਂ ਲਈ ਵਰਤਿਆ ਜਾਂਦਾ ਹੈ ਜਿਨ੍ਹਾਂ ਦੀ ਹੱਦ specification ਆਪ ਛੋਟੀ ਅਤੇ ਨਿਸ਼ਚਿਤ ਕਰਦੀ ਹੈ, ਜਿਵੇਂ 46 drops, 47 ਮਹੀਨੇ, 17 ਕਟਲੈਟ ਅਤੇ 5778 ਦਿਨ ਤੱਕ ਦਾ year-local offset। Absolute day, answer-ring offset, year number ਅਤੇ logical gate index decimal arbitrary-precision ਰੂਪ ਵਿੱਚ ਰਹਿੰਦੇ ਹਨ।

Big-integer multiplication ਹਰ digit-product ਤੋਂ ਬਾਅਦ carry normalize ਕਰਦਾ ਹੈ; ਇਸ ਲਈ ਇੱਕ native accumulator ਵਿੱਚ ਬੇਹੱਦ digit-products ਇਕੱਠੇ ਨਹੀਂ ਹੁੰਦੇ। ਜੇ physical cache allocation runtime ਦੀ native ਹੱਦ ਤੱਕ ਪਹੁੰਚੇ, code wraparound ਕਰਨ ਦੀ ਥਾਂ explicit machine error ਦਿੰਦਾ ਹੈ।

## Source language

ਸਾਰੇ implementation-authored ਮਨੁੱਖੀ comments ਅਤੇ documentation ਪੰਜਾਬੀ ਵਿੱਚ ਗੁਰਮੁਖੀ ਲਿਪੀ ਨਾਲ ਲਿਖੇ ਗਏ ਹਨ। API identifiers, error codes, file names ਅਤੇ ਹੋਰ machine-readable tokens technical conventions ਅਨੁਸਾਰ ਰਹਿੰਦੇ ਹਨ।

## Tests ਚਲਾਉਣਾ

LibreOffice profile ਦੇ `user/basic` ਹੇਠ ਇਸ package ਦੀ `basic` library ਰੱਖ ਕੇ ਇਹ macro ਚਲਾਇਆ ਜਾ ਸਕਦਾ ਹੈ:

```text
libreoffice -env:UserInstallation=file:///PATH/TO/PROFILE --headless 'macro:///Standard.Tests.Main'
```

ਸਫਲ run ਦੇ ਅੰਤ ਵਿੱਚ test output ਵਿੱਚ ਇਹ ਲਾਈਨ ਆਉਂਦੀ ਹੈ:

```text
OVERALL=PASS
```

## ਪੜਾਅ ਦੀ ਹੱਦ

ਇਹ ਸਿਰਫ਼ `Stage 1 / 55 — BOOTSTRAP` ਹੈ। ਪੜਾਅ 2 ਦਾ `DISCOVERY 01` ਇਸ package ਵਿੱਚ ਮੌਜੂਦ ਨਹੀਂ ਹੈ ਅਤੇ ਕਿਸੇ ਵੀ future patch ਦਾ code ਪਹਿਲਾਂ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ।
