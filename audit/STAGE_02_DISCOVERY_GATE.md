# Mərhələ 2 — normativ həcm üzrə giriş yoxlaması (plan, icraya başlanmayıb)

Bu qeyd Stage 1-in sübutlu bağlanmasından sonrakı addımı müəyyən edir. Bu, Stage 2-nin icrası və ya PASS nəticəsi deyil.

## Əvvəlki mərhələdən gələn zəmanətlər
- Stage 1: neytral bootstrap, istehsal kodundan ayrılmış sınaq oracle-ı, dondurulmuş Azərbaycan dili kataloqu.
- 2026-10-30 Native: 16/16 PASS, Canonical Names Lock SUCCESS (1bcd853e4a3a9a5bb3498d43c1e1728e23949274).
- İstehsalın calendar_date_spaghetti yolu hələ tarixi hesablamır; normativ beş nəticə təsdiqlənməyib.

## Stage 2-ni açmadan əvvəl lazım olan konkret giriş
1. Kanonik 55-mərhələli proqramda Stage 2-nin normativ əhatə dairəsini və mənbə istinadını göstərmək; hansı davranışın məhz Stage 2-də nəzərdə tutulduğu bilinməlidir.
2. Həmin davranışın giriş/çıxış müqaviləsini, dəqiq sərhəd hallarını və BigInt tələblərini yazmaq; mövcud Stage 1 API-ni səbəbsiz dəyişməmək.
3. İstehsal Rust kodundan tam ayrılmış müstəqil oracle və həqiqətən müstəqil gözlənilən nümunələr hazırlamaq. Eyni alqoritmi iki dəfə işlətmək diferensial sübut deyil.
4. Yeni normativ addımın beş kanonik tarix komponenti ilə əlaqəsini göstərmək; bundan artıq istehsal komponenti yaratmamaq.
5. Qəbul sınaqları: kiçik açıq nümunələr, sərhədlər, böyük tam ədədlər; sonra Native cargo test, lazım olan verify və müstəqil differential sınaqları ayrıca sübut etmək.

## Hal-hazırkı sərhəd
Bu budaqdakı Stage 1 mənbələri Stage 2-nin konkret hesablanacaq davranışını müəyyən etmir. Buna görə Stage 2-nin nömrəsi mövcud olsa da, məzmunu özbaşına seçilməyəcək. Normativ Stage 2 müqaviləsi və mənbə aydınlaşdıqdan sonra icra planı dəqiqləşdirilib mərhələ açılacaq. Main ilə merge nəzərdə tutulmur.
