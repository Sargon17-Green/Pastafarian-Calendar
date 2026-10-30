# Mərhələ 4 — DISCOVERY02: gün etiketinin müstəqil baza tədqiqi

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`
**Başlanğıc HEAD:** `716e5a6f335b1a15464029b446edb468f3a8482c`
**Qapı:** Stage3/PATCH01 üçün Native sübutu təsdiqlənib; Stage4 hələ PASS deyil.

## Namizəd və mənfi sübutun sərhədi

Növbəti müstəqil mövzu təməl günün ətrafındakı **gün-sayğacı**dır (`day_count`). Mənbə: bu filialda dondurulmuş `tests/support/normative_oracle.rs::day_count`; həmin fayl istehsal koduna idxal edilmir. Aşağıdakı sınaq **müsbət baza**dır: mövcud Rust mənbəyində tarixən işləyən ayrıca `oldDayTag`/legacy day-tag yolu tapılmayıb. Buna görə heç bir uydurma tarixi qüsur, EXPECTED_RED və ya Stage4 PASS iddia edilmir.

`src/discovery02_day_tag_probe.rs::candidate_day_tag(&BigInt)->BigInt` təqvimin istehsal girişinə qoşulmayan sınaq namizədidir. Orijinal SAVE (`src/patch01_save.rs`) və legacy SAVE (`src/discovery01_legacy_save.rs`) toxunulmaz saxlanılır.

## Riyazi müqavilə

`F = -15_055_671`, `d = day-F`, `tag = 2*abs(d) + [d >= 0]`.

- Giriş: istənilən işarəli, ölçüsü məhdudlaşdırılmamış `BigInt`; giriş dəyişmir.
- Çıxış: müsbət `BigInt`; `day=F` olduqda 1; `day<F` olduqda cüt, `day>=F` olduqda tək.
- Tərsinə çevrilmə: tək `tag` üçün `F+(tag-1)/2`; cüt üçün `F-tag/2`.
- Sərhədlər: `F-3 ... F+3` üçün dəqiq `6,4,2,1,3,5,7`; əlavə 1025+ bit işarəli müsbət/mənfi fərqlər.
- Müstəqil yoxlayıcı: `tests/support/normative_oracle.rs::day_count` (istehsala daxil deyil), tərsinə çevrilmə və paritet yoxlamaları.
- SAVE qorunur: hər sınaqdan əvvəl/sonra `calculate_save`, `observe_legacy_save`, `oracle::save`; beş komponentli ümumi giriş `BootstrapOnly` qaytarmalıdır.

## Ölçülə bilən ara qapı

`cargo fmt --all -- --check`; `cargo test --all-targets -- --nocapture`; Stage1/2/3 reqressiya; Stage4 üç test funksiyası, yeddi dəqiq sərhəd və dörd böyük ədəd. Native CI logları yalnız `completed/success` olduqda və eyni code SHA üzrə yoxlananda **baza** təsdiqlənə bilər. Bu ara qapı Stage4 yekunu deyil.

## Stage4-ü bağlamaq üçün çatışmayan sübut

1. Həqiqi legacy day-tag tətbiqi, tarixi dəyişiklik və ya təkrar istehsal edilən qüsurlu marşrut müəyyən edilsin; fərz edilən yanlış alqoritm yazılmasın.
2. Mövcud proqram yolunun müstəqil oracle-dan fərqləndiyi konkret giriş/çıxış yerində müşahidə edilsin; yalnız bundan sonra sayılan EXPECTED_RED və CONTROL sınaqları tərtib edilsin.
3. Stage3 SAVE semantikası, katalog və bootstrap müqaviləsi qorunsun. Native və Names Lock qapıları keçilmədən Stage4 bağlanmasın.

`main`/merge yoxdur; tam təqvim iddiası yoxdur.
