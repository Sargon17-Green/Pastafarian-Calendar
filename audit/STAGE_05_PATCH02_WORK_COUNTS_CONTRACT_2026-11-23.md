# Stage05 / PATCH02 — normativ iki-gün iş sayları

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI  
Branch: Rust+Azərbaycan-dili  
Source parent: `229c04f2b597038542cb84c5b2153b757d816f9a` (Stage04 ACCEPTED)  
Authorization: 2026-11-23, user explicitly removed the requirement for a separate approval between stages.  
Status: **OPEN / NOT_ACCEPTED**. Stage04 remains accepted; LAST_COMPLETED_STAGE=4.

## Yalnız bu mərhələnin əhatəsi

Mərhələ 4-ün müstəqil DISCOVERY02 araşdırmasından sonra istehsal dispatcher-inə yalnız iki tarix gününün normativ **iş sayları** əlavə olunur. Tam beş-sahəli `calendar_date_spaghetti` marşrutu yenə `BootstrapOnly` qaytarır. Stage04-ün orijinal Python arxiv RED-si tarixi Rust RED kimi təqdim edilmir; təsdiqlənmiş 2026 rekonstruksiya istisnası Stage04 ilə məhdud qalır.

İstehsal: `src/patch02_work_counts.rs`, `MonsterManager` → `WorkCountsPatch02` → çağırışa məxsus `MonsterContext.work_counts_observation`. Test oracle yalnız `tests/support/normative_oracle.rs` faylındadır. Stage03 SAVE, Stage02 legacy SAVE, Stage04 zondları və mənbə-ad kataloqu dəyişdirilmir.

## Ölçülən müqavilə

Giriş: `(calculation_day, target_day)`, istənilən işarəli `BigInt`; girişlər dəyişmir. `F=-15055671`, `P(x)=2|x-F|+[x>=F]`. Çıxış:

- `action=P(calculation_day)`, `target=P(target_day)` — müsbət `BigInt`;
- `distance=|target_day-calculation_day|+1` — müsbət `BigInt`, eyni gün üçün 1;
- `connection=action+target` — müsbət `BigInt`;
- `direction=1` (hədəf əvvəl), `2` (eyni), `3` (sonra).

Heç bir `i64`-ə daralma, qlobal keş, qeyri-Rust runtime və ya Stage04 probe/oracle importu yoxdur. Dispetçer konteksti hər çağırışda təzədir; metrik `patch02.work_counts.calls=1` olmalıdır.

## Testlər və qəbul qapıları

1. `F±3` daxil olmaqla yeddi dəqiq sərhəd (gözlənilən `6,4,2,1,3,5,7`), istehsal dispatcher-i və müstəqil test oracle.
2. `7×7=49` iki-gün kombinasiyası, tərs istiqamət simmetriyası, iki sərhədli məsafə və çağırış izoləsiyası.
3. `1025,2049,4096,8192` bitlik `±` girişlərdən 8 cüt; BigInt oracle ilə bütün beş sahənin bərabərliyi.
4. 4 müstəqil SAVE izoləsiyası: Stage02/03 nəticələrinin dəyişməməsi; Stage04 zondunun mənası ilə uyğunluq; tam beş-sahəli yol hələ `BootstrapOnly`.
5. Stage01–Stage04 Native reqressiyası, `cargo fmt --all -- --check`, `cargo test --locked --all-targets -- --nocapture`, Canonical Names Lock.
6. Yeni Stage05 code SHA üçün tamamlanmış GitHub run, job, checkout log, `exit.txt=0`, `sha.txt`, artifact SHA-256/CRC və ayrıca məzmun yoxlaması olmadan **Stage05 PASS/ACCEPTED iddia edilmir**. Dəyişmiş HEAD üzrə əvvəlki CI-nin nəticəsi təkrar istifadə edilmir.

Başlanğıc vəziyyəti: `CURRENT_STAGE=5`, `LAST_COMPLETED_STAGE=4`, `EXPECTED_REPOSITORY_STATE=PATCH02_STAGE05_PENDING_NATIVE`. Hər hansı qapı açıq qalarsa `D=פתוחה`, `G=READY`. `main`, merge və digər mərhələlər toxunulmazdır.

NEXT: tamamlanmış Native/Names Lock və artifact-u yoxla, çarpaz oracle nəticələrini ayrıca təsdiqlə, yalnız bundan sonra Stage05 qəbuluna bax.
