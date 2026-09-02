# Mərhələ 1 statik audit

Bu sənəd faktiki Rust icrasını əvəz etmir. Məqsəd icradan əvvəl Bootstrap tərkibinin tapşırıq sərhədlərinə uyğunluğunu yoxlamaqdır.

## Yoxlanılan tərkib

- layihə ağacı sıfırdan yaradılıb;
- production kodu Rust-dur;
- oracle və bütün test kodu Rust-dur;
- shell faylı yalnız `cargo test --all-targets` çağırır və hesablama məntiqi daşımır;
- FFI, xarici interpreter, WASM körpüsü və başqa dildə layihə oracle-ı yoxdur;
- normativ hesabda floating point tipi və ya çevrilməsi yoxdur;
- `BigInt` və `BigUint` dəqiq tam ədəd hesabı üçün istifadə olunur;
- `SourceLanguageCatalog` versiyası `az-1` kimi dondurulub;
- 17 kotlet və 47 ay adı həm indeks, həm exact Azərbaycan dili mətni üzrə test fixture ilə bağlanıb;
- semantik ad sırası yalnız `canonical_index` ilə aparılır;
- tam test-only normativ oracle daşlar, gizli və görünən damcılar, kasalar, A1 qarışdırması, cavab axını, qısa/geniş seçim, darvazalar, illər, kompozisiyalar, ad dərəcəsi, ay uzunluqları, toxunuş və beş sahəli nəticə yolunu əhatə edir;
- A1 oxunuşunda saxlanılan qiymət `SAVE(sum(oldBowls) + 149 * stirNumber)` kimi həm sıra üçün, həm kasa düsturuna əlavə üçün istifadə olunur;
- il maksimumu oracle-da `5778`-dir; gələcək `5781` legacy sabiti production-a qabaqcadan daxil edilməyib;
- production Stage 1-də gələcək 26 qüsur/yamaq yolları yoxdur;
- neytral `MonsterContext`, dispetçer, validator, xəta sərhədi, metrik və jurnal qabığı mövcuddur;
- oracle production moduluna import edilmir və `calendar_date_spaghetti` tərəfindən çağırılmır;
- semantik vəziyyət iki invocation arasında paylaşılmır; mövcud müşahidə vəziyyəti normativ giriş kimi oxunmur.

## Açıq qalan yeganə yoxlama

Bu mühitdə `rustc` və `cargo` olmadığı üçün kompilyasiya və test icrası edilməyib. Buna görə sintaksis, trait həlli, borrow checker və runtime nəticələri yalnız real Rust alət zəncirində təsdiqlənə bilər. Mərhələ 1-in tamamlanması üçün `cargo test --all-targets` uğurla bitməlidir.
