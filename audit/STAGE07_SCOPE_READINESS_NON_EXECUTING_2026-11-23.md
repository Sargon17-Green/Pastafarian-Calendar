# Rust+Azərbaycan-dili — Stage07 əhatəsinin dəlil-əsaslı yoxlanması (yalnız audit, 2026-11-23)

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
VERIFIED_START_HEAD=a5e1c884a7fe7f4204f48f22cae808ef38482959
TYPE=NON_EXECUTING_SCOPE_REVIEW
STAGE07_STARTED=NO
STAGE07_ACCEPTED=NO
PRODUCTION_CHANGE=NO
STAGE_COUNTER_CHANGE=NO
CURRENT_STAGE=6
LAST_COMPLETED_STAGE=6
EXPECTED_REPOSITORY_STATE=DISCOVERY03_STAGE06_ACCEPTED_HOLD_NO_STAGE07

## 1. Dəqiq mövcud vəziyyətin dəlilləri

Başlanğıc SHA ilə canlı `Rust+Azərbaycan-dili` ref-i müqayisəsi `identical / ahead=0 / behind=0` qaytardı. `DEVELOPMENT_STAGE.md` (blob `0fd1647fcffb4eaa6248536af5ede7a94bfa8371`) 6/6 sayğacını və `HOLD_NO_STAGE07` gözləmə vəziyyətini təsdiqləyir.

Stage04 avtomatik push run `45265086192`, job `138009791205`: `completed/success`; checkout tam SHA; format, 6 TSV yoxlaması, 16 provenance, 19 callability, mövcud Rust Native regressiyaları, original Rust/Python direct differential, səlahiyyət verilmiş 2026 rekonstruksiya müqaviləsi və bütün mərhələ uyarlığı addımları uğurludur. Artifact `14862556633`, 22619 bayt; GitHub metadata digest `sha256:568bc99cd1f220a4ec303bbcce054b5115cbe29e771f1998625bd33a8f728be9`. Əvvəlki müstəqil ZIP/CRC/exit/sha yoxlaması mərkəzi reyestrdə var; bu audit zamanı ZIP yenidən yüklənməyib.

Stage06 əvvəlki qəbul edilmiş sübut: run `45133979277`, job `137555725056`, `completed/success`, artifact `14798514936` (6860 bayt; GitHub metadata digest `sha256:e13c504eaff64e34aab46a8d398545a4c1d0ff42f85e16536c1f96d07e08df60`) əvvəlki SHA `5f2f178f3b10f2aac80ae281044bb655220ae163` üzərindədir. Bu, cari SHA üzrə yenidən Stage06 Native icrası demək deyil. Stage05 və Stage06 əvvəlki qəbul dəlilləri saxlanılır. Tarixi pre-Stage03 Rust RED sübutu yoxdur; xüsusi 2026 rekonstruksiya ayrıca etiketlənir.

## 2. Mənbələrin məhdud inventarı və qərar sərhədi

Cari SHA-nın repo kök, `docs/` və `audit/` adları yoxlanılıb. Açıq Stage07 məqsədini, onun növünü (DISCOVERY/PATCH), normativ son giriş/çıxış müqaviləsini və mərhələ səlahiyyətini bağlayan birbaşa `STAGE07` faylı tapılmayıb. `SPAGHETTI_DEVELOPMENT_HISTORY.md` yalnız ilkin mərhələnin izahını verir; `README.md` də sonrakı mərhələni əvvəlcədən müəyyən etmir. Ad inventarının yoxluğu başqa kanallarda sənədin olmamasını sübut etmir. Səlahiyyətin mərhələlər arasında ayrıca mərasimlə verilməsi tələbinin aradan qaldırılması, `HOLD_NO_STAGE07` üçün itmiş normativ spesifikasiyanı öz-özünə yaratmır.

`tests/support/normative_oracle.rs` (blob `8881f34deadecf43a2c897088b791f4892a160db`, yalnız test təbəqəsi) aşağıdakı ardıcıllığı ehtiva edir: `work_counts` → `build_stones` → `build_hidden_drops` → `build_visible_drops` → bowls. `src/discovery03_stone_probe.rs` (blob `5db024e1cd05fa497a4b62eede78f1df1f7bfb00`) 46×5 daşları hesablayır; `src/lib.rs` (blob `d396921819230944aa7ce6e8840204fbea5b8c68`) tam beş komponentli cavab üçün `BootstrapOnly` qaytarır. Buna görə yeddi gizli damcı hesabı növbəti **mümkün texniki asılılıqdır**, lakin Stage07-ni avtomatik müəyyən edən rəsmi norma deyil.

## 3. İcra edilməyəcək namizəd müqavilə — yeddi gizli damcı

**Yalnız plan namizədi; məhsul koduna və stage sayğaclarına tətbiq edilməyib.**

Giriş: dəyişməyən iki işarəli `BigInt` gün `calculation_day`, `target_day`. Stage05 `WorkCounts` sahələri `action, target, distance, connection, direction`; Stage06-nın 46×5 `Stone` cədvəli. `F=-15055671`, `P(d)=2*abs(d-F)+[d>=F]`; `action=P(calculation_day)`, `target=P(target_day)`, `distance=abs(target_day-calculation_day)+1`, `connection=action+target`; `direction=1,2,3` müvafiq olaraq hədəf əvvəl/eyni/sonra.

`M=2^127-1`, `SAVE(x)=1+mod_floor(x-1,M)`; bir nəticə `H[0..6]`, hər sahə müsbət `BigInt` və `1<=H[k]<=M`.

`C[k]=(a,b,c,d)` cərgələri:
`[(3,4,6,8),(5,7,10,12),(7,10,14,16),(9,13,18,20),(11,16,22,24),(13,19,26,28),(15,22,30,32)]`.
`G=[0,1,2,3,4,0,1]`.

`k=0..6` üçün `s=S[k]` və
`x_0=SAVE(action+a*target+b*distance+c*connection+d*direction+sum(s[0..4]))`.
`r=1..7` üçün
`x_r=SAVE(x_(r-1)^2+3*x_(r-1)+s[G[r-1]]+r)`.
`H[k]=x_7`.
Daşlar yalnız cari çağırışda oxunur; qlobal semantik vəziyyət, implicit `i64` daralması, xarici runtime və oracle importu qadağandır.

### Müstəqil, icrasız namizəd hesabın rəqəmli sanity-check-i

Ayrıca JavaScript `BigInt` hesabı (Rust kodu işə salınmadan) Stage06 daş tənliyini yenidən qurdu: 46 sətir, ikinci sətir `[378,1073,2375,6195,10493]`; sonra yeddi damcı formulunu hesabladı. Dörd giriş cütündə (F,F), (F-1,F), (F,F+1), (-2^1025,2^1025) nəticələrin hər biri 7 ədəd və hamısı `[1,M]` daxilindədir. Bu, normativ qəbul və ya Native differential deyil; test-oracle tənliyinə əsaslanan müstəqil kod yolunun məhdud yoxlanmasıdır.

`(F,F)` üçün namizəd sabit vektor:
```text
119390830530032782664128530203002080344
11877236279154673426874867061566696749
24217814924229232987463457533828175476
166629231917547214614573522551290204247
81202913407267092008896220686064041568
73551520026920072430116213847585486272
6164285870955721082771365327359496898
```

## 4. Gələcək icranın qapıları (hələ AÇILMAYIB)

1. Normativ mərhələ ardıcıllığına əsasən Stage07-nin növü, asılılığı, bu namizədin düzgün növbəti vahid olub-olmaması, konkret input/output sərhədi və qəbul qaydası yazılı şəkildə təsdiqlənməlidir. Əks halda `HOLD_NO_STAGE07` qalır.
2. Mərhələ müəyyən edilərsə, əvvəl ayrıca test-only oracle və fiks­turlar müstəqil riyazi spesifikasiyadan yenidən hazırlanmalı; məhsul Rust kodu və oracle eyni implementasiyanı import etməməlidir. Köhnə source/test fayllarının dəqiq blob SHA-ları sabitlənməlidir.
3. Məqbul namizəd üçün `F-1,F,F+1` hər iki gündə `3×3=9` cüt, istiqamət inversiyası, signed böyük `2^1025` və daha böyük sərhədlər, 7/7 dəyər/oracle, min-max interval, iki təkrar çağırış determinizmi, izolyasiya, çağırış metrikası, köhnə 46×5/WorkCounts/SAVE regressiyası ölçülməlidir. `BootstrapOnly` saxlanılmalıdır.
4. İcra yalnız ayrıca səlahiyyətli Stage07 scope-dan sonra yeni source SHA üzərində: Rust Native `cargo test --locked --all-targets -- --nocapture`, `cargo fmt --all -- --check`, Names Lock, bütün əvvəlki stage CI və müstəqil per-case differential. `completed/success` run + job + decoded checkout log, artifact SHA256/CRC/exit/PROJECT_ID/SHA və raw nəticələrin ayrıca oracle müqayisəsi olmadan heç bir PASS/kabul yoxdur.
5. Cari hesabat yalnız `audit/` faylıdır. Stage07 işə salınmır, `DEVELOPMENT_STAGE.md` dəyişmir, main/merge/release yoxdur; heç bir CI əl ilə işə salınmayıb. Audit-only commit-dən doğan avtomatik workflow ayrıca sübut tələb edir və əvvəlcədən PASS sayıla bilməz.

**NEXT**: rəsmi 55-mərhələ ardıcıllığı və Stage07 semantik mənbə əlaqəsi tapılarsa bu layihə-namizədini onunla uyğunlaşdırmaq; uyğun gəlmirsə yeni stage-in mənasını uydurmadan `HOLD_NO_STAGE07` saxlamaq. Cari layihə üçün bu, icazəli, icrasız scope-evidence fəaliyyətidir; D=פתוחה, G=READY.
