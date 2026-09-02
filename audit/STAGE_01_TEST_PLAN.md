# Mərhələ 1 sınaq planı

Sınaqlar yalnız Rust ilə yazılıb və eyni tətbiq xəttinin normativ oracle-ına əsaslanır.

Yoxlanılan sahələr:

- normativ sabitlərin dəqiq qiymətləri;
- `SAVE` sərhədləri;
- təməl günün və hər iki tərəfin gün sayları;
- məsafə və istiqamət;
- daşların eyni köhnə snapshot-dan hesablanması üçün ikinci sıra fixture-i;
- permutasiya dərəcəsinin 1 və 720 sərhədləri;
- məhdud kompozisiyaların dəqiq sayı və leksikoqrafik dərəcə açılması;
- daxili sərhədli kotlet kompozisiyalarının kiçik məkan üzrə tam müqayisəsi;
- fərqli ad indekslərinin təkrarsızlığı;
- kiçik ay toxunuşu ailəsinin tam leksikoqrafik müqayisəsi;
- 17 və 47 elementli Azərbaycan dili kataloqunun indeks sabitliyi;
- bütün 64 Azərbaycan dili mənbə mətninin exact fixture kimi dondurulması;
- sous hesabının təkrarlanan çağırışlarda deterministik olması;
- neytral monster qabığının həyat dövrü;
- əsas xəta sərhədinin machine error code-u dəyişmədən deterministik sarğı yaratması;
- gələcək yamaq izlərinin istehsal kodunda olmaması.

Tam təqvim oracle funksiyası da sınaq modulunda mövcuddur. Birinci mərhələnin gündəlik sınaq dəsti onun ən ağır sonadək hesabını məcburi etmir; ağır ekvivalentlik sınaqları sonrakı audit mərhələlərində genişləndiriləcək.
