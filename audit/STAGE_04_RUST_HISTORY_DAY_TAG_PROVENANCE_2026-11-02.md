# Mərhələ 4 — Rust gün etiketi üçün tarixi mənbə yoxlaması (2026-11-02)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
İşçi filial: Rust+Azərbaycan-dili
Araşdırılan HEAD: `0aa4280ada842d96418c4c862dc5affe2a52036a`
Mərhələ vəziyyəti: OPEN / CURRENT_STAGE=4 / LAST_COMPLETED_STAGE=3
İstehsal statusu: BootstrapOnly. Bu sənəd Stage4 PASS və ya EXPECTED_RED iddiası deyil.

## Ölçülmüş əhatə dairəsi

Yeni, konkret tarixli Rust gün-etiketi yolunun olub-olmadığını yoxlamaq üçün yalnız bu filialın `src` tarixçəsi, Stage1 və Stage3 Git ağacları və Stage4-ün ilk dəyişikliyi araşdırıldı. Ümumi bütün filiallar və izlənməyən fayllar axtarılmadı.

- Stage1 mənbə SHA: `9a46739c981605875958f9b167bad6049f01fa79` (2026-09-02). Git ağacı: 22 yol, `truncated=false`; istehsal Rust mənbələri `src/lib.rs` (blob `c981aaae35e375ca98634d414bf761e7d0e95119`) və `src/source_language_catalog.rs` (blob `dfceca5be541e3911119b95145aa391c0a3bc54f`).
- Stage3 bağlanma SHA: `716e5a6f335b1a15464029b446edb468f3a8482c` (2026-10-30). Git ağacı: 38 yol, `truncated=false`; istehsal Rust mənbələri `src/lib.rs` (blob `8a813ba020c9101276007148c93cb00ae7836644`), `src/discovery01_legacy_save.rs` (blob `dcf5734b88a8ddb45cea00f9b6f8b8d550549ed2`), `src/patch01_save.rs` (blob `69802695826650c3f2db8bfc742d49dccb412dec`), `src/source_language_catalog.rs` (blob `0106ec0b12dd9089481f5be3aeee8b72bb6a0705`).
- Bu iki tam snapshot-un bütün istehsal Rust fayllarının məzmunu ayrıca oxundu. `day_tag`, `dayTag`, `day_count`, `foundation` üçün məzmun yoxlamasında istehsal gün-etiketi alqoritmi tapılmadı. `src/lib.rs::calendar_date_spaghetti` hər iki snapshot-da var, lakin `BootstrapOnly` qaytarır; bu, legacy day-tag marşrutu deyil.
- Eyni Stage3-də `tests/support/normative_oracle.rs` (blob `8881f34deadecf43a2c897088b791f4892a160db`) `day_count` funksiyasını ehtiva edir; Stage1-də də həmin blob mövcuddur. `tests/support` test oracle-ıdır, istehsal `src` yolu deyil.

## Versiya dəyişikliyi yoxlaması

Bu filialın `src` yolu üzrə GitHub commit tarixindən Stage4-ün ilk implementasiyasından *əvvəl* olan səkkiz Rust mənbə dəyişikliyi seçildi. Hər bir commit-in `src/**` file diff-i oxundu; əlavə edilən sətrlərdə `day_tag`, `dayTag`, `day_count` və `foundation` üçün uyğunluqlar: **0**.

| SHA (qısa) | Yoxlanılmış `src` dəyişikliyi |
|---|---|
| `9a46739c` | lib.rs, source_language_catalog.rs |
| `301d25cb` | source_language_catalog.rs |
| `0c32cfc` | source_language_catalog.rs |
| `fd31a099` | lib.rs |
| `f6ce3fa8` | discovery01_legacy_save.rs |
| `b818990d` | discovery01_legacy_save.rs, lib.rs |
| `805827c2` | lib.rs, patch01_save.rs |
| `932e35d4` | patch01_save.rs |

GitHub müqayisəsi `716e5a6f... ` → `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f` üçün `ahead_by=1`, `behind_by=0`, `status=ahead` göstərdi. Məhz bu Stage4 ilk commit-i `src/discovery02_day_tag_probe.rs` faylını *yeni* əlavə etdi. Bu namizəd tarixən işləyən Stage1–3 legacy gün-etiketi deyil.

## Nəticə və hüdud

Yeni təsdiqlənmiş tarixi Rust gün-etiketi mənbə/işləmə marşrutu aşkar **edilmədi**. Bu, məhz sadalanan Git snapshot-ları və commit diff-ləri barədə mənfi nəticədir; bütün mümkün izlənməyən arxivlər və müstəqil filiallar barədə qəti yoxluq sübutu deyil. Python+Türkçe arxivindəki əvvəlki 8 RED Rust filialının tarixi qüsuru sayılmır (bu arxiv Rust HEAD-in əcdadı deyil). Rust-da tarixi RED müşahidəsi: **0 təsdiqlənmiş**, uydurulmuş nümunə yoxdur.

Yoxlama həcmi: 2 tam Git ağacı, həmin ağaclardakı 2+4 istehsal mənbə məzmunu, 1 müstəqil test oracle-ı, 8 konkret istehsal `src` diff-i, 1 Stage3→Stage4 ancestry müqayisəsi. Bu araşdırma yeni Native çalışdırma və ya yeni test PASS deyil; əvvəlki 34/34 Native və 6/6 TSV uğuru yalnız `0aa4280ada842d96418c4c862dc5affe2a52036a` üçün qüvvədədir.

NEXT: yalnız **yeni, konkret, commit ilə versiyalanmış və əvvəl işləyən Rust gün-etiketi yolu** müəyyən edildikdə onu mənbə SHA/blob, çağırış marşrutu və real input/output ilə sabitləşdir; ayrı normativ oracle ilə fərqi yenidən işlət. Belə şahid olmadan Stage04 bağlanmır; Stage05 açılmır. Stage3 SAVE, adlar, BootstrapOnly, main və merge dəyişmir.

## Təkrarlana bilən mənbələr
- Git src tarixi: https://github.com/Sargon17-Green/Pastafarian-Calendar/commits/Rust%2BAz%C9%99rbaycan-dili/src
- Stage1: https://github.com/Sargon17-Green/Pastafarian-Calendar/tree/9a46739c981605875958f9b167bad6049f01fa79/src
- Stage3: https://github.com/Sargon17-Green/Pastafarian-Calendar/tree/716e5a6f335b1a15464029b446edb468f3a8482c/src
- Stage3 independent oracle: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/716e5a6f335b1a15464029b446edb468f3a8482c/tests/support/normative_oracle.rs
- Stage4 initial implementation: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f
- Prior ancestry and eligibility: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/0aa4280ada842d96418c4c862dc5affe2a52036a/audit/STAGE_04_CLOSURE_ELIGIBILITY_AND_TSV_QA_2026-11-01.md
