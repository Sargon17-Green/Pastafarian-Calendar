# Mərhələ 4 / DISCOVERY02 — legacy day-tag üçün mənbə yoxlaması

**Layihə:** PC-BRANCH-RUST-AZERBAIJANI
**Yoxlanılan başlanğıc HEAD:** `09bbf02b0d2d322463456b81cbfb8c5ddfc95fc4`
**Tarix:** 2026-10-31
**Nəticə:** məhdudlaşdırılmış mənbə yoxlamasında tarixi legacy day-tag yolu müəyyən edilmədi. Bu nəticə bütün tarixdə belə yolun heç vaxt mövcud olmadığını sübut etmir.

## Məhdud əhatə və müşahidələr

- Hədəf filialın `src/` siyahısı yoxlandı: `lib.rs`, `discovery01_legacy_save.rs`, `discovery02_day_tag_probe.rs`, `patch01_save.rs`, `source_language_catalog.rs`.
- `src/lib.rs` faylının bu filial üzrə tarixində beş kod komiti görünür: `9a46739c` (bootstrap), `fd31a099` (legacy SAVE), `b818990d` (format), `805827c2` (PATCH01 SAVE) və `2a7648c3` (DISCOVERY02 day-tag).
- `src/discovery02_day_tag_probe.rs` tarixində yalnız `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f` komiti görünür. Fayl özünü istehsala bağlı olmayan **müsbət baza namizədi** kimi müəyyən edir.
- `calendar_date_spaghetti` istehsal girişi hələ `BootstrapOnly` qaytarır; `src/lib.rs` içindəki yeganə day-tag modulu baza zondudur.
- `discovery01_legacy_save.rs` fərqli, əvvəlki SAVE davranışı üçündür; onu day-tag üçün tarixi qüsur kimi təqdim etmək olmaz.

Bu axtarış yalnız göstərilən filial, mənbə yolları və əlaqəli komit tarixçəsinə aiddir; başqa filiallar, xarici mənbələr və ya tarixən silinmiş, burada görünməyən fayllar barədə nəticə çıxarılmır.

## Yeni müstəqil QA qapısı

`tests/stage04_discovery02_properties.rs` faylı:
1. `F-512...F+512` üçün 1025 giriş: oracle uyğunluğu, müsbət nəticə, injectivity, örtülən 1...1025 etiketləri və iki istiqamətli tam bərpa;
2. `2^1, 2^127, 2^1025, 2^4096` uzaqlıqlarında 8 BigInt giriş: simmetriya, həmişə tək/cüt, qonşu etiketlər və müstəqil oracle uyğunluğu.

Bu sınaqlar **yalnız yeni əlavə yoxlamalardır**, tarixi fərq/EXPECTED_RED deyil. Stage4 üçün Native nəticə, əvvəlki 26 regressiya və Names Lock yenidən yoxlanmalıdır. Cari mərhələ açıq qalır; tam təqvim və Stage4 PASS elan edilmir.

## NEXT

Konkret əvvəlki day-tag kodu, artefaktı və ya sənədləşdirilmiş tarixçəsi aşkarlanarsa, versiya və giriş/çıxışı qeyd edərək mövcud oracle-a qarşı təkrar istehsal et; yalnız real fərqdən sonra RED/CONTROL qapısını qur. Aşkarlanmadığı müddətdə tarixi qüsur uydurma və Stage4 bağlama.
