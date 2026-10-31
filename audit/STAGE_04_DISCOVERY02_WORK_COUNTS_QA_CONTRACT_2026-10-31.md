# Mərhələ 4 / DISCOVERY02 — iki günlük work_counts müsbət QA müqaviləsi

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`
**Branch:** `Rust+Azərbaycan-dili`
**Parent SHA:** `86704b287520b48f8cb8fce335c547bc48849faf`
**Status:** Stage4 hələ AÇIQDIR; bu dəyişiklik tarixi legacy qüsuru və EXPECTED_RED elan etmir.

## Giriş, çıxış və müstəqil oracle

`candidate_work_counts(calculation_day: &BigInt, target_day: &BigInt) -> CandidateWorkCounts` yalnız diaqnostik zondur; production `calendar_date_spaghetti` və beş komponentlik nəticə toxunulmaz qalır. Çıxış beş sahəlidir: `action`, `target`, `distance`, `connection` (BigInt), `direction` (u8). `action` və `target` mövcud `candidate_day_tag` vasitəsilə yaranır; `distance` daxil edilən iki sonluq arası mütləq fərq + 1; `connection=action+target`; `direction=1` geriyə, `2` eyni günə, `3` irəliyə. Girişlər dəyişdirilmir. Müqayisə üçün ayrı `tests/support/normative_oracle.rs::work_counts` istifadə olunur; production-a oracle kodu köçürülmür.

## Sonlu yoxlama kontraktı

- Lokal tam Dekart hasili: `F+[-3..3]` üçün 7×7=**49** cüt, bütün çıxış sahələri və girişin dəyişməməsi.
- İmzalı böyük BigInt: `F±2^b` üçün `b ∈ {127,1025,4096,8192}`, hər iki istiqamət: **8** cüt. Gözlənilən məsafə `2^(b+1)+1`; istiqamət və müstəqil oracle yoxlanır.
- Eyni translasiya: 4 əsas cüt × 3 sürüşmə (`0`, `2^127`, `-2^4096`) = **12** cüt; məsafə və istiqamətin invariantlığı, bütün sahələrin oracle ilə uyğunluğu.

Cəmi **69 cüt** və **3 yeni test**. CI-də `cargo fmt --all -- --check`, `cargo test --all-targets -- --nocapture`, üç dəqiq marker (`49/8/12`), əvvəlki Stage1/2/3/4 marker və RED/CONTROL qorunmalıdır. GitHub Actions yalnız `completed/success` və nəticə stdout/stderr ilə sübut ediləndə bu **müsbət QA** qəbul edilir. Nəticə olmadan Native PASS elan edilməz. Tarixi day-tag mənbəyi və həqiqi uyğunsuzluq tapılmadığı müddətcə Stage4 closure/EXPECTED_RED yoxdur.
