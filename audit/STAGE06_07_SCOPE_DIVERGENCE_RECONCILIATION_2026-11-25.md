# Stage06/07 — mərhələ ardıcıllığının uyğunsuzluğu və bərpa müqaviləsi

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
START_HEAD=e3aa6afb0a68a3d4c2ee2e9ebe18fd0bba7aaded
TYPE=NON_EXECUTING_SCOPE_RECONCILIATION
STAGE07_STARTED=NO
SOURCE_CHANGE=NO
STAGE_COUNTER_CHANGE=NO
STAGE06_STONE_NATIVE_EVIDENCE=RETAINED
STAGE06_DISCOVERY03_SCOPE_ACCEPTANCE=CONTESTED
STAGE05_PATCH02_WRAPPER_CHAIN=REVIEW_REQUIRED

## Mənbə yoxlaması

- Kotlin, 77f631d357d2fccc4e8f0e8b0a3602677c34f4b0, docs/AUDIT_STAGE_06.md blob 29ce0127c672133dad2ba6f2b94400e44d373ed2 və docs/AUDIT_STAGE_07.md blob 32c12f9918b81044e5f46129c4d85755f13c683b: DISCOVERY03 köhnə tag fərqi, PATCH03 xronoloji məsafə və +1.
- V, bdbb4ccbd320176ef538a64a0ce22718c79cc65c, SPAGHETTI_DEVELOPMENT_HISTORY.md blob 34498a4b444c1d1d40d530047a65323774a3ac24: eyni Stage06/07, Stage08 isə ardıcıl daş yeniləmə qüsuru; Stage09 snapshot düzəlişi.
- JavaScript, 6b276f4fffe3b3baf1f98023e295241ca90da6be, SPAGHETTI_DEVELOPMENT_HISTORY.md blob 8603f08f754338f90a59ea7491243b90d66be72b: eyni DISCOVERY03/PATCH03.
- Normativ README.md (main blob 74c424b44eadd4ece3f29072ddbf873236557604), A/C/E/F: məsafə abs(t-c)+1, gün etiketləri, snapshot daşlar və gizli damcılar. Bu riyazi mənbə mərhələ sıralaması deyil. Əsl 55-mərhələ göstərişinin ayrıca sənədi hələ tapılmayıb. Üç sənədləşdirilmiş müstəqil inkişaf tarixçəsi eyni ardıcıllığı göstərir; yalnız semantik əhatə yoxlanıb, başqa dilin source/fixture/oracle kodu köçürülməyib.

## Rust mənbə uyğunsuzluğu

Dəqiq HEAD-də DEVELOPMENT_STAGE.md blob 0fd1647fcffb4eaa6248536af5ede7a94bfa8371 6/6 HOLD_NO_STAGE07. src/discovery03_stone_probe.rs blob 5db024e1cd05fa497a4b62eede78f1df1f7bfb00 düzgün snapshot ilə 46×5 daş hesablayır; tarixi RED iddiası yoxdur. Stage06 daş nəticələri və Native sübutu etibarlı məhdud QA kimi saxlanılır, ancaq DISCOVERY03 köhnə məsafə qüsurunu əhatə etmir. Stage07 gizli damcı dizaynı dayandırılır.
src/patch02_work_counts.rs blob 14fce04947a7b6ec1cba5bb99160c0fb3a8242bd normative_day_tag-i sıfırdan hesablayır, legacy day-tag çağırışı yoxdur, normative_work_counts artıq abs(t-c)+1 hesablayır. src/discovery02_day_tag_probe.rs blob 47b33a2fb3f604759f552d94cc8ca07edc3f586f da düzgün müsbət zonddur. Stage05-in normativ PASS sübutu saxlanılır, amma tarixi PATCH02 wrapper zəncirinin production-da həqiqi legacy yolundan keçməsi ayrıca yoxlanmalıdır. Stage04 xüsusi 2026 rekonstruksiya icazəsi tarixi Rust RED yaratmır; başqa qüsura avtomatik tətbiq edilmir.
Names Lock 45272604750/job138036042834 completed/success; decoded log exact checkout e3aa6afb0a68a3d4c2ee2e9ebe18fd0bba7aaded və canonical verify step success. Yalnız Names Lock, yeni Native deyil.

## Müstəqil riyazi müqavilə və hesablanmış gözləntilər

F=-15055671; d<F üçün N(d)=2(F-d), əks halda N(d)=2(d-F)+1.
Stage06: iki signed BigInt giriş, eyni çağırışda həqiqi PATCH02-dən iki tag, L=abs(N(c)-N(t)); normativ gözlənti Q=abs(t-c)+1. L saxlanılır, düzəliş edilmir. Stage07 yalnız Stage06 RED Native təsdiqindən sonra: B=abs(t-c); L != B olduqda B-ni seç, əks halda L-ni saxla; həmişə +1. Legacy və seçmə flag ayrıca müşahidə olunur. L!=Q və L!=B eyni predikat deyil.
JS BigInt müstəqil hesabı (Rust icrası deyil): F-20..F+20 və F±2^b, F±(2^b+1), b=127,1025,4096; 53 fərqli günün 2809 ordered cütü. L!=Q: 2693, L==Q:116; L!=B:2728; patch formul Q ilə 2809/2809; symmetry 2809/2809. Bunlar gözlənilən riyazi təsnifatdır, müşahidə olunmuş Rust RED deyil.
Yeni əl nümunələri (F-ə nisbətən): (-20,-19): L=2 B=1 Q=2; (-7,3): L=7 B=10 Q=11; (0,0): L=0 B=0 Q=1; (-1,0): L=1 B=1 Q=2; (1,3): L=4 B=2 Q=3.
Gələcək Native gate: original Rust source və test-only oracle ayrılığı; real production handler zənciri, per-call ownership/trace, guard/reentry, strict negative test-in yalnız gözlənilən səbəbdən uğursuzluğu, müşahidə edilmiş hər cütün L/Q/flag (Stage07 flag yalnız sonrakı mərhələdə); bütün əvvəlki Native regression, cargo fmt, Names Lock, exact checkout, artifact sha/CRC/exit/PROJECT_ID. Köhnə daş probe regressiya kimi qalır, Stage08/09 qəbulunu əvəz etmir. Full-calendar BootstrapOnly qalır.

## NEXT

Əvvəl Stage05-in legacy PATCH02 wrapper chain-ni Stage04-approved reconstruction sərhədləri ilə uzlaşdır; sonra Stage06 DISCOVERY03 məsafə qüsurunu real Rust production route-da ayrıca Native EXPECTED_RED ilə qur və mövcud yanlış etiketlənmiş daş gate-i ilə qarışdırma. Stage counter/gates yalnız dəqiq düzəliş planı və actual evidence ilə uzlaşdırılmalıdır; Stage07, main, merge, release yoxdur. Bu auditdə Stage05/06 əvvəlki PASS silinmir; semantik qəbul mübahisəsi qeyd edilir və yanlış scope ilə irəli getmək dayandırılır. D=פתוחה G=READY.
