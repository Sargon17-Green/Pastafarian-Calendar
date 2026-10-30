# Mərhələ 3 — PATCH01: normativ SAVE müqaviləsi

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`  
**Tarix:** 2026-10-30  
**Başlanğıc SHA:** `fe4607ec99b10b6b0f6781c63ad6c2e730577064`  
**Qapı:** Stage2/DISCOVERY01 native təsdiq olunub; Stage3 native nəticəsi hələ təsdiq edilməyib.

## Məna və sərhəd

Bu mərhələ yalnız əvvəlki DISCOVERY01 ilə sübut edilmiş sıfır-qalıq səhvini aradan qaldırır. `M = 2^127 - 1 = 170141183460469231731687303715884105727`.

```text
SAVE(x) = 1 + mod_floor(x - 1, M), hər bir işarəli BigInt x üçün
1 <= SAVE(x) <= M
SAVE(x + kM) = SAVE(x), hər bir tam k üçün
```

`src/patch01_save.rs` içində `normative_save(&BigInt) -> BigInt` hasil edilir, `SavePatch01` `PhaseHandler` ilə real `MonsterManager` dispetçerinə bağlanır, hər çağırışın `MonsterContext.save_observation` sahəsi və ayrıca `patch01.save.calls` metrikası olur. `calculate_save(BigInt) -> Result<SavePatchObservation, MonsterError>` istehsal girişidir. Heç bir daraldıcı tam ədəd tipi, üzən-nöqtə hesabı, qlobal mutasiya, test-oracle importu və xarici runtime istifadə edilmir.

`src/discovery01_legacy_save.rs` və `legacy_remainder` dəyişdirilmir. Sınaq oracle-ı yalnız `tests/support/normative_oracle.rs` daxilində qalır. Dondurulmuş kataloq dəyişdirilmir. `calendar_date_spaghetti` hələ beş nəticəni qaytarmır; Stage3 bütöv təqvim deyil.

## Məcburi sınaqlar

1. Səkkiz dəqiq sərhəd: `0`, `M`, `2M`, `3M`, `M+1`, `-M`, `-1`, `1`; gözlənilənlər müstəqil oracle ilə eyni olmalıdır.
2. Çox böyük müsbət/mənfi `BigInt` (320 və 640 bitdən böyük), `x±M` invariantı, `[1,M]` həddi, girişin dəyişməməsi və invokasiyalararası izolyasiya.
3. Legacy müşahidəsində 3 `EXPECTED_RED` və 1 `CONTROL` qorunmalıdır. Yeni SAVE yalnız patch marşrutunda işləməlidir.
4. Stage1 16/16 və Stage2 3/3 reqressiyası, Stage3 4/4 test; `cargo fmt --all -- --check`, `cargo test --all-targets -- --nocapture`, Canonical Names Lock.
5. Yalnız eyni yeni code SHA üzrə GitHub Actions completed/success və log, artifact yoxlanandan sonra Stage3 PASS. `CURRENT_STAGE=3`, `LAST_COMPLETED_STAGE=2`, `EXPECTED_REPOSITORY_STATE=PATCH01_PENDING_NATIVE` yazılır.

`main` dəyişdirilmir, merge edilmir, sonrakı mərhələlər qabaqcadan tətbiq edilmir.
