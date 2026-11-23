# Stage06 / DISCOVERY03 — bounded 46×5 stone-sequence probe

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
PARENT_SHA=723661da73bf802f28d76ffca4f19f6c312bf582
STATUS=OPEN_NOT_ACCEPTED
CURRENT_STAGE=6
LAST_COMPLETED_STAGE=5
KIND=DISCOVERY03
HISTORICAL_RUST_RED=NOT_CLAIMED

## Məhdud əhatə və əsaslandırma

Stage05-də iki-gün WorkCounts qəbul edilib. Normativ sınaq spesifikasiyasının növbəti hesablanan asılılığı 46 daşdan ibarət, beş sütunlu dəyişməz cədvəldir. Bu mərhələ onun ayrıca Rust zondunu yaradır. Test oracle-ı istehsal koduna ötürülmür və başqa dildəki kod/fiks­tur köçürülmür. İstifadə olunan yeganə hesablayıcı asılılıq qəbul edilmiş PATCH01 `normative_save` funksiyasıdır. `calendar_date_spaghetti` əvvəlki kimi `BootstrapOnly` qaytarır.

## Ölçülən müqavilə

Giriş: parametrsiz `candidate_stones()`; `M=2^127-1`, `SAVE(x)=1+((x-1) mod M)`.

Çıxış: ardıcıllıq `S[1..46]`, hər `S[i]` beş müsbət `BigInt` sahəsidir. Başlanğıc `S[1]=[17,29,43,71,101]`. `i=2..46`, `j=0..4`, əmsallar `k=[3,5,7,11,13]`:
`S[i][j]=SAVE(S[i-1][j]^2 + k[j]*S[i-1][(j+1)%5] + (i if j=0 else S[i-1][j-1]))`.

Əl ilə yoxlanmış ikinci sətir `[378,1073,2375,6195,10493]`. Bütün 230 ədəd `[1,M]` intervalındadır. Giriş yoxdur, heç bir `i64` daralması, xarici dil runtime-ı, qlobal vəziyyət və ya qaytarılan mutable keş yoxdur.

## Qapılar

1. Statik: yalnız Stage06 `src/discovery03_stone_probe.rs` modulunu əlavə edir; əvvəlki Rust istehsal funksiyalarını və kanonik mənbə-ad kataloqunu dəyişmir.
2. Rust Native: bütün 230 dəyər test-only müstəqil `tests/support/normative_oracle.rs::build_stones` ilə müqayisə olunur; ayrıca ilk iki sətirin sabit hesabı, 230 aralıq yoxlaması və eyni nəticəni ikinci çağırışda təkrar alma yoxlanır.
3. Stage01–Stage05 Native regressiyası, `cargo fmt --all -- --check`, `cargo test --all-targets -- --nocapture`, Names Lock, Stage04 bütün mərhələ gate-i qalmalıdır.
4. Tam beş sahəli giriş hələ `BootstrapOnly`; tarixi Rust `EXPECTED_RED` barədə yeni iddia yoxdur.
5. Dəqiq yeni SHA üzrə `completed/success` run, job və decoded checkout log; ZIP hash, CRC, `sha.txt` PROJECT_ID/SHA, `exit.txt=0`, test markers və test olmayan hadisənin ayrıca təsdiqi olmadan Stage06 ACCEPTED deyil.

Gələcək CI `STAGE06_DISCOVERY03_NATIVE=PASS` yaza bilər, amma `STAGE06_CLOSURE=NOT_CLAIMED` qalır; ayrıca audit/kabul tələb olunur. `main`, merge, Stage07 və dərc yoxdur.
