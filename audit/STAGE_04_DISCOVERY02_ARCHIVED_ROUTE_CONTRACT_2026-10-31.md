# Mərhələ 4 / DISCOVERY02 — arxivdə sübut olunmuş gün-etiketi marşrutunun müqayisəsi

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Tarix: 2026-10-31
Vəziyyət: mənbə və lokal riyazi reproduksiya yoxlanıb; yeni Rust Native CI hələ təsdiqlənməyib.

## Mənbə və provenance

- Tarixi artefakt: GitHub Release `python-turkish-v1.0.0-verified-20261030`, commit `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`.
- Mənbə: `src/pastafari_calendar/legacy_day_counts.py`, Git blob `405f461b2e2cdd170ded010e6f8046b78d6b4ab6`.
- `oldDayTag(day)` tarixi marşrutu `2 * abs(day - (-15055671))` qaytarır.
- `dayTagWithFoundationScar` əvvəldən mövcud tarixi dəyəri saxlayır; `day >= -15055671` olduqda bir əlavə edir və foundation-day qoruyucusunu saxlayır.
- Rust-də bu kodun surəti və production integrasiyası yaradılmır; riyazi test-only rekonstruksiya normativ oracle ilə müstəqil müqayisə olunur.

## Müqavilə və hesablanan şahidlər

- Daxilolma: signed BigInt day, foundation day F=-15055671; mənbədə iki rol `action`/`target` üçün eyni hesab çağırılır.
- Legacy çıxışı: L(d) = 2|d-F|. Normativ çıxış: N(d) = 2(F-d) if d<F; otherwise 2(d-F)+1.
- Pozitiv günlərdə L(d) həmişə N(d)-1, negatif günlərdə L(d)=N(d). Yalnız müşahidə olunan fərqlər RED sayılır.
- Test şahidləri: F+[-3,-2,-1,0,1,2,3] və hər biri üçün ±2^127, ±2^1025, ±2^4096, ±2^8192; cəmi 15 distinct days.
- Gözlənilən tarixi nəticə: 8 RED, 7 CONTROL, 0 UNEXPECTED; tarixi patch 15/15 və müstəqil Rust candidate 15/15 oracle ilə uyğun olmalıdır.
- Native qəbul üçün yeni iki Rust testi, cargo fmt --check, mövcud 32 regression testi, marker yoxlaması, CI completed/success, və işçi SHA identikliyi lazımdır.

## Sərhədlər

Bu mənbə **başqa dilin tarixi branch-indən** gəlir; Rust branch-də əvvəlki legacy day-tag mövcud olduğu iddia edilmir. Yeni testlər normativ kodu xarici alqoritmdən köçürmür və tam çox-komponentli alqoritmi sübut etmir.
Python mənbəyinin lokal əsas funksiyaları ilə 15-case reproduksiya: RED=8, CONTROL=7, UNEXPECTED=0, PATCH_OK=15. Bu lokal müşahidə Rust Native CI PASS demək deyil.
Stage4 yalnız müsbət baseline ilə bağlanmır. İstehsalın beş-sahəli entry point-i `BootstrapOnly` qalır. Stage5, main, merge, publish yoxdur.

## Növbəti addım

Yeni test və workflow dəyişikliklərinin exact SHA-sı üzrə bütün CI tamamlandıqdan sonra log, Rust test count və evidence artifact yoxlanmalıdır. Tarixi Python source-dan çıxarılan şahidin Rust Native reproduksiyası qeydə alınsa belə Stage4 closure ayrıca qaydalarla yoxlanmalıdır.

Source: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/python-turkish-v1.0.0-verified-20261030/src/pastafari_calendar/legacy_day_counts.py
