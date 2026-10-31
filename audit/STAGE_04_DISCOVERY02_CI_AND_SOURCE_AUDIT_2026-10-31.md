# Mərhələ 4 / DISCOVERY02 — CI icrası və mənbə yoxlamasının davamı

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Branch:** `Rust+Azərbaycan-dili`  
**Code SHA:** `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818`  
**Yoxlama tarixi:** 2026-10-31  
**Status:** müsbət Native baza təsdiqləndi; Stage4 açıqdır.

## 1. Branch və dəyişiklik identikliyi

GitHub branch endpoint-i `Rust+Azərbaycan-dili` üçün HEAD-in `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818` olduğunu təsdiqlədi. Stage4 düzəliş commit-i əvvəlki `0b10298d15a163dc8df49b18265b1d7c1326baf3` üzərində yalnız iki Rust faylında üç rustfmt dəyişiklikindən ibarətdir:

- `src/discovery02_work_counts_probe.rs`
- `tests/stage04_discovery02_work_counts.rs`

Commit diff-də məntiqi dəyişiklik yoxdur. Əvvəlki üç CI xətası `cargo fmt --check` mərhələsində baş vermişdi; bu SHA üzrə Native yoxlamalar yenidən uğurla tamamlandı.

## 2. CI nəticələri — eyni Code SHA

Bütün beş workflow `completed/success` vəziyyətindədir və `head_sha`-ları Code SHA ilə eynidir.

| Gate | Run ID | Job ID | Conclusion |
|---|---:|---:|---|
| Stage1 Native | 41203445100 | 124543683641 | success |
| Stage2 DISCOVERY01 Native | 41203445152 | 124543684019 | success |
| Stage3 PATCH01 Native | 41203445099 | 124543683747 | success |
| Stage4 DISCOVERY02 baseline Native | 41203445156 | 124543683911 | success |
| Canonical Names Lock | 41203445083 | 124543683611 | success |

Run links:

- [Stage1](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445100)
- [Stage2](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445152)
- [Stage3](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445099)
- [Stage4](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445156)
- [Canonical Names Lock](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445083)

### Stage4 artifact

- Artifact ID: `13043472881`
- Name: `rust-az-stage04-discovery02-baseline`
- Size: 6,301 bytes
- SHA-256: `308805e4869f2557b9fe16d53155ab99f8d47f9c332103b0799e5ad36efe4070`
- Expires: 2026-11-30T13:22:18Z
- [Workflow run and artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203445156)

Artifact ZIP was downloaded and independently checked: `exit.txt=0`; `sha.txt` names PROJECT_ID and the exact Code SHA; `result.txt` contains exactly:

```text
STAGE04_DISCOVERY02_BASELINE_ONLY=PASS
EXPECTED_RED=NOT_CLAIMED
```

The downloaded ZIP SHA-256 matches GitHub's artifact digest.

## 3. Native test evidence

Stage4 job passed the stable Rust toolchain, identity/format verification, and bounded Native baseline/regression steps. The captured toolchain was rustc 1.99.1 and cargo 1.99.1. The Stage4 stdout contains six successful test groups:

- Stage1: 16 tests
- Stage2: 3 tests
- Stage3: 4 tests
- Stage4 baseline: 3 tests
- Stage4 day-tag properties: 3 tests
- Stage4 work-counts: 3 tests

**Total: 32 passed, 0 failed.** The zero-test harness entry is not included in this total.

Exact Stage4 markers:

- `STAGE04_DISCOVERY02_BASELINE_CASES=7`
- `STAGE04_DISCOVERY02_HUGE_CASES=4`
- `STAGE04_DISCOVERY02_SYMMETRIC_HUGE_CASES=8`
- `STAGE04_DISCOVERY02_TAG_PREIMAGE_CASES=398`
- `STAGE04_DISCOVERY02_BIJECTION_CASES=1025`
- `STAGE04_DISCOVERY02_WORK_COUNTS_LOCAL_PAIRS=49`
- `STAGE04_DISCOVERY02_WORK_COUNTS_HUGE_PAIRS=8`
- `STAGE04_DISCOVERY02_WORK_COUNTS_TRANSLATION_CASES=12`

Prior regression signatures were retained:

- `STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0`
- `STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0`
- `STAGE03_PATCH01_BOUNDARY_OK=8`

Warnings about unused code and Node deprecations were non-fatal; all relevant workflow steps and test result summaries completed successfully.

## 4. Continued bounded legacy-source investigation

The following additional checks were performed against the exact branch history, not against other branches or other implementations:

1. The initial project commit `9a46739c981605875958f9b167bad6049f01fa79` has only `src/lib.rs` and `src/source_language_catalog.rs` under `src/`. Its `calendar_date_spaghetti` entry point returns `BootstrapOnly`; it contains no day-tag implementation.
2. The current history of `src/discovery02_day_tag_probe.rs` contains exactly one commit, `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f`, which introduced it explicitly as a positive baseline probe.
3. The current `src/lib.rs` history has six commits. The tracked sequence contains bootstrap, the Stage2 legacy SAVE path, Stage3 SAVE patch, the Stage4 positive day-tag probe, and the Stage4 work-counts QA; no earlier tracked day-tag implementation appears in that history.
4. `src/discovery01_legacy_save.rs` is a legacy SAVE remainder path (`mod_floor` with modulus `2^127-1`), not a day-tag implementation.
5. `src/patch01_save.rs` is the normative SAVE patch, not a day-tag implementation.
6. In current `src/lib.rs`, `calendar_date_spaghetti` still returns `BootstrapOnly`; the candidate day-tag module is not wired into the production five-field calendar entry point.

Relevant source/history links:

- [Initial bootstrap commit](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/9a46739c981605875958f9b167bad6049f01fa79)
- [Only commit adding the day-tag probe](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f)
- [Current day-tag probe](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/discovery02_day_tag_probe.rs)
- [Current production entry point and module declarations](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/lib.rs)
- [Legacy SAVE implementation](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/discovery01_legacy_save.rs)
- [Normative SAVE patch](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818/src/patch01_save.rs)

**Finding, limited to the audited branch and paths:** no concrete historical legacy day-tag implementation or documented earlier day-tag route was found. This does not prove that no external archive, other repository, or untracked historical artifact exists. The existing SAVE legacy path must not be relabeled as a day-tag defect.

## 5. Acceptance decision and NEXT

- Positive Native baseline: **PASS** on Code SHA `e9f2a1c6042a6bfa1ba448a8f6a4ea09c66ce818`.
- Stage4 / DISCOVERY02 overall: **OPEN**.
- `EXPECTED_RED`: **NOT CLAIMED**.
- Production five-field entry point: unchanged and still `BootstrapOnly`.
- No Stage5, main update, merge, or release is authorized or performed.

**NEXT:** continue only with a concrete archived day-tag implementation, artifact, or documented historical route whose provenance and version can be pinned. Reproduce that exact route against the independent normative oracle, and create RED/CONTROL only after an observed mismatch. If no such source is identified, preserve Stage4 as OPEN; do not invent a defect or close the stage from positive-only tests.

## 6. Əlavə hədəfli day-tag mənbə yoxlaması — 2026-10-31

Əvvəlki `src/` tarixçəsini yenidən skan etmədən, inventar jurnalında artıq istinad edilən bir konkret potensial sənəd yoxlanıldı:

- Mənbə: [PC-BRANCH-RUST-AZERBAIJANI — Stage 1 Native CI patch and verified findings — 2026-10-28](https://docs.google.com/document/d/17lpWvSFP-DRQBRApCAb6ceIPkSiMyEKh6-LAFi4T8Ps/edit).
- Sənədin müşahidə edilmiş məzmunu: `tests/stage01.rs` faylında `CATALOG_VERSION` import düzəlişi və `.github/workflows/stage-01-rust-native.yml` üçün Stage1 Native CI təklifi; Stage1-də 17 cutlet və 47 month adının statik müqayisəsi.
- Bu konkret sənəddə day-tag üçün arxivləşdirilmiş alqoritm, ilkin giriş/çıxış marşrutu, kod reviziyası və ya müşahidə edilmiş historical RED yoxdur. Bundan əlavə, redaktə edilə bilən Google Docs URL-si təkbaşına sabit kod versiyası sayıla bilməz.
- İkinci, yalnız repoya məhdudlaşdırılmış yoxlama: GitHub Issues üzrə dəqiq `"day-tag"` və `"DISCOVERY02"` axtarışlarının hər biri 0 nəticə qaytardı. Bu, yalnız həmin axtarışların nəticəsidir; repoda və ya xarici arxivlərdə belə mənbənin qəti yoxluğunu sübut etmir.

**Mənbə uyğunluğu:** `NO_VERIFIABLE_LEGACY_DAY_TAG_ROUTE_FOUND_IN_THESE_TWO_TARGETED_CHECKS`. Heç bir day-tag `EXPECTED_RED`, `CONTROL`, Stage4 closure, Stage5 və ya production wiring nəticəsi çıxarılmır. Əvvəlki Code SHA üzrə 32/32 Native baseline sübutu dəyişmir.

**NEXT (dəyişməz qəbul şərti):** yalnız dəqiq provenance və versiyalı real tarixi day-tag source/artifact/route təqdim olunduqda onu müstəqil normativ oracle ilə çoxalt; faktiki fərq aşkar edilmədən `EXPECTED_RED` bəyan etmə.

## 7. Versiyalı xarici arxiv gün-etiketi marşrutu — 2026-10-31

İki əvvəlki mənfi yoxlamanı təkrarlamadan, 5 GitHub Release obyektinin metadata-sı yoxlanıldı. `python-turkish-v1.0.0-verified-20261030` tag-i commit `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` ünvanına bağlanır. Həmin tree-də `src/pastafari_calendar/legacy_day_counts.py` blob `405f461b2e2cdd170ded010e6f8046b78d6b4ab6` kimi mövcuddur. Bu, Rust branch tarixindəki əvvəlki day-tag implementasiyası deyil, **başqa dilin tarixi qorunmuş marşrutudur**.

`oldDayTag(day)` funksiyası `2 * abs(day - F)` hesablayır (`F=-15055671`), halbuki bağımsız normativ oracle `day>=F` üçün əlavə `1` tələb edir. Arxiv mənbəyindən çıxarılan orijinal Python əsas funksiyaları lokal olaraq 15 sərhəd/BigInt girişi ilə icra edildi: `RED=8 CONTROL=7 UNEXPECTED=0`, tarixi `dayTagWithFoundationScar` üçün `PATCH_OK=15`. Burada 4 böyüklük `2^127`, `2^1025`, `2^4096`, `2^8192` hər iki işarə ilə sınandı.

Rust üçün test-only, müstəqil riyazi rekonstruksiya və onun Native CI markerləri əlavə edildi; normativ oracle xarici tarixi koddan götürülməyib. Rust Native yeni SHA üzərində **hələ təsdiqlənməyib**, Stage4 ümumilikdə **OPEN** qalır, production entry `BootstrapOnly` saxlanılır.

Source: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/python-turkish-v1.0.0-verified-20261030/src/pastafari_calendar/legacy_day_counts.py
Contract: audit/STAGE_04_DISCOVERY02_ARCHIVED_ROUTE_CONTRACT_2026-10-31.md

## 8. Arxiv şahidlərinin Rust Native CI yoxlaması və növbəti müstəqil qapı — 2026-10-31

**Yoxlanmış code SHA:** \`3eebe8e11e8dac2ee281ae33c797f104b8a4a426\`, **branch:** \`Rust+Azərbaycan-dili\`.
GitHub branch HEAD yenidən oxunub və həmin SHA ilə eynidir. Aşağıdakı beş workflow işinin hamısı \`completed/success\` idi; heç biri təkrar başladılmadı.

| Qapı | Run | Job | Nəticə |
|---|---:|---:|---|
| Stage4 Native + arxiv şahidi | 41239239534 | 124649437996 | success |
| Stage3 regression | 41239239536 | 124649437849 | success |
| Stage2 regression | 41239239500 | 124649437658 | success |
| Stage1 Native | 41239239503 | 124649437653 | success |
| Canonical Names Lock | 41239239566 | 124649437909 | success |

Stage4 Native job logunda \`cargo fmt --all -- --check\` addımı müvəffəqdir; test qruplarında **16+3+4+2+3+3+3=34 keçmiş, 0 uğursuz** nəticə var. Test-only arxiv müqayisəsi dəqiq olaraq
\`STAGE04_DISCOVERY02_ARCHIVED_RED=8 CONTROL=7 UNEXPECTED=0\` və
\`STAGE04_DISCOVERY02_ARCHIVED_PATCH_CONTROL=15\` yazdı.
Stage4 baseline, huge, bijection, symmetric, preimage və work-counts markerləri, həmçinin Stage2/Stage3 regression markerləri workflow tərəfindən yoxlanıldı.

Sübut ZIP-i: GitHub Actions artifact \`13057206172\` (\`rust-az-stage04-discovery02-baseline\`, 6455 bayt), SHA-256 \`8ee8f22b678130a4d565625c244b34f4133df1781f084a5ed1e8a713c84dda47\`; \`expired=false\` zamanı API metadata-sı yoxlandı. Yüklənmiş ZIP baytları ayrıca yoxlanılmadı, buna görə ZIP-in daxilindəki hər bir fayl barədə əlavə iddia edilmir.
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41239239534/artifacts/13057206172

Arxiv mənbə faylı GitHub-da release tag ilə ayrıca oxundu: \`src/pastafari_calendar/legacy_day_counts.py\`, faktiki blob SHA \`405f461b2e2cdd170ded010e6f8046b78d6b4ab6\`; bu, əvvəlcədən qeyd edilmiş hash ilə eynidir. Python mənbəyində \`oldDayTag\` və \`dayTagWithFoundationScar\` həqiqətən mövcuddur. **Lakin** yuxarıdakı CI yalnız həmin kodun Rust test-only riyazi rekonstruksiyasını icra edir, arxivdəki Python funksiyalarının özlərini Rust ilə avtomatlaşdırılmış cross-language müqayisədə icra etmir.

**Qəbul sərhədi:** \`ARCHIVAL_WITNESS_RUST_NATIVE_QA=PASS\`; \`STAGE4_CLOSURE=OPEN\`; \`CROSS_IMPLEMENTATION_RUNTIME_DIFFERENTIAL=NOT_RUN\`. Arxivləşdirilmiş Python marşrutu Rust filialının əvvəlki istehsal marşrutu deyil. Tarixi Rust day-tag nasazlığı sübut edilməyib; beş-komponentli production entry \`BootstrapOnly\` qalır; Stage5/main/merge yoxdur.

**NEXT — birbaşa, hash-lə qorunan arxiv diferensialı:** Məhz release commit \`0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4\`-dəki Python faylını SHA doğrulaması ilə al; həmin orijinal \`oldDayTag\` / \`dayTagWithFoundationScar\` funksiyalarını \`F+[-3,-2,-1,0,1,2,3]\` və \`F±2^k\` (\`k=127,1025,4096,8192\`) daxil olmaqla 15 müxtəlif gün üzərində **birbaşa** icra et. Ayrı Rust test runner-i yalnız müstəqil normativ oracle və Rust candidate nəticələrini maşınla müqayisə oluna bilən fixture formasında istehsal etsin. 15-cüt doğrulamada \`RED=8, CONTROL=7, UNEXPECTED=0, PATCH_OK=15, CANDIDATE_OK=15\` tələb et; fərq varsa konkret (input, Python output, Rust output, oracle) şahidini göstər. CI \`completed/success\`, eyni code SHA, log və artifact olmadan yeni PASS iddia etmə. Bundan sonra Stage4 bağlanma şərtini ayrıca yoxla; Rust-un özündə mövcud olmayan tarixi nasazlığı uydurma.
