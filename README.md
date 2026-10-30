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

**CURRENT_STAGE=2, LAST_COMPLETED_STAGE=1. Stage2 Native PASS hələ təsdiqlənməyib.** GitHub Actions-ın bitməsini gözləmək şaxənin `READY` olmasına mane deyil; növbəti söhbətdə nəticə artıq yoxlanıla bilər. Stage3/PATCH01, `main` və semantik `calendar_date_spaghetti` dəyişməyib.
