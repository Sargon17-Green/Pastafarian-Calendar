# Mərhələ 3 — PATCH01: Native qəbul və bağlanma sübutu

Tarix: 2026-10-30
PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Budaq: Rust+Azərbaycan-dili
İstehsal kodu və bütün Native qapıları üçün eyni SHA: `932e35d466595477827a09dafb50a97157f5ee65`
CURRENT_STAGE=3
LAST_COMPLETED_STAGE=3
Nəticə: GREEN / STAGE3 PATCH01 COMPLETE (SAVE ONLY)

## Normativ hədd

M = 2^127 - 1 = 170141183460469231731687303715884105727.
`SAVE(x)=1+mod_floor(x-1,M)` bütün işarəli `BigInt` girişləri üçün `1..=M` aralığındadır və `SAVE(x+kM)=SAVE(x)` invariantını saxlayır. Normativ kod `src/patch01_save.rs` vasitəsilə istehsal `MonsterManager` dispetçerinə bağlanır. `MonsterContext.save_observation` çağırışa məxsusdur. Köhnə `src/discovery01_legacy_save.rs` və `legacy_remainder` yolu qorunub; oracle yalnız test kodunda saxlanılıb.

Məcburi müqavilə: [Stage3 PATCH01 SAVE müqaviləsi](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/932e35d466595477827a09dafb50a97157f5ee65/audit/STAGE_03_PATCH01_SAVE_CONTRACT_2026-10-30.md).

## Yerinə yetirilmiş GitHub Actions Native yoxlamaları

**Yoxlamalar məhz code SHA `932e35d466595477827a09dafb50a97157f5ee65` üçün completed/success nəticəsindədir; yalnız növbədə və ya icrada olan run PASS hesab edilmir.** Bu SHA-nın `Rust+Azərbaycan-dili` HEAD-i ilə eyniliyi ayrıca müqayisə ilə təsdiqlənib.

- Stage3 Native [run 41109421059](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421059), job 124247669456: `cargo fmt --all -- --check` PASS; `cargo test --all-targets -- --nocapture` PASS; Stage1 16/16, Stage2 3/3, Stage3 4/4, 0 failures.
- Stage2 Native [run 41109421013](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421013), job 124247669347: completed/success, `cargo fmt` və test regresiyası PASS; 16+3+4 testlər, 0 failures.
- Stage1 Native [run 41109420940](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109420940), job 124247669136: completed/success; Stage1 16/16, Stage2 3/3, Stage3 4/4, 0 failures.
- Canonical Names Lock [run 41109420985](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109420985), job 124247668683: completed/success.

Stage3 job-un real stdout məzmununda `STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0`, `STAGE03_PATCH01_BOUNDARY_OK=8`, `STAGE03_PATCH01_LEGACY_RED=3 CONTROL=1 UNEXPECTED=0` dəqiq imzaları var. Səkkiz sərhəd: 0, M, 2M, 3M, M+1, -M, -1, 1. 320/640 bitdən böyük müsbət/mənfi `BigInt`, dövrilik və çağırış izolyasiyası müstəqil oracle ilə sınaqdan keçirildi.

Artifact: [rust-az-stage03-native, ID 13003720839](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41109421059/artifacts/13003720839), ölçü 5,788 bayt, GitHub tərəfindən təsdiqlənmiş digest `sha256:9a4f75a1bbb5528bff0b30c180844595f66dd264a0f77f06aaa7c0e14a5f8897`, müddət 2026-11-29-a qədər.

## Əvvəlki qüsur və düzəliş

Əvvəlki SHA `805827c2790fca6d88a53126b4570447b09bd609` üzərində Stage3 və Stage2 run 41108912543 / 41108912212 `cargo fmt --check` qapısında uğursuz oldu, testlər işə düşmədi. Dəqiq üç formatlama fərqi [932e35d commitində](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/932e35d466595477827a09dafb50a97157f5ee65) `src/patch01_save.rs` və `tests/stage03_patch01.rs` fayllarında düzəldildi. Yeni runs yuxarıdakı uğurlu sübutdur, uğursuz köhnə SHA PASS kimi nəzərə alınmır.

Kompilyator `dead_code` xəbərdarlıqları və GitHub Actions Node.js deprecation xəbərdarlıqları mövcuddur; sıfır warning iddia edilmir. Bu xəbərdarlıqlar yuxarıdakı test qapılarını uğursuz etmədi.

## Qəbul hüdudu və növbəti iş

Stage3/PATCH01 yalnız normativ SAVE düzəlişini və əvvəlki təbəqələrin regresiyasını təsdiqləyir. `calendar_date_spaghetti` beş tarix komponentini hələ tətbiq etmir. Bu fayl Stage4 müqaviləsi yaratmır və `main` merge, release və ya bütün 55 mərhələnin qəbulunu bildirmir.

Bu audit və `DEVELOPMENT_STAGE.md` yenilənməsi **yalnız artıq yoxlanmış code SHA-nın qəbulunun sənədləşdirilməsidir**. Sənəd-bağlanma komitinin SHA-sında Native yenidən işlədilməsə, ona ayrıca yeni Native PASS aid edilməməlidir. Növbəti addım: mövcud normativ Stage4 tərifini aşkar etmək; dəqiq scope/API/test oracle/qəbul qapısı sənədləşdirilmədən Stage4 tətbiqinə başlamamaq.
