# Mərhələ 2 — DISCOVERY 01: sıfır qalıq SAVE ola bilməz

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Tarix:** 2026-10-30  
**Mənbə:** cari Rust test oracle-ı və əvvəlki DISCOVERY01/PATCH01 mərhələsini keçən COBOL, TypeScript, PHP, C++ və Kotlin budaqları. Bu, yeni qüsur icadı deyil.  
**Qərar:** Stage2 konkret qüsur və API artıq müəyyənləşdi; əlavə istifadəçi icazəsi tələb olunmur. Stage1 yalnız bootstrap kimi qəbul edilmişdir.

## Kanonik kontrakt — Rust test müstəqil mənbəsi

`tests/support/normative_oracle.rs` daxilində:
```rust
pub fn m_bigint() -> BigInt { (BigInt::one() << 127usize) - BigInt::one() }
pub fn regular_mod(x: &BigInt, d: &BigInt) -> BigInt { x.mod_floor(d) }
pub fn save(x: BigInt) -> BigInt {
    let m = m_bigint();
    BigInt::one() + regular_mod(&(x - BigInt::one()), &m)
}
```
Yəni `M=2^127−1=170141183460469231731687303715884105727` üçün `SAVE(x) ∈ [1,M]`. Tarixi köhnə yol belədir:
```text
legacyRemainder(x) = regular_mod(x, M)    // 0..M−1; sifır səhvi
normativeSAVE(x)  = 1 + regular_mod(x−1, M) // 1..M
```
Giriş: istənilən işarəli `num_bigint::BigInt`. Nəticə: yeni, müstəqil `BigInt`, heç bir `u64/i64`-a daraltma, `float`, xarici runtime, mutable global cache və test oracle importu yoxdur.

## Dəqiq hadisələr

| x | Tarixi `regular_mod(x,M)` | SAVE norması | Nəticə |
| --- | --- | --- | --- |
| M | 0 | M | EXPECTED_RED |
| 2M | 0 | M | EXPECTED_RED |
| 3M | 0 | M | EXPECTED_RED |
| M+1 | 1 | 1 | CONTROL |

Bunlar COBOL Stage2 Native-də də təsdiq olunub (2026-10-30; 3 red və 1 control). Əlavə regressiya: `0` və `−M` RED, `−1` üçün normal pozitiv modul və SAVE uyğunluğu; böyük müsbət/mənfi `BigInt` nöqtələri və caller ownership.

## Giriş və çıxış API / real istehsal yol

`src/discovery01_legacy_save.rs` əlavə edilir:
- `pub fn legacy_remainder(x: &BigInt) -> BigInt` — tarixi nəticəni düzəlişsiz qaytarır;
- `LegacySaveDiscovery01` `PhaseHandler` tətbiq edir, real `MonsterManager` dispetçerindən keçərək tək çağırışa məxsus `MonsterContext` daxilində `legacy_save_observation` sahəsini doldurur.
- `pub fn observe_legacy_save(x: BigInt) -> Result<LegacySaveObservation, MonsterError>`: tarixi nəticə, orijinal giriş və istehsal konteksti; yalnız Rust, ayrı invocation, trace və metrics.
- `calendar_date_spaghetti` Stage2-də hələ 5 nəticəni hesablaya bilməz; boşluğu həqiqi tarix API kimi qələmə vermək qadağandır.

Stage2 yalnız kəşfdir. `SAVE` sıfır qalıqda `M` verəcək `PATCH01` Stage3-də ayrıca həyata keçiriləcək; legacy yol saxlanacaq.

## Test/CI qəbul şərtləri

1. İstehsal yolunun gerçək handler ilə işlədiyi, hər çağırışın öz konteksti və metric-i olduğu, inputun dəyişmədiyi, oracle modulunun `src/` daxilində olmadığı sübut edilməlidir.
2. `tests/stage02_discovery01.rs` girişləri üzrə dörd dəqiq müqayisə: **3 EXPECTED_RED, 1 CONTROL**, heç bir gözlənilməz fərq yoxdur; böyük `BigInt` və mənfi inputlar da yoxlanılır. Normativ gözlənilənlər `tests/support/normative_oracle.rs`-dən alınır, production hesabı oracle kodu ilə təkrar etmir.
3. `cargo fmt --check`, `cargo test --all-targets`, Canonical Names Lock və Stage1 16/16 regressiyası eyni HEAD üzərində Native GitHub Actions. Nəticə və SHA yoxlanmadan Stage2 tamamlanmış sayılmır. Bir neçə qaçışın queued olması şaxənin `READY` işlənməsinə mane olmur.
4. `CURRENT_STAGE=2`, `LAST_COMPLETED_STAGE=1`, `EXPECTED_REPOSITORY_STATE=EXPECTED_RED_PENDING_NATIVE` — icra başlananda; Stage3 heç bir halda öncədən açıla bilməz.
5. `main`-a merge etməyin, test-only oracle-ı istehsala gətirməyin və source language catalog-unu dəyişməyin.

## Əsası olan istinadlar

- [Rust Stage1 oracle — real SAVE tərifi](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/Rust%2BAz%C9%99rbaycan-dili/tests/support/normative_oracle.rs)
- [COBOL Stage2 Native Discovery01](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41032602303)
- [COBOL Stage3 Native Patch01](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040504858)
- [PHP Stage2–3 history](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/PHP%2BBahasa-Melayu/SPAGHETTI_DEVELOPMENT_HISTORY.md)

`audit/STAGE_02_DISCOVERY_GATE.md` əvvəlcə mövcud mənbə boşluğunu təsvir etmişdi; indiki kontrakt bu boşluğu bağlayır, o tarixi sənəd silinmir.
