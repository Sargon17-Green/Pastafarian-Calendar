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
