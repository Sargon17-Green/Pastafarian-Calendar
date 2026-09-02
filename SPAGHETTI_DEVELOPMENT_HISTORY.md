# Spagetti inkişaf tarixçəsi

## Mərhələ 1 — ilkin quruluş

### Nə quruldu

Yeni Rust tətbiq ağacı sıfırdan yaradıldı. Neytral `MonsterContext`, dispetçer, validator, xəta sərhədi, metrik və jurnal qabığı əlavə edildi. Mənbə dili kataloqu Azərbaycan dilində yaradıldı və `canonical_index` sırası ilə donduruldu. Sınaq məqsədli normativ oracle ayrıca sınaq qatında saxlanıldı.

### Nə düşünülürdü

Bu mərhələdə hələ heç bir tarixi səhv fərziyyə daxil edilməməlidir. Buna görə istehsal yolu yalnız gələcək böyüməyə hazır neytral qabıqdır.

### Nə aşkarlandı

Tarixi qüsur aşkar edilməyib; bu mərhələ kəşf mərhələsi deyil.

### Nə dolanıldı

Heç nə. Gələcək yamaq kodu qəsdən yoxdur.

### Normativ bərabərlik niyə qorunur

Oracle yalnız sınaq qatındadır. İstehsal funksiyası bu mərhələdə normativ cavab iddiası etmir və oracle nəticəsini qaytarmır.

### Əlavə olunan struktur mürəkkəbliyi

Bir çağırışa məxsus kontekst, dispetçer, validator, xəta sərhədi, metrik və jurnal qabığı əlavə olunub. Bu qatlar hazırda semantik olaraq neytraldır və gələcək mərhələlərdə tarixi şəkildə böyümək üçün başlanğıc nöqtəsidir.
