# Спагетти хөгжүүлэлтийн түүх

## Stage 1 — Bootstrap

### Юуг байгуулсан

Mercury + Монгол хэл гэсэн шинэ, бие даасан шугамыг хоосон модноос эхлүүлэв. Монгол эх хэлний 17 котлет, 47 сарын нэрийг `canonicalIndex`-тэй хөлдөөсөн каталог болгон тусгаарлав. Mercury-ийн arbitrary-precision `integer` дээр норматив oracle, жижиг fixture-үүд, test harness, мөн ерөнхий context/dispatcher/validator/metrics суурийг үүсгэв.

### Ямар legacy алдаа одоогоор бий вэ

Байхгүй. Stage 1-д 01–26 түүхэн алдааны аль нь ч орох ёсгүй.

### Мангасын ямар давхарга нэмэгдсэн бэ

Зөвхөн саармаг `monster_context`, `base_dispatch`, validation ба observability талбарууд нэмэгдсэн. Эдгээр нь норматив алгоритмын оролт биш бөгөөд ирээдүйн түүхэн patch-уудыг урьдчилан хэрэгжүүлээгүй.

### Семантик аюулгүй байдал

Production bootstrap нь test oracle-ийг дуудахгүй. Каталогийн мөрүүд норматив rank/unrank-д оролцохгүй. Invocation context нь өөр invocation-тай хуваалцахгүй.
