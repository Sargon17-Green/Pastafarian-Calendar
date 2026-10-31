# Mərhələ 4 / DISCOVERY02 — etiketdən günə preimage QA

**PROJECT_ID:** `PC-BRANCH-RUST-AZERBAIJANI`
**Branch:** `Rust+Azərbaycan-dili`
**Başlanğıc HEAD:** `6fe098754fbadb9e06e9efaf121d2499c1b043ff`
**Hökm:** yeni müsbət QA hazırlanıb; Native sübut hələ yoxdur. **Stage4 PASS deyil; EXPECTED_RED=NOT_CLAIMED.**

## Yeni fərqli yoxlama

Əvvəlki yoxlamalar gün seçib etiketin hesablanmasını ölçürdü; bu yoxlama müsbət etiketi birbaşa seçib ona uyğun tam günün mövcudluğunu yoxlayır. Tək `t`: `day=F+(t-1)/2`; cüt `t`: `day=F-t/2`, `F=-15055671`. `t=1,2` və `b∈{0,1,127,1025,4096,8192}`, `k∈[0,32]`, `m=2^b+11k+1` üçün `t=2m,2m-1` istifadə edilir: **2+6×33×2=398 deterministik hal**. Hər `t` üçün `candidate_day_tag(reconstructed_day)==t` və ayrıca `normative_oracle::day_count(reconstructed_day)==t` yoxlanır. Testlər sonludur və giriş BigInt məhdudlaşdırılmır.

## Native CI qəbul şərti

`tests/stage04_discovery02_properties.rs` test funksiyalarını 2-dən 3-ə qaldırır. `.github/workflows/rust-az-stage04-discovery02.yml` yeni `STAGE04_DISCOVERY02_TAG_PREIMAGE_CASES=398` işarəsini və 3 testli qrupun uğurunu tələb edir. Stage1/2/3 regresiya, SAVE, Names Lock və beş-komponentli bootstrap dəyişmir.

Yalnız həmin yeni commit üçün `completed/success`, format, test sayları və job stdout/stderr doğrulandıqdan sonra yeni **müsbət QA** keçmiş sayıla bilər. Həqiqi tarixi legacy day-tag və faktiki fərq hələ aşkarlanmayıb: EXPECTED_RED və Stage4 closure iddia edilmir. Əgər konkret mənbə tapılarsa, versiya və giriş/çıxışı ayrıca oracle ilə reproduksiya edilməlidir.
