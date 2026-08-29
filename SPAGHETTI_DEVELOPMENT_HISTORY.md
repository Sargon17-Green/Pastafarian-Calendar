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


## Aşama 4 — Keşif 02: iki tarafı da çift gün etiketi sanmak

### Ne sanıldı

İkinci tarihsel hesap katmanı, kuruluş gününe olan uzaklığın iki katının doğrudan gün etiketi olduğunu varsaydı:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)
```

Bu eski formül artık yalnızca kenarda duran bir yardımcı değildir. `LegacyDayTagAdapter` üzerinden gerçek `calendar_date_spaghetti` zincirine bağlanır ve hem eylem günü hem hedef günü için çağrılır.

### Ne keşfedildi

Kuruluş gününden önceki günlerde eski formül normatif sayımla tesadüfen aynıdır: uzaklığın iki katı doğru çift değeri verir.

Kuruluş gününün kendisinde ve sonraki günlerde ise varsayım yanlıştır. Kuruluş gününün normatif sayımı `1` olmalıdır; eski yol `0` verir. Kuruluş gününden sonraki günlerin normatif sayımları tek olmalıdır; eski yol onları çift bırakır.

Yeni normatif regresyon bu ayrışmayı gerçek adapter yolunda gösterir. Kuruluş gününden önceki örnekler geçer; kuruluş günü ile sonraki örnekler bilinçli olarak kırmızıdır. Birinci yamanın bütün regresyonları yeşil kalır.

### Bu aşamada eklenen canavar katmanı

`LegacyDayTagAdapter`, `MonsterManager` içine ayrı bir eski-hesap bileşeni olarak eklendi. Eylem ve hedef günlerine ait eski etiket girdileri ve sonuçları ayrı alanlarda, yalnızca tek çağrının `MonsterContext` nesnesinde tutulur. Günlük ve ölçüm güncellemeleri sonuç hesabına geri okunmaz.

Bu aşamada kuruluş günü yarası için hiçbir `+1` düzeltmesi, özel kuruluş koruması veya başka bir gelecek yama eklenmemiştir.


## Aşama 5 — Yama 02: kuruluş sonrası tek gün etiketini geri getirme

### Ne aşıldı

`oldDayTag` değiştirilmedi. Kuruluş gününü `0`, kuruluş gününden sonraki ilk günü `2` ve üçüncü günü `6` olarak üretmeye devam eder.

Düzeltme eski yardımcının üstüne eklendi:

```text
n = oldDayTag(day)
if day >= FOUNDATION_DAY_OLD:
    n += 1
if day == FOUNDATION_DAY_OLD and n != 1:
    n = 1
```

İkinci kuruluş-günü koruması normal eski formülle gereksiz görünse de tarihsel yara olarak fiziksel biçimde korunur.

### Neden normatif olarak eşdeğer

Kuruluş gününden önce `oldDayTag`, normatif çift sayımla zaten aynıdır ve yama değeri değiştirmez.

Kuruluş gününde eski değer `0` olur; ilk dal bunu `1` yapar. İkinci koruma da sonuç `1` değilse zorla `1` yapar.

Kuruluş gününden sonra eski değer `2*d` biçimindedir; `+1` onu normatif `2*d+1` değerine dönüştürür.

Bu nedenle yama bütün tam sayı günlerde temiz normatif `day_count` ile aynıdır.

### Ne korundu

Aşama 4'teki normatif kırmızı regresyonun gövdesi değiştirilmedi ve yalnızca yama sayesinde yeşile döndü. Eski `oldDayTag` formülünü doğrudan doğrulayan test de aynı yanlış sonuçları beklemeye devam eder.

Keşif anında adapter'ın doğrudan yanlış sonucunu sabitleyen geçici sahiplik testi, yama sonrasında hem ham eski değerin bağlamda korunduğunu hem adapter çıkışının düzeltilmiş olduğunu doğrulayacak biçime geçirildi; normatif regresyona dokunulmadı.

### Bu aşamada eklenen canavar katmanı

`DayTagPatchWrapper`, `LegacyDayTagAdapter` ile eski hesap arasına eklendi. Her çağrıda ham eski değer ile yama sonrası değer ayrı alanlarda tutulur. Eylem ve hedef yolu için ayrı yama durumları vardır.

Günlük, ölçüm ve tanı durumu normatif hesaba geri okunmaz. İki farklı `MonsterContext` arasında ham veya yamalı gün etiketi durumu paylaşılmaz.


## Aşama 6 — Keşif 03: gün etiketi farkını kronolojik mesafe sanmak

### Ne sanıldı

Üçüncü tarihsel hesap katmanı, iki günün mesafesini düzeltilmiş gün etiketlerinin mutlak farkı olarak aldı:

```text
oldDistance(calculationDay, targetDay) =
    abs(
        dayTagWithFoundationScar(calculationDay)
        - dayTagWithFoundationScar(targetDay)
    )
```

Bu eski fonksiyon gerçek `calendar_date_spaghetti` yoluna `LegacyDistanceAdapter` üzerinden bağlanmıştır.

### Ne keşfedildi

Gün etiketleri kronolojik eksende her yerde birer birer ilerlemez. Kuruluş gününden sonra aynı yöndeki her günlük hareket etikette iki birim değiştirir; kuruluş çevresinde ise iki tarafın çift/tek yapısı farkı daha da yanıltabilir.

Ayrıca normatif mesafe uç günlerin ikisini de içerir:

```text
abs(targetDay - calculationDay) + 1
```

Bu nedenle aynı gün için eski mesafe `0` iken normatif mesafe `1` olur. Kuruluş gününden üç gün sonrasında eski değer `6`, normatif değer `4` olur. Kuruluşun iki yanını aşan örneklerde de etiket farkı kronolojik uzaklığı temsil etmez.

Bir günlük `FOUNDATION_DAY -> FOUNDATION_DAY + 1` örneği eski yolun tesadüfen doğru normatif sonuç verebildiğini gösterir: iki yol da `2` üretir.

### Bu aşamada eklenen canavar katmanı

`LegacyDistanceAdapter`, `MonsterManager` zincirine ayrı bir eski hesap yöneticisi olarak eklendi. Girdi günleri ve eski mesafe sonucu yalnızca çağrıya ait `MonsterContext` içinde tutulur.

`oldDistance`, önceki yamanın `dayTagWithFoundationScar` yolunu gerçekten yeniden çağırır; bu nedenle gün etiketi katmanı artık bir çağrı içinde hem kendi aşamasında hem mesafe legacy hesabının içinde görülebilir.

Bu aşamada kronolojik karşılaştırma, legacy değeri kronolojik değerle değiştiren guard veya son `+1` henüz yoktur. Bunların hiçbiri erken eklenmemiştir.


## Aşama 7 — Yama 03: etiket farkını kronolojik mesafeyle karşılaştırma

### Ne aşıldı

`oldDistance` değiştirilmedi. Hâlâ iki yamalı gün etiketinin mutlak farkını döndürür.

Düzeltme eski fonksiyonun üstünde uygulanır:

```text
legacy = oldDistance(calculationDay, targetDay)
chronological = abs(targetDay - calculationDay)

if legacy != chronological:
    legacy = chronological

distance = legacy + 1
```

Bu yol önce tarihsel hesabı gerçekten çalıştırır. Yalnızca legacy değer kronolojik farktan ayrışıyorsa legacy ara değeri kronolojik değerle değiştirir. Ardından her durumda iki uç günü de kapsamak için `+1` uygular.

### Neden normatif olarak eşdeğer

Legacy değer kronolojik farktan farklıysa açıkça kronolojik farkla değiştirilir.

Legacy değer kronolojik farkla aynıysa değiştirme dalı çalışmaz; legacy zaten kronolojik değerdir.

Her iki durumda da son `+1` uygulanır. Böylece son değer her zaman:

```text
abs(targetDay - calculationDay) + 1
```

olur.

### Ne korundu

Aşama 6'nın normatif kırmızı regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca yeni yama sayesinde yeşile döndü.

`oldDistance` yardımcısının yanlış sonuçlarını doğrulayan doğrudan testler korunur.

Aşama 6'daki adapter-state testi PATCH sonrası adapter çıkışının normatif olmasını bekleyecek biçimde güncellendi; ham legacy değer bağlamda yine `oldDistance` sonucu olarak saklanır.

### Bu aşamada eklenen canavar katmanı

`DistancePatchWrapper`, `LegacyDistanceAdapter` üstünden çalışan ayrı yama katmanıdır.

Çağrı bağlamında ham legacy mesafe, kronolojik ara fark, son mesafe, legacy değerin değiştirilip değiştirilmediği ve yamanın uygulanma durumu ayrı saklanır.

Doğal değiştirmeme dalı `FOUNDATION_DAY-1 -> FOUNDATION_DAY` örneğiyle ayrıca doğrulanır: legacy `1`, kronolojik fark `1`, değiştirme yok, son mesafe `2`.

Günlük, ölçüm ve tanı verileri normatif hesaba geri okunmaz.


## Aşama 8 — Keşif 04: taşları aynı nesnede sırayla güncellemek

### Ne sanıldı

Dördüncü tarihsel katman, beş taşın bir sonraki satırını tek bir mutable state üzerinde satır satır hesapladı:

```text
S.w = savePatch(S.w*S.w + 3*S.b + i)
S.b = savePatch(S.b*S.b + 5*S.s + S.w)
S.s = savePatch(S.s*S.s + 7*S.m + S.b)
S.m = savePatch(S.m*S.m + 11*S.r + S.s)
S.r = savePatch(S.r*S.r + 13*S.w + S.m)
```

`mutateStonesWrong` aynı state nesnesini in-place değiştirir. Bu yüzden `b` hesabı yeni `w` değerini, `s` hesabı yeni `b` değerini, `m` hesabı yeni `s` değerini ve `r` hesabı yeni `w` ile yeni `m` değerlerini okur.

### Ne keşfedildi

Normatif taş satırı aynı eski snapshot'tan beş bağımsız sonuç üretmelidir.

İkinci satırda `w` hesabı ilk çalışan satır olduğu için tesadüfen normatif değerle aynıdır. Ancak aynı satırdaki `b`, `s`, `m` ve `r` yeni ara değerlerden kirlenir. Bu ayrışma sonraki satırlara da taşınır.

Yeni regresyon gerçek `LegacyStoneBuilderAdapter` yolunun 2, 3 ve 46 numaralı satırlarını aynı Python hattının test-only normatif taş tablosuyla karşılaştırır. Üç alt örnek de bilinçli olarak kırmızıdır.

### Önceki instrumentation ile etkileşim

Aşama 2'deki gerçek-yol instrumentation testi başlangıçta `oldRemainder` için tam bir çağrı bekliyordu. Taş legacy hesabı her `savePatch` üzerinden aynı tarihsel `oldRemainder` yolunu meşru biçimde yeniden kullandığı için Aşama 8'de toplam çağrı sayısı doğal olarak artar.

Bu nedenle yalnızca instrumentation koşulu geleceğe dayanıklı hâle getirildi: ilk `oldRemainder` çağrısının hâlâ Aşama 2'nin `M_OLD` çağrısı olduğu doğrulanır. Aşama 2'nin normatif kırmızı/yeşil regresyonuna dokunulmadı.

### Bu aşamada eklenen canavar katmanı

`getStoneTableThroughLegacyBuilder`, ilk satırı sabit başlangıç state'inden kurar ve 2–46 satırlarını `mutateStonesWrong` çağrılarıyla üretir.

`LegacyStoneBuilderAdapter`, bu yanlış tabloyu gerçek `calendar_date_spaghetti` state machine'ine bağlar. Tablo ve üretilen satır sayısı yalnızca invocation'a ait `MonsterContext` içinde tutulur.

Bu aşamada snapshot alınmaz, legacy clone üzerinde ayrıca çalıştırılmaz, `garbage` sonucu yoktur ve beş alanı eski snapshot formülleriyle yeniden yazan `stonePatch` henüz eklenmemiştir.
