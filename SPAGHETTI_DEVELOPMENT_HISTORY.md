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
