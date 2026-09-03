# Transportus `date-job.js`

Haec cicatrix transportalis longum calculum calendarii a vita unius petitionis HTTP separat. Semantica Stage 56, `calendarDateSpaghetti(c,t)`, Pair Tomb et regula unius possessoris manent immutata.

## Initium

`GET /v1/date-job.js` accipit eadem argumenta computationis quae `GET /v1/date.js`, atque `callback` obligatoriam.

Exemplum:

```text
/v1/date-job.js?date=2026-09-03&calendar=gregorian&language=la&callback=pfStart
```

Petitio ipsa cito redit:

```js
pfStart({
  "apiVersion":"1",
  "job":{
    "id":"j1788427641316-1",
    "status":"running",
    "pollAfterMilliseconds":2000
  }
});
```

Calculus historicus deinde in filo ministri pergit. Tempus semanticum implicitum est momentum petitionis initialis, non momentum polling posterioris.

Si machina iam ab alio calculo possidetur, initium non in catervam ponitur. JavaScript HTTP 200 statim reddit:

```js
pfStart({
  "apiVersion":"1",
  "job":{
    "status":"busy",
    "retryAfterMilliseconds":5000
  }
});
```

Header `Retry-After: 5` quoque adest.

## Polling

```text
/v1/date-job.js?job=j1788427641316-1&callback=pfPoll
```

Dum calculus currit:

```js
pfPoll({"apiVersion":"1","job":{"id":"...","status":"running","pollAfterMilliseconds":2000}});
```

Post successum:

```js
pfPoll({
  "apiVersion":"1",
  "job":{"id":"...","status":"complete","applicationStatus":200},
  "result":{
    "apiVersion":"1",
    "engine":{"id":"celeritas-per-sepulcra","semanticStage":56},
    "resolvedInput":{},
    "date":{}
  }
});
```

Si validatio vel calculus errorem applicationis reddit, `status` fit `failed` et corpus JSON originale sub `result` servatur.

## Vita resultati

Resultata completa per 30 minutas in memoria transportali retinentur, cum limite 64 job. Hoc **non est cache semanticus**: nulla quaestio nova ex hoc registro acceleratur neque semantica Pair Tomb mutatur. Registrum tantum efficit ut clientis polling breve possit resultatum iam perfectum legere.

Restart/deploy ministri registrum delet. Clientis `JOB_NOT_FOUND` post restart potest calculationem denuo incipere.

## Proprietas

Unus tantum calculus semanticus simul intrat engine historicum. Initia simultanea non queue fiunt. `/v1/health`, `/v1/meta` et polling job non exspectant post calculum.

Nullus Stage 57 creatur.
