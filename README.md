# Pastafarian təqvimi — Rust + Azərbaycan dili

Bu ağac yeni və müstəqil tətbiq xəttinin birinci mərhələsidir. Layihə başqa tətbiqdən köçürülməyib və normativ məna yalnız tapşırığa daxil edilmiş istinaddan götürülür.

## Birinci mərhələnin sərhədi

Bu mərhələdə yalnız neytral başlanğıc infrastrukturu yaradılır:

- `MonsterContext` üçün əsas çağırış vəziyyəti;
- `MonsterDispatcher` üçün əsas dispetçer;
- `MonsterValidationManager` üçün əsas yoxlama sərhədi;
- `MonsterErrorBoundary` üçün neytral xəta sarğısı;
- müşahidə üçün metrik və jurnal qabığı;
- tam və dondurulmuş `SourceLanguageCatalog`;
- yalnız sınaqlarda istifadə olunan normativ oracle;
- eyni Rust xəttində yaradılmış sınaq və sadə gözlənilən qiymətlər.

Gələcək tarixi qüsurlar, köhnə yollar və yamaqlar bu mərhələdə qəsdən yoxdur. `calendar_date_spaghetti` hələ normativ istehsal cavabı vermir; bu, gələcək mərhələlərin işini qabaqcadan daxil etməmək üçündür.

## Mənbə dili

Layihənin yeganə insan mətn dili Azərbaycan dilidir. Normativ ad seçimi mətnə görə deyil, yalnız sabit `canonical_index` qiymətinə görə aparılır. Təqdimat mətnləri yalnız son qatdadır və sıralama, dərəcə açma, keş açarı və ya normativ seçimə təsir etmir.

Kataloq qaydaları `docs/SOURCE_LANGUAGE_CATALOG.md` sənədində verilib.

## Dəqiq tam ədədlər

Normativ tam ədəd sahəsini məhdudlaşdırmamaq üçün skelet və sınaq oracle-ı saf Rust paketləri olan `num-bigint`, `num-integer` və `num-traits` istifadə edir. Layihə kodunda xarici dil runtime-ı, FFI və ya başqa dildə oracle yoxdur. Redaktə, arxivləmə və iş sahəsinin hazırlanması üçün istifadə olunan xarici alətlər layihə kodunun bir hissəsi sayılmır.

## Sınaq əmri və təsdiqlənmiş nəticə

Rust alət zənciri olan mühitdə layihənin kökündən:

```text
cargo test --all-targets
```

2026-10-30 tarixli GitHub Actions Native run 41040357894 (SHA `1bcd853e4a3a9a5bb3498d43c1e1728e23949274`) bu əmri tamamladı: 16 sınaq uğurlu, 0 uğursuz. Compiler 37 warning göstərdi (əsasən test oracle-ındakı istifadəsiz elementlər); bunlar error deyil. Canonical Names Lock run 41040357441 də eyni SHA üzrə SUCCESS oldu. Ətraflı sübut: `audit/STAGE_01_EXECUTION_STATUS.txt`.

Stage 1 yalnız BOOTSTRAP üçün tamamlanıb. Tarix hesablamasının beş komponenti və növbəti mərhələlər hələ təsdiqlənməyib.

## Mərhələ 2 — DISCOVERY 01: həqiqi Legacy SAVE yolu

Kanonik Stage2 müqaviləsi artıq [sənəddə](audit/STAGE_02_DISCOVERY01_SAVE_CONTRACT_2026-10-30.md) müəyyənləşib. `M=2^127−1` üçün köhnə `regularMod(x,M)` hesabı `x=M,2M,3M` hallarında `0` verir, amma normativ `SAVE(x)=M`; `M+1` nəzarət halında hər iki yol `1` verir. Bu, 3 qəsdən yanlış tarixi nəticə və 1 uyğun nəzarətdir.

`src/discovery01_legacy_save.rs` real `MonsterManager` dispatcher yolu və çağırışa məxsus `MonsterContext` ilə nəticəni dəyişdirmədən qaytarır. `tests/stage02_discovery01.rs` normativ nəticəni yalnız test oracle-dan alır, signed və böyük BigInt-i yoxlayır, tarix üçün beş sahənin uydurulmadığını təsdiqləyir. CI: `.github/workflows/rust-az-stage02-discovery01.yml`.

**CURRENT_STAGE=2, LAST_COMPLETED_STAGE=2. Stage2 DISCOVERY01 Native PASS təsdiqləndi.** 2026-10-30 tarixli eyni `b818990de4da5a66a0765cb9bf53942daeabdfde` SHA-da `cargo fmt --all -- --check`, 16 Stage1 regressiya testi, 3 Stage2 testi (3 EXPECTED_RED, 1 CONTROL, 0 UNEXPECTED) və Canonical Names Lock uğurla başa çatdı. [Native sübut](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41097634181), [regressiya](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41097634069), [ad kilidi](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41097633885), [audit](audit/STAGE_02_EXECUTION_STATUS_2026-10-30.md). Bu, qəsdən səhv qalan legacy yolu düzəltmir: `SAVE` üçün PATCH01 Stage3-də ayrıca həyata keçiriləcək. Stage3/PATCH01 sonradan eyni xəttdə Native sınaqlarla qəbul edilib; `main` və `calendar_date_spaghetti` dəyişməyib.

## Mərhələ 3 — PATCH01: normativ SAVE (Native təsdiqlənib)

`audit/STAGE_03_PATCH01_SAVE_CONTRACT_2026-10-30.md` müqaviləsinə əsasən `M=2^127−1` üçün `SAVE(x)=1+mod_floor(x−1,M)` istehsal yolu `src/patch01_save.rs` daxilində tətbiq edilib. `MonsterManager` dispetçeri və hər çağırışın ayrıca konteksti saxlanılır. Stage2-dəki `legacy_remainder` dəyişdirilməyib, test oracle istehsal koduna köçürülməyib.

**CURRENT_STAGE=3, LAST_COMPLETED_STAGE=3. Stage3/PATCH01 Native PASS yalnız bu mərhələnin müqaviləsi çərçivəsində təsdiq edilib.** Eyni istehsal SHA `932e35d466595477827a09dafb50a97157f5ee65` üzərində `cargo fmt --all -- --check`, Stage1 **16/16**, Stage2 **3/3**, Stage3 **4/4** testləri, səkkiz sərhəd, signed böyük BigInt və `STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0` imzası uğurludur. [Stage3 Native](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421059), [Stage2 Native](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421013), [Stage1 reqressiyası](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109420940), [Names Lock](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109420985) və [qəbul aktı](audit/STAGE_03_EXECUTION_STATUS_2026-10-30.md) təsdiqedici sübutdur. Bu yekun sənədləşdirmə kodu dəyişdirmir və yeni SHA üzrə test iddiası yaratmır.

**Qalan sərhəd:** `calendar_date_spaghetti` hələ beş tarix komponentini normativ şəkildə hesablamır. Stage4 və sonrakı mərhələlərin tərifi bu qəbul sənədindən çıxarılmır; yalnız mövcud ayrıca normativ müqavilə aşkar ediləndən sonra növbəti əməliyyata keçilməlidir. `main` birləşdirilmir.
