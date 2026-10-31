# Mərhələ 4 / DISCOVERY02 — müsbət baza Native sübutu (2026-10-31)

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`
**Branch:** `Rust+Azərbaycan-dili`
**Sınaqdan keçmiş kod SHA:** `494827478e996b977492f16eda3beb916d964cad`
**Hökm:** `BASELINE_NATIVE_VERIFIED`; **Stage4 PASS deyil**, `EXPECTED_RED=NOT_CLAIMED`.

## Eyni SHA üzrə bitmiş CI

| Qapı | Run ID | Son nəticə |
| --- | --- | --- |
| Stage4 baseline Native | [41184330935](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184330935) | completed/success |
| Stage3/PATCH01 | [41184330948](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184330948) | completed/success |
| Stage2/DISCOVERY01 | [41184330982](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184330982) | completed/success |
| Stage1 Native | [41184331060](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184331060) | completed/success |
| Canonical Names Lock | [41184331149](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184331149) | completed/success |

Bütün 5 run `head_sha=494827478e996b977492f16eda3beb916d964cad` və `head_branch=Rust+Azərbaycan-dili` ilə GitHub API-də təsdiqləndi. Run 41184330935 işinin `rust-stage04-baseline` addımları, o cümlədən format yoxlaması və Native testlər, success oldu. CI-də `cargo fmt --all -- --check` qapısı keçdi.

## Native test çıxışı — Stage4 job 124488005884

```text
test result: ok. 16 passed; 0 failed
test result: ok. 3 passed; 0 failed
test result: ok. 4 passed; 0 failed
test result: ok. 3 passed; 0 failed
test result: ok. 2 passed; 0 failed
STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0
STAGE03_PATCH01_BOUNDARY_OK=8
STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0
STAGE04_DISCOVERY02_BASELINE_CASES=7
STAGE04_DISCOVERY02_HUGE_CASES=4
STAGE04_DISCOVERY02_BIJECTION_CASES=1025
STAGE04_DISCOVERY02_SYMMETRIC_HUGE_CASES=8
```

Cəmi **28 test keçdi, 0 uğursuz** (16+3+4+3+2). 1025 yerli qiymət və 8 simmetrik BigInt girişi iki Stage4 property testinin daxilində yoxlanıb; bunlar əlavə 1033 ayrı Rust test funksiyası deyil. Bu testlər müsbət baza və oracle uyğunluğudur, tarixi legacy qüsurun sübutu deyil.

Stage4 artifact: [13036407009](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184330935/artifacts/13036407009), `rust-az-stage04-discovery02-baseline`, 6194 bayt (GitHub API-də mövcud, expired=false). Stage1-də `dead_code` daxil olmaqla xəbərdarlıqlar görünür; uğurlu test nəticəsi xəbərdarlıqsız kompilyasiya iddiası deyil.

## Qapanmayan meyar

Məhdud mənbə auditində həqiqi köhnə day-tag tətbiqi müəyyən edilməyib. `candidate_day_tag` yalnız bazadır; istehsalın beş-komponentli girişi hələ `BootstrapOnly` vəziyyətindədir. Şərh olunmamış tarixi fərq, müşahidə edilmiş bug və ya Stage4 üçün EXPECTED_RED yoxdur.

**NEXT:** yalnız yeni konkret legacy mənbə/artefakt tapılarsa, dəqiq versiya və giriş/çıxışla normativ `day_count` oracle-a qarşı reproduksiya et; real uyğunsuzluq tapılmadan RED/CONTROL və mərhələ PASS elan etmə. Tam təqvim və ya merge iddiası yoxdur. Bu sənədin Git commit-i yalnız audit/status dəyişir; burada verilən Native sübut əvvəlki kod SHA-sına aiddir.
