# Mərhələ 1 handoff

## Vəziyyət

Bootstrap tərkibi statik baxımdan tamamlanıb. Faktiki Rust icrası bu mühitdə alət zənciri olmadığı üçün edilməyib. Buna görə `LAST_COMPLETED_STAGE=0` saxlanılır və paket real `cargo test --all-targets` nəticəsindən sonra GREEN kimi bağlanmalıdır.

## Əlavə və dəyişdirilmiş fayllar

- `Cargo.toml`
- `src/lib.rs`
- `src/source_language_catalog.rs`
- `tests/stage01.rs`
- `tests/support/mod.rs`
- `tests/support/normative_oracle.rs`
- `README.md`
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`
- `DEVELOPMENT_STAGE.md`
- `docs/ARCHITECTURE.md`
- `docs/SOURCE_LANGUAGE_CATALOG.md`
- `audit/STAGE_01_TEST_PLAN.md`
- `audit/STAGE_01_STATIC_AUDIT.md`
- `audit/STAGE_01_EXECUTION_STATUS.txt`
- `RUN_STAGE_01.sh`

Silinən fayl yoxdur.

## Yerli sınaq əmri

```text
cargo test --all-targets
```

Gözlənilən nəticə: bütün Stage 1 sınaqları PASS və proses exit code `0`.

Faktiki nəticə: bu mühitdə `rustc` və `cargo` olmadığından icra olunmayıb.

## Təklif olunan commit başlığı

`Mərhələ 1: Rust və Azərbaycan dili üçün ilkin quruluş`

## Təklif olunan commit mətni

`Yeni və müstəqil Rust tətbiq xəttinin ilkin quruluşunu yaradır. Dondurulmuş Azərbaycan dili SourceLanguageCatalog-u, tam test-only normativ oracle, Rust sınaq dəsti və neytral MonsterContext/dispetçer/validator/xəta sərhədi/müşahidə qabığı əlavə olunur. Kataloq canonical_index və exact mətn fixture-ləri ilə bağlanır. Gələcək tarixi qüsur və yamaq kodu daxil edilmir.`

## GitHub üçün izah

`Bu dəyişiklik yalnız Mərhələ 1 üçündür. Tətbiq sıfırdan yaradılıb; başqa tətbiqin kodu, fixture-i, çıxışı, hash-i və differential nəticəsi istifadə edilməyib. Normativ oracle yalnız Rust sınaq qatındadır və production yolu ona müraciət etmir. SourceLanguageCatalog canonical_index sırası və exact Azərbaycan dili mətnləri ilə dondurulub. Production-da gələcək 26 legacy/yamaq yolundan heç biri qabaqcadan mövcud deyil.`

## İstifadəçi üçün son addım

Rust alət zənciri olan mühitdə paketin kökündə `cargo test --all-targets` işlədin. Yaşıl nəticənin logunu növbəti mesajda göndərin. Yalnız həmin nəticədən sonra `LAST_COMPLETED_STAGE=1` və faktiki GREEN icra statusu ilə Mərhələ 1 bağlanmalıdır.
