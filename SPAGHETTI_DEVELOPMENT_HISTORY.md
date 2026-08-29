# Makarna Canavarı Geliştirme Geçmişi

## Aşama 1 — Başlangıç

Bu çizgi Python ve Türkçe için sıfırdan başlatıldı.

Bu aşamada henüz tarihsel bir yanlış varsayım eklenmedi. Yalnızca tarafsız altyapı kuruldu: çağrı başına ayrı bağlam, temel dağıtım, doğrulama sınırı, hata sarmalama kabuğu, ölçüm ve günlük kabuğu.

Temiz normatif başvuru yalnızca test alanındadır. Üretim girişi ona çağrı yapmaz ve ondan sonuç kopyalamaz.

`SourceLanguageCatalog` on yedi köfte ve kırk yedi ay için `canonicalIndex` değerleriyle donduruldu. Türkçe metin sunum verisidir; sıralama, derece açma, seçim veya önbellek semantiğine katılmaz.

Bir sonraki aşamada ilk tarihsel yanlış varsayım keşif amacıyla eklenecektir. Bu dosya gelecekteki yamaların hikâyesini şimdiden içermez.

## Aşama 2 — Keşif 01: normal kalanın kaydetme işlemi sanılması

### Ne sanıldı

İlk aritmetik katman, büyük sayaca göre sıradan Öklid kalanı almanın tomarın “kaydet” işlemiyle aynı olduğunu varsaydı. Bu nedenle `oldRemainder`, değeri doğrudan `regularMod(x, M_OLD)` ile küçültüyor. Bu eski yol artık gerçek `calendar_date_spaghetti` çağrı zincirine bağlıdır ve çağrıya ait `MonsterContext` içinde sonucu saklar.

### Ne keşfedildi

Varsayım büyük sayacın tam katlarında yanlıştır. `M_OLD`, `2*M_OLD` ve `3*M_OLD` için eski işlem `0` döndürürken normatif kaydetme işlemi `M_OLD` döndürmelidir. `M_OLD+1` örneği ise iki yolun bazı girdilerde tesadüfen aynı sonucu verebildiğini gösterir.

Yeni regresyon bu ayrışmayı bilerek kırmızı bırakır. Önceki bütün birinci aşama regresyonları yeşil kalır.

### Bu aşamada eklenen canavar katmanı

`LegacyRemainderAdapter`, temel `MonsterManager` zincirine eklendi. Girdi ve sonuç yalnızca tek çağrıya ait `MonsterContext` içinde tutulur; günlük ve sayaç güncellemeleri normatif hesaba geri okunmaz. Henüz düzeltme, sıfırı büyük sayaca çeviren koruma veya gelecek bir yamanın başka parçası eklenmemiştir.


## Aşama 3 — Yama 01: sıfır kalanı büyük sayaca geri çevirme

### Ne aşıldı

`oldRemainder` değiştirilmedi. Büyük sayacın tam katlarında hâlâ `0` döndürür ve bu davranış ayrı testle korunur.

Düzeltme, eski yardımcının üstüne eklenen `savePatch` katmanındadır. `savePatch` önce gerçekten `oldRemainder(x)` çağırır; dönen değer `0` ise onu `M_OLD` ile değiştirir, değilse değeri olduğu gibi bırakır.

Gerçek `LegacyRemainderAdapter` artık sonucu doğrudan eski yardımcıdan döndürmek yerine `SavePatchWrapper` üzerinden geçirir. Böylece Aşama 2'de kırmızı olan aynı normatif regresyon değiştirilmeden yeşile döner.

### Neden normatif olarak eşdeğer

Öklid kalanı `1..M_OLD-1` aralığındaysa normatif `SAVE` aynı değeri verir. Kalan yalnızca `0` olduğunda normatif işlem `M_OLD` döndürmelidir. Bu nedenle:

```text
r = oldRemainder(x)
if r == 0:
    r = M_OLD
```

bütün tam sayı girdileri için gömülü normatif `SAVE(x)` işlemiyle aynıdır.

### Bu aşamada eklenen canavar katmanı

`SavePatchWrapper`, eski adapter ile çağrının geri kalanı arasına yerleştirildi. Yamanın girdisi, çıktısı ve uygulanma durumu yalnızca o çağrıya ait `MonsterContext` içinde tutulur. Günlükler, ölçümler ve tanı verileri yamaya girdi değildir; önceden doldurulmuş gözlem durumu sonuç üzerinde etkisizdir.

Aşama 2'deki “yama henüz yok” nöbetçisi aşama-geçişi gereği artık doğru bir önerme olmadığından, aynı dosyada tarihsel yaranın hâlâ mevcut olduğunu doğrulayan daha güçlü bir nöbetçiyle değiştirilmiştir. Normatif kırmızı regresyonun kendisi değiştirilmemiştir.
