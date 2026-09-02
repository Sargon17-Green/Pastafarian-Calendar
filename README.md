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

## Sınaq əmri

Rust alət zənciri olan mühitdə layihənin kökündən bu əmri işlətmək lazımdır:

```text
cargo test --all-targets
```

Bu paket hazırlanarkən mövcud icra mühitində `rustc` və `cargo` tapılmadığı üçün sınaqlar faktiki icra olunmayıb. Buna görə bu handoff təsdiqlənmiş `GREEN` kimi təqdim edilmir.
