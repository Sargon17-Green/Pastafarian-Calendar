# Stage5 — ਕੈਲੰਡਰ ਇੰਟੀਗ੍ਰੇਸ਼ਨ ਅਤੇ ਅਰਥ-ਸੰਬੰਧੀ ਜਾਂਚ ਦਾ ਕਰਾਰ (2026-11-06)

**ਪ੍ਰੋਜੈਕਟ:** `PC-BRANCH-BASIC-PUNJABI`  
**ਸ਼ਾਖਾ:** `BASIC+ਪੰਜਾਬੀ`  
**ਸਥਿਤੀ:** `CONTRACT_ONLY / NATIVE_NOT_RUN / NOT_ACCEPTED`

## 1. ਮੰਨੀ ਹੋਈ ਬੁਨਿਆਦ ਅਤੇ source locks

- Stage2 v17 ਇਤਿਹਾਸਕ ਤੌਰ 'ਤੇ ACCEPTED ਹੈ; ਉਸ ਦੀ Windows cleanup ਹਾਲਤ ਤੋਂ ਨਵਾਂ ਨਤੀਜਾ ਨਾ ਕੱਢੋ।
- Stage3 native ACCEPTED: `74aa087b81094f34eab9a0e04e395cc693dd83b1`; run `41878744368`; 148 ਵੱਖਰੇ PASS, 0 FAIL। ਇਹੀ user-approved `SOURCE_LOCK` ਰਹਿੰਦਾ ਹੈ।
- Stage4 QA-only commit: `0527eac40c83551c2f06dafc99be7dc3b2833993`; ਪਹਿਲੀ ਕੁਦਰਤੀ push run `42125645030`, attempt 1, `completed/success`; fresh Stage3 148/148, Stage4 206/206 live native–Python comparisons, 48 metamorphic comparisons, 0 FAIL। Stage4 ਦੀ ਮਨਜ਼ੂਰੀ ਕੇਵਲ ਉਸ ਦੇ BigInt differential scope ਲਈ ਹੈ।
- `BigInt.xba`, `Tests.xba` ਅਤੇ canonical names ਵਾਲੇ blob locks ਬਦਲਣੇ ਨਹੀਂ। ਕੋਈ `main`, merge, release ਜਾਂ machine-wide cleanup ਨਹੀਂ। Stage2–Stage4 ਨੂੰ ਸਿਰਫ਼ contract documentation ਲਈ ਮੁੜ ਨਾ ਚਲਾਓ।

## 2. ਅਸਲੀ implementation boundary

`OracleCalendarDate(calculationDay, targetDay)` test-only reference ਰਸਤਾ ਹੈ ਅਤੇ ਪੰਜ ਨਤੀਜੇ ਦਿੰਦਾ ਹੈ: `(year, cutletName, cutletDay, monthName, monthDay)`। ਇਹ ਆਪਣੇ ਆਪ ਵਿੱਚ **ਸੁਤੰਤਰ** reference ਨਹੀਂ: ਇਸ ਵਿੱਚ shared `BI_*` ਅਤੇ `Catalog*` routines ਵਰਤੇ ਜਾਂਦੇ ਹਨ।

`calendarDateSpaghetti(calculationDay, targetDay)` production entry point ਅਜੇ **ਪੰਜ ਖੇਤਰ ਵਾਪਸ ਨਹੀਂ ਦਿੰਦਾ**; ਇਹ ਜਾਣ-ਬੁੱਝ ਕੇ error number `9302`, code `E_STAGE_02_DISCOVERY_ONLY`, raise ਕਰਦਾ ਹੈ। `CalendarSpaghettiDiscovery01Remainder` ਸਿਰਫ਼ Stage3 corrected SAVE diagnostic ਰਸਤਾ ਹੈ। ਇਸੇ ਲਈ Stage5 ਦੇ *contract* ਨੂੰ production full-calendar PASS ਜਾਂ five-field integration ACCEPTED ਨਹੀਂ ਕਹਿਣਾ।

## 3. ਸੁਤੰਤਰ checks — shared oracle ਤੋਂ ਵੱਖ

### A. ਦਿਨ ਦੀ ਗਿਣਤੀ ਅਤੇ ਦੋ-ਦਿਨੀ invariants

Python `int` ਨਾਲ `F = -15055671` ਲਓ। ਹਰ input `d` ਲਈ ਸੁਤੰਤਰ ਉਮੀਦ:

```
day_count(d) = 2*(F-d)                    if d < F
             = 2*(d-F) + 1              if d >= F
```

`OracleDayCount(d)` ਨਾਲ ਸਿੱਧਾ ਮੇਲ ਕਰੋ। `(calculationDay=c, targetDay=t)` ਲਈ `OracleWorkCounts(c,t)` ਦੇ ਪੰਜ ਖੇਤਰ ਇਹਨਾਂ ਨਾਲ ਮੇਲ ਖਾਣ:

```
[f(c), f(t), abs(t-c)+1, f(c)+f(t), (1 if t<c else 2 if t==c else 3)]
```

ਇਹ ਸੁਤੰਤਰ ਗਣਨਾ `Oracle.xba` ਜਾਂ ਕਿਸੇ ਹੋਰ implementation ਦੀ output copy ਨਹੀਂ ਕਰਦੀ। Inputs: `F-1,F,F+1`, `0`, tablets day `-278522`, signed `2^127` ਆਲੇ-ਦੁਆਲੇ, leading zero strings, 40+ digit signed decimal values, `(c,t)` ਦੀ ਤਿੰਨੋਂ ordering, deterministic seed `0x20261106`। ਬਿਨਾਂ source-specific input grammar proof ਦੇ invalid strings ਨੂੰ valid ਨਾ ਘੋਸ਼ਿਤ ਕਰੋ।

### B. Gate ਅਤੇ year boundaries

ਨਜ਼ਦੀਕੀ `OracleGateDay(i)` ਅਤੇ `OracleGateDay(i+1)` ਲਈ strictly increasing ਕ੍ਰਮ ਅਤੇ gap `42..963` ਦੀ ਜਾਂਚ; `OracleGateIndexAtOrBefore(d)` ਲਈ `GateDay(i) <= d < GateDay(i+1)` invariant। Exact gate ਅਤੇ `gate±1` ਦੇ probes ਲਓ। `OracleFindTargetYear` ਦੇ year boundaries ਨੂੰ ਲੱਗਦੇ ਦਿਨਾਂ ਨਾਲ ਜਾਂਚੋ; year span `252..5778` ਹੋਵੇ। Year structure ਵਿੱਚ ਕਟਲੈਟ ਗਿਣਤੀ `6..17`, ਮਹੀਨੇ `3..47`, ਹਰ ਮਹੀਨਾ `4..123` ਦਿਨ। `Long` ਸਿਰਫ਼ bounded year-local quantities ਲਈ; absolute day ਅਤੇ gate index strings ਹੀ ਰਹਿਣ।

### C. ਕੈਲੰਡਰ ਦੇ ਪੰਜ ਖੇਤਰਾਂ ਦੀ ਅੰਦਰੂਨੀ ਸੰਗਤੀ

`OracleCalendarDate(c,t)` ਲਈ ਹਰ ਖੇਤਰ ਦੀ type/shape ਜਾਂਚੋ। `cutletName` frozen 17-entry catalog ਵਿੱਚ ਅਤੇ `monthName` frozen 47-entry catalog ਵਿੱਚ ਹੋਣ। `cutletDay >= 1`, `monthDay >= 1` ਅਤੇ ਉਹਨਾਂ ਦੀਆਂ ਹੱਦਾਂ independently validated year structure ਤੋਂ ਆਉਣ। ਉਸੇ year ਦੇ ਲੱਗਦੇ ਦਿਨਾਂ ਉੱਤੇ boundary transitions ਅਤੇ name indices ਦੀ ਪੜਤਾਲ ਕਰੋ। `Catalog` ਦੇ translated text 'ਤੇ sorting/ranking ਨਾ ਕਰੋ; canonical indices ਹੀ semantics ਹਨ।

**ਸੀਮਾ:** ਸਿਰਫ਼ `OracleCalendarDate` ਵੱਲੋਂ ਬਣਿਆ output ਅਤੇ ਉਹੀ shared `Oracle` internal structure ਆਪਸ ਵਿੱਚ ਮਿਲ ਜਾਣਾ ਸੁਤੰਤਰ semantic correctness ਦਾ ਸਬੂਤ ਨਹੀਂ। ਜਿੱਥੇ ਸੁਤੰਤਰ normative fixture/algorithm ਨਹੀਂ, ਉਥੇ `STRUCTURAL_ONLY` ਦਰਜ ਕਰੋ। ਭਵਿੱਖ ਵਿੱਚ verified Appendix A fixtures ਅਤੇ production ਦੇ ਪੰਜ ਖੇਤਰਾਂ ਨਾਲ independent comparisons ਲੋੜੀਂਦੀਆਂ ਹਨ।

### D. Production contract characterization

ਵੱਖਰੇ fresh UNO macro calls ਵਿੱਚ `calendarDateSpaghetti(c,t)` ਨੂੰ ਦਾਖ਼ਲ ਕਰੋ; current Stage3 source ਉੱਤੇ expected `Err.Number=9302`, `E_STAGE_02_DISCOVERY_ONLY` assert ਕਰੋ। Unexpected five-field return, wrong error ਜਾਂ suppressed error ਨੂੰ failure ਗਿਣੋ। ਇਹ check *ਮੌਜੂਦਾ ਅਧੂਰੇ API* ਦੀ ਸਹੀ characterization ਹੈ, end-to-end calendar success ਨਹੀਂ।

## 4. Native implementation ਅਤੇ evidence gate

- ਨਵਾਂ Stage5 test harness ਸਿਰਫ਼ `basic/qa/` ਵਿੱਚ; ਲੋੜ ਪਏ ਤਾਂ temporary **private copy** of `Tests.xba` ਵਿੱਚ probes inject ਕਰੋ। Accepted production modules ਅਤੇ canonical-name locks byte-identical ਰਹਿਣ।
- Python independent calculations, StarBasic actual native outputs ਅਤੇ per-case status raw `cases.tsv` ਵਿੱਚ; unique case IDs, duplicate-input policy, input normalization, actual values, expected values ਅਤੇ comparison provenance record ਕਰੋ।
- Required artifacts: `cases.tsv`, `assertions.json`, `status.txt`, `source_metadata.json`, `lo-startup.log`, ਅਤੇ exceptions ਉੱਤੇ `error.txt`। `source_metadata.json` ਵਿੱਚ exact HEAD SHA, parent SHA, relevant blob SHA, runner/UNO versions ਅਤੇ seed ਹੋਣ।
- `assertions.json` ਵਿੱਚ ਵੱਖਰੇ counters: `independent_oracle_checks`, `structural_only_checks`, `boundary_checks`, `production_expected_error_checks`, `native_invocations`, `failures`, `errors`। Missing outputs, missing UNO calls, duplicates ਜਾਂ unchecked exceptions PASS ਨਹੀਂ ਹਨ।
- Fresh owned temporary profile; ਕੇਵਲ ਉਸ profile ਦੀ cleanup। ਕੋਈ ਪੁਰਾਣਾ `D:/v17` recovery, machine-wide deletion ਜਾਂ unverified Windows cleanup claim ਨਹੀਂ।
- Stage5 ਦੇ native job ਨੂੰ ਨਵੇਂ candidate ਲਈ intentional ਤੌਰ 'ਤੇ configure ਕਰੋ; accepted Stage2–Stage4 historical acceptance ਨੂੰ overwrite ਜਾਂ ਗਲਤ ਤਰੀਕੇ ਨਾਲ re-run ਨਾ ਕਰੋ। Jobs ਦੀਆਂ dependencies ਅਲੱਗ evidence-backed ਰੱਖੋ।
- `queued`/`in_progress` ਨਾ PASS ਹਨ ਨਾ BLOCKED। Stage5 acceptance ਕੇਵਲ first eligible `completed` run ਦੇ jobs, raw native logs, files, source SHA ਅਤੇ independent Python checks ਦੀ ਜਾਂਚ ਤੋਂ ਬਾਅਦ।

## 5. ਦੋ ਸਪਸ਼ਟ verdicts

1. **Stage5 characterization/structural QA**: ਉਪਰਲੇ independent arithmetic, boundaries, structural checks ਅਤੇ expected production-error checks ਸਾਰੇ native evidence ਨਾਲ PASS ਹੋਣ ਤੋਂ ਬਾਅਦ ਹੀ `ACCEPTED_WITH_SCOPE_LIMIT` ਸੰਭਵ ਹੈ। ਅਜੇ `CONTRACT_ONLY` ਹੈ।
2. **Full five-field production calendar**: production implementation ਅਸਲ ਵਿੱਚ ਪੰਜ ਖੇਤਰ ਦੇਵੇ, ਹਰ field ਨੂੰ independent normative fixtures/algorithms ਨਾਲ compare ਕੀਤਾ ਜਾਵੇ ਅਤੇ semantic invariants ਸਾਰੇ PASS ਹੋਣ ਤੋਂ ਪਹਿਲਾਂ `NOT_IMPLEMENTED / NOT_ACCEPTED` ਹੀ ਰਹੇਗਾ। Current intentional error ਨੂੰ PASS of full-calendar ਨਾ ਬਣਾਓ।

**NEXT:** ਇਸ contract ਲਈ scoped deterministic Stage5 test harness ਅਤੇ independent Python checks ਬਣਾਓ; QA-only changes ਨੂੰ review ਕਰੋ; ਨਵੀਂ native ਰਿਪੋਰਟ ਤੋਂ ਬਿਨਾਂ ACCEPTED ਨਾ ਲਿਖੋ।
