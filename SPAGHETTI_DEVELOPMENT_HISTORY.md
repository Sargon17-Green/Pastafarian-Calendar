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


## Aşama 9 — Yama 04: sequential taş mutasyonunu snapshot ile etkisizleştirme

### Ne aşıldı

`mutateStonesWrong` değiştirilmedi. Aynı mutable state üzerinde beş alanı sırayla güncellemeye ve sonraki formüllerin yeni ara değerleri okumasına devam eder.

Düzeltme onun üstündeki `stonePatch` katmanındadır:

```text
old = clone(S)
garbage = mutateStonesWrong(i, clone(S))

garbage.w = savePatch(old.w*old.w + 3*old.b + i)
garbage.b = savePatch(old.b*old.b + 5*old.s + old.w)
garbage.s = savePatch(old.s*old.s + 7*old.m + old.b)
garbage.m = savePatch(old.m*old.m + 11*old.r + old.s)
garbage.r = savePatch(old.r*old.r + 13*old.w + old.m)

return garbage
```

Legacy çağrısı kaldırılmaz ve sahte bir diagnostic çağrıya dönüştürülmez. `mutateStonesWrong`, gerçek bir clone üzerinde çalışır ve gerçek `garbage` state üretir. Daha sonra aynı garbage nesnesindeki beş alanın tamamı old snapshot kullanan formüllerle ezilir.

### Neden normatif olarak eşdeğer

Her taş formülü yalnızca önceki satırın aynı `old` snapshot değerlerini okur.

Bu nedenle beş sonuç, test-only normatif taş tablosunun aynı satır formülleriyle birebir eşdeğerdir. Legacy mutasyonunun kirli ara değerleri hiçbir normatif formülde okunmaz; tamamı overwrite edilir.

`getStoneTableThroughLegacyBuilder` artık 2–46 satırlarında doğrudan `mutateStonesWrong` yerine `stonePatch` çağırır. Böylece yanlış fonksiyon fiziksel olarak korunur ve çalıştırılır, fakat tabloya commit edilen satırlar snapshot semantiğine döner.

### Ne korundu

Aşama 8'in normatif taş-tablosu regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca yeni patch sayesinde yeşile döndü.

`mutateStonesWrong` fonksiyonunun in-place ve yanlış sequential davranışını doğrulayan testler korunur.

Patch ayrıca gerçek legacy `garbage` ile overwrite sonrası committed satırı ayrı gözlemleyebilir. Bu gözlem durumu semantik hesaba geri okunmaz.

### Bu aşamada eklenen canavar katmanı

`LegacyStoneBuilderAdapter`, builder'ın patch trace bilgisinden son satır için üç scar snapshot tutar:

```text
old snapshot
legacy garbage
committed patched row
```

Ayrıca kaç satırın `stonePatch` üzerinden geçtiği tutulur.

Bu alanlar yalnızca invocation'a ait `MonsterContext` içinde bulunur. Logs, metrics ve diagnostics taş hesabına girdi değildir.


## Aşama 10 — Keşif 05: gizli damlaları ters fiziksel sırada saklamak

### Ne sanıldı

Gizli damla katmanı fiziksel depoyu yakınlığa göre ileri sırada değil, eski bir yerleşim alışkanlığıyla ters sırada tuttu:

```text
slot 1 = hidden7
slot 2 = hidden6
slot 3 = hidden5
slot 4 = hidden4
slot 5 = hidden3
slot 6 = hidden2
slot 7 = hidden1
```

`buildHiddenWithBackwardStorage`, her normatif `k` değerini gerçekten `legacyHidden[8-k]` slotuna yazar.

Gizli damlaların kendileri önceki yamalardan geçen exact sayımlar ve taş tablosu ile hesaplanır. Eski coefficient tablosu da fiziksel olarak ters tutulur; `coeffForHidden` yalnızca o coefficient storage scar'ını doğru `k` hesabına bağlar. Discovery 05'in yeni kusuru coefficient seçimi değil, üretilmiş hidden değerinin near-ness isteğinde yanlış physical slot'tan okunmasıdır.

### Ne keşfedildi

İlk erişim katmanı backward storage'ı normal bir near-ness dizisi sandı:

```text
legacyHiddenDirectByAssumedNearness(legacyHidden, k)
    -> legacyHidden[k]
```

Bu nedenle `hidden1` istendiğinde fiziksel slot 1'de duran `hidden7` döner; `hidden2` istendiğinde `hidden6` döner. Yalnızca orta değer `hidden4`, ters çevirmede kendi slotunda kaldığı için tesadüfen doğrudur.

Yeni normatif regresyon gerçek `LegacyHiddenDropAdapter` erişimini `k = 1,2,4,6,7` için test-only normatif hidden değerleriyle karşılaştırır. `k=4` geçer; diğer dört alt örnek bilinçli olarak kırmızıdır.

### Bu aşamada eklenen canavar katmanı

`LegacyHiddenDropAdapter`, gizli damla deposunu gerçek `calendar_date_spaghetti` state machine'ine bağlar.

Gerçek main yolu storage'ı kurduktan sonra Discovery kusurunu çalıştırmak için `hidden1` near-ness isteğini yanlış direct accessor üzerinden gerçekten okur.

Backward storage, son istenen `k` ve dönen legacy değer yalnızca invocation'a ait `MonsterContext` içinde tutulur.

Bu aşamada `hiddenByNearness(legacyHidden,k) -> legacyHidden[8-k]` çevirmeni yoktur. Fiziksel dizi ters çevrilmez ve doğru erişim katmanı henüz eklenmez.


## Aşama 11 — Yama 05: backward hidden storage için near-ness çevirmeni

### Ne aşıldı

Backward storage fiziksel olarak değiştirilmedi:

```text
slot 1 = hidden7
slot 2 = hidden6
slot 3 = hidden5
slot 4 = hidden4
slot 5 = hidden3
slot 6 = hidden2
slot 7 = hidden1
```

Aşama 10'un yanlış direct accessor'ı da fiziksel olarak korunur:

```text
legacyHiddenDirectByAssumedNearness(legacyHidden, k)
    -> legacyHidden[k]
```

Düzeltme onun üstünde ayrı bir erişim çevirmeni olarak eklenmiştir:

```text
hiddenByNearness(legacyHidden, k)
    -> legacyHidden[8-k]
```

### Neden normatif olarak eşdeğer

Backward storage kurulurken normatif `hiddenK` değeri fiziksel olarak `legacyHidden[8-k]` slotuna yazılır.

Dolayısıyla aynı `8-k` dönüşümünün okunurken tekrar uygulanması, near-ness `k` isteğini tam olarak yazıldığı fiziksel slota götürür.

Fiziksel diziyi ters çevirmeye gerek yoktur; hatta bu tarihsel storage scar'ını yok ederdi.

### Ne korundu

`HiddenNearnessPatchWrapper`, yanlış direct accessor'ı önce gerçekten çağırır ve ham yanlış legacy değeri scar olarak saklar. Ardından `hiddenByNearness` üzerinden doğru değeri döndürür.

Aşama 10'un normatif kırmızı regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca bu erişim çevirmeni sayesinde yeşile döndü.

Backward storage'ın hidden7..hidden1 fiziksel sırası ve yanlış direct accessor'ın davranışı ayrı testlerle korunur.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında şu erişim scar alanları ayrı tutulur:

```text
istenen near-ness k
çevirilmiş fiziksel slot
yanlış direct legacy değeri
doğru çevrilmiş değer
patch uygulanma durumu
```

Logs, metrics ve diagnostics hidden erişim sonucuna girdi değildir. Bu aşamada visible-drop history veya negative-index düzeltmesi başlatılmamıştır.


## Aşama 12 — Keşif 06: görünür history'nin hidden geçmişini bilmemesi

### Ne sanıldı

Görünür damla geçmişi için ilk legacy yardımcı yalnızca görünür drop deposunu tanıyordu:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Bu fonksiyon ancak `i-back >= 1` olduğunda anlamlı bir görünür slot bulabilir.

`LegacyPriorAdapter`, bu eski yardımcıyı production state-machine yoluna bağlar. Visible-drop hesabı henüz kurulmadığı için gerçek calendar yolu yalnızca valid `slot=1` probe çalıştırır; probe semantic calendar çıktısına beslenmez.

### Ne keşfedildi

İlk görünür damlalarda `i-1`, `i-3` ve `i-7` isteklerinin bir kısmı sıfır veya negatif slotlara düşer.

Normatif timeline bu slotları hidden damlalarla doldurur:

```text
slot 0  -> hidden1
slot -1 -> hidden2
slot -2 -> hidden3
...
slot -6 -> hidden7
```

Legacy `dropStore[i-back]` yolu bunları bilmez. Python uygulamasında visible `dropStore` yalnızca pozitif integer anahtarlarla temsil edildiği için `slot<=0` erişimi `KeyError` ile açığa çıkar.

Yeni normatif regresyon adapter yolunu `slot=0`, `slot=-2` ve `slot=-6` için test-only normatif hidden değerleriyle karşılaştırır. Üç alt örnek de bilinçli olarak kırmızıdır.

### Bu aşamada eklenen canavar katmanı

`LegacyPriorAdapter`, son `i`, `back`, hesaplanan slot ve başarılıysa okunan legacy değeri invocation'a ait `MonsterContext` içinde tutar.

Gerçek state-machine probe yalnızca valid görünür slotu kullanarak eski fonksiyonun gerçek üretim zincirinde çağrıldığını kanıtlar; hidden geçmişinin yanlışlığı yeni regresyonda gerçek adapter üzerinden ölçülür.

Bu aşamada `priorPatch` yoktur. `slot<=0` için `hiddenK=1-slot` hesabı yapılmaz ve `hiddenByNearness` çağrılmaz. Grind-table sentinel veya visible-drop grind hesapları da başlatılmamıştır.


## Aşama 13 — Yama 06: nonpositive history slotlarını hidden geçmişe bağlamak

### Ne aşıldı

`legacyPrior` değiştirilmedi:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Pozitif görünür history slotlarında bu eski yol hâlâ gerçek çağrı zincirinin parçasıdır ve hidden storage gerektirmez.

Düzeltme ayrı `priorPatch` katmanındadır:

```text
slot = i - back

if slot >= 1:
    return legacyPrior(dropStore, i, back)

hiddenK = 1 - slot
return hiddenByNearness(legacyHidden, hiddenK)
```

### Neden normatif olarak eşdeğer

Visible timeline'ın ilk elemanından geriye doğru sayıldığında:

```text
slot 0  -> hidden1
slot -1 -> hidden2
slot -2 -> hidden3
...
slot -6 -> hidden7
```

Bu ilişki doğrudan `hiddenK = 1 - slot` eşitliğidir.

`hiddenByNearness`, backward physical hidden storage'ı normatif near-ness değerine çevirdiği için nonpositive branch doğru hidden geçmişi bulur.

Pozitif branch ise hidden storage'a hiç ihtiyaç duymadan eski `legacyPrior` çağrısını gerçekten korur.

### Ne korundu

Aşama 12'nin normatif kırmızı regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca `priorPatch` sayesinde yeşile döndü.

`legacyPrior` fiziksel olarak hidden storage bilmeden kalır.

Discovery aşamasındaki temporary `KeyError` state testi PATCH sonrası gerçekliği yansıtacak biçimde güncellendi; normatif regresyona dokunulmadı.

### Bu aşamada eklenen canavar katmanı

`PriorPatchWrapper`, invocation bağlamında hesaplanan slotu, hidden branch kullanımını, varsa hiddenK değerini ve patched sonucu tutar.

Visible branch'in hidden storage istememesi ayrıca regression ile dondurulmuştur.

Logs, metrics ve diagnostics history sonucuna girdi değildir. Grind-table sentinel veya visible-drop grind hesapları hâlâ başlatılmamıştır.


## Aşama 14 — Keşif 07: 1-based grind indeksini 0-based tabloya doğrudan vermek

### Ne sanıldı

Görünür damla için 11 gerçek öğütme satırı normal Python tablosunda `index 0..10` olarak tutuldu.

Legacy kod ise öğütmeleri tarihsel olarak `1..11` numaralarıyla yürüttü ve bu numarayı doğrudan tablo indeksi sandı:

```text
legacyGrindRow(table, grind)
    -> table[grind]
```

Tabloda sentinel yoktur.

### Ne keşfedildi

`grind=1` ilk gerçek satırı değil, ikinci gerçek satırı okur.

Böylece görünür damla ilk normatif öğütmeyi tamamen atlar ve gerçek satır 2 ile başlar.

`grind=10` gerçek satır 11'i okur.

`grind=11` için tablo index 11 mevcut değildir.

Discovery yolu bu son `IndexError` durumunu recovery scar olarak kaydeder ve o noktaya kadar oluşmuş yanlış `x` değerini döndürür. Bu recovery bir düzeltme değildir: ilk gerçek satır hâlâ atlanmıştır ve yalnızca 10 yanlış hizalanmış grind uygulanmıştır.

### Gerçek görünür damla yolu

Bu aşamada visible-drop builder ilk kez tam 1..46 zinciriyle üretime bağlandı.

Her görünür damla:

```text
prev1 = priorPatch(...)
prev3 = priorPatch(...)
prev7 = priorPatch(...)
base x = SAVE(...)
x = legacy grind-table yolu
```

ile hesaplanır.

History erişimi Patch 06 üzerinden doğru hidden/visible timeline'ı görür. Taşlar ve count değerleri de önceki yamalardan gelir. Bu aşamadaki yeni divergence yalnızca grind tablosunun indeks hizasındadır.

Yeni normatif regresyon gerçek builder yolunun görünür damla 1, 2 ve 46 değerlerini test-only normatif visible-drop builder ile karşılaştırır. Üç alt örnek bilinçli olarak kırmızıdır.

### Önceki instrumentation ile etkileşim

Aşama 12'nin gerçek-yol `legacyPrior` instrumentation testi başlangıçta tek probe çağrısı bekliyordu.

Visible-drop builder artık aynı prior yolunu doğal olarak çok kez çağırdığı için exact-count koşulu tarihsel olarak geçersiz oldu. Yalnızca instrumentation genişletildi: ilk çağrının hâlâ Stage 12'nin `(i=2, back=1)` probe'u olduğu doğrulanır.

Aşama 12'nin normatif history regresyonuna dokunulmadı.

### Bu aşamada eklenen canavar katmanı

`LegacyVisibleDropBuilderAdapter`, 46 görünür damlayı yeni bir production katmanı olarak üretir.

Invocation bağlamında görünür damla tablosu, damla sayısı, son eksik legacy grind indeksi ve uygulanmış grind satırı sayısı tutulur.

Bu aşamada sentinel row yoktur. Gerçek 11 grind satırı 1..11 slotlarına taşınmamıştır ve Patch 07 henüz eklenmemiştir.


## Aşama 15 — Yama 07: 1-based grind indexing için kalıcı sentinel row

### Ne aşıldı

Legacy indexing değiştirilmedi:

```text
legacyGrindRow(table, grind)
    -> table[grind]
```

Bunun yerine tablo fiziksel olarak yeniden katmanlandı.

Tarihsel zero-based tablo da scar olarak kodda kalır:

```text
LEGACY_VISIBLE_GRIND_TABLE
    -> 11 gerçek row, index 0..10
```

Patch tablosu:

```text
index 0    -> SENTINEL_GRIND_ROW
index 1..11 -> 11 gerçek grind row
```

olarak kurulur.

### Sentinel neden var

Legacy loop grind numaralarını `1..11` üretir.

`table[grind]` davranışını değiştirmeden doğru row'a ulaşmanın tarihsel detour'u, index 0'a kullanılmayan bir sentinel yerleştirmektir.

Böylece:

```text
grind 1  -> gerçek row 1
grind 2  -> gerçek row 2
...
grind 11 -> gerçek row 11
```

olur.

Sentinel normal grind loop'unda okunmaz; yalnızca fiziksel hizalama scar'ıdır.

### Ne korundu

Aşama 14'ün normatif visible-drop regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca sentinel hizalaması sayesinde yeşile döndü.

`legacyGrindRow` fonksiyonunun `table[grind]` davranışı değiştirilmedi.

Eski 11-row zero-based `LEGACY_VISIBLE_GRIND_TABLE` fiziksel olarak kodda tutulur.

IndexError recovery scar da kaldırılmadı; sentinel table ile normal `1..11` yolunda artık tetiklenmez.

Müfredat gereği sentinel ileride de silinmemelidir.

### Bu aşamada eklenen canavar katmanı

`SENTINEL_GRIND_ROW` ve `GRIND_TABLE_WITH_SENTINEL`, eski tablonun üstünde yeni fiziksel katmandır.

Invocation bağlamı sentinel tablosunun kullanıldığını, tablo uzunluğunu ve patch uygulanma durumunu tutar.

Görünür drop builder'ın 46 satırının tamamı test-only normatif visible-drop builder ile aynı sonucu verir.

Permutation rank kusuru veya Patch 08 henüz eklenmemiştir.


## Aşama 16 — Keşif 08: 1-based order numarasını rank0 sanmak

### Ne sanıldı

Eski permütasyon helper'ı sıfır tabanlı bir rank bekler:

```text
oldPermutationUnrank0(rank0)
```

Geçerli aralığı:

```text
0..719
```

ve bu aralıkta lexicographic altı-kâse permütasyonunu doğru biçimde unrank eder.

Yeni tarihsel kusur helper'ın içinde değildir.

Drop değerinden önce 1-based order numarası üretilir:

```text
oneBased = regularMod(drop-1,720)+1
```

Legacy çağrı yolu bu `1..720` değerini yanlışlıkla doğrudan `rank0` sanır:

```text
order = oldPermutationUnrank0(oneBased)
```

### Ne keşfedildi

Normatif order numarası `oneBased` ise sıfır tabanlı helper'a verilmesi gereken değer bir eksiktir.

Discovery yolunda bu eksiltme yoktur.

Bu nedenle `oneBased=1` normatif ilk permütasyon yerine rank0=1 olan ikinci permütasyonu döndürür.

Aynı off-by-one bütün 1..719 değerlerinde sürer.

`oneBased=720` ise 0-based helper'ın aralığının dışındadır. Order-table adapter bu tarihsel uç durumu warning/scar olarak kaydeder; bu recovery Patch 08 değildir.

### Gerçek production yolu

`LegacyPermutationOrderAdapter`, Stage 15'te exact hâle gelen 46 görünür drop değerinin her biri için legacy order türetir.

Bu order tablosu gerçek `calendar_date_spaghetti` state-machine zincirine bağlanmıştır.

Pours ve bowl alias katmanı henüz başlatılmaz; Stage 16 yalnızca permutation rank kusurunu görünür kılar.

Yeni normatif regresyon gerçek order-table yolunun `i=1`, `i=2` ve `i=46` order değerlerini test-only normatif `bowl_order_from_drop` ile karşılaştırır. Üç alt örnek bilinçli olarak kırmızıdır.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında 46-order tablosu, son drop indeksi/değeri, hesaplanan 1-based değer ve dönen legacy order tutulur.

Varsa `oneBased=720` uç durumu ayrıca invocation-local scar alanlarında tutulur.

Bu aşamada `legacyRank0 = oneBased - 1` yoktur. Patch 08 zinciri henüz eklenmemiştir. Stage 15 sentinel olduğu gibi korunur.


## Aşama 17 — Yama 08: 1-based order numarasını legacy rank0'a çevirmek

### Ne aşıldı

`oldPermutationUnrank0(rank0)` değiştirilmedi.

Discovery 08'in yanlış caller'ı da fiziksel olarak korunur:

```text
oneBased = regularMod(drop-1,720)+1
legacyOrderFromDropWrong(drop)
    -> oldPermutationUnrank0(oneBased)
```

Patch authoritative zinciri ayrı fonksiyondadır:

```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```

### Neden normatif olarak eşdeğer

Normatif bowl order numarası 1-based `1..720` aralığındadır.

Tarihsel unrank helper 0-based `0..719` aralığını bekler.

Bu iki coordinate sistemi arasındaki tek exact dönüşüm:

```text
legacyRank0 = oneBased - 1
```

eşitliğidir.

Böylece `oneBased=1 -> rank0=0` ve `oneBased=720 -> rank0=719` olur.

### Ne korundu

`PermutationRankPatchWrapper`, Discovery 08'in yanlış caller'ını önce gerçekten çağırır.

Yanlış caller başarılıysa yanlış order scar olarak tutulur.

`oneBased=720` durumunda yanlış caller'ın `ValueError` üretmesi de scar olarak tutulur; authoritative patch yine rank0=719 ile doğru order'ı üretir.

Ardından zorunlu patched chain çalışır ve yalnızca corrected order semantic sonuç olarak döner.

Aşama 16'nın normatif order regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca bu rank çevirisi sayesinde yeşile döndü.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında drop index, oneBased, legacyRank0, yanlış caller order/error scar'ı, corrected order ve patch uygulanma durumu ayrı tutulur.

Bütün 46 visible-drop order'ı test-only normatif bowl order ile eşleşir.

Stage 15'in kalıcı grind sentinel row'u aynen korunur.

Pours, bowlAlias ve Patch 09 henüz başlatılmamıştır.


## Aşama 18 — Keşif 09: pour positions yerine sabit bowl ID 1,2,3 okumak

### Ne sanıldı

İlk bowl factory doğru başlangıç kâselerini üretir.

Legacy pour kodu ise eski position düşüncesini sabit bowl ID sanmıştır:

```text
pour position 1 -> B[1]
pour position 2 -> B[2]
pour position 3 -> B[3]
```

Bu nedenle helper:

```text
legacyFixedBowlPours(...)
```

ilk üç pour değerini current permutation order'ını bowl seçimi için kullanmadan hesaplar.

### Ne keşfedildi

Normatif anlamda `pour[1]`, `pour[2]`, `pour[3]` birer position değeridir.

Current order:

```text
order[position]
```

hangi gerçek bowl ID'nin o position'da olduğunu belirler.

Dolayısıyla doğru bowl read:

```text
B[order[1]]
B[order[2]]
B[order[3]]
```

olmalıdır.

Discovery 09'da bu alias henüz yoktur.

Örneğin order position 1 bowl 5 ise legacy hâlâ bowl 1'i okur.

### Gerçek production yolu

`LegacyPourAdapter`, exact initial bowls, Stage 15 exact visible drops ve Stage 17 exact permutation orders üstünde çalışır.

Gerçek `calendar_date_spaghetti` state-machine yolu drop 1 için legacy fixed-bowl pour probe çalıştırır.

Bowl stir/update henüz başlatılmaz. Böylece Stage 18 yalnızca Patch 09 kusurunu ekler; in-place bowl contamination olan Patch 10 erkenden ortaya çıkmaz.

Yeni normatif regresyon aynı gerçek adapter yolunu `i=1`, `i=2` ve `i=3` için test-only normatif position-based pour formülüyle karşılaştırır. Üç alt örnek bilinçli olarak kırmızıdır.

`i=46` bu regresyon için kullanılmaz çünkü o fixture'da ilk üç order position'ı tesadüfen bowl 1,2,3'tür ve legacy kusuru görünmez.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında exact initial bowl tuple'ı, son pour drop indeksi, son exact order ve son legacy pour tuple'ı tutulur.

Bu aşamada `bowlAlias` yoktur. Alias install/read helper'ı, vaultOld, pending writes veya Patch 10 kodu eklenmemiştir.

Stage 15 sentinel ve Stage 17 permutation rank patch aynen korunur.


## Aşama 19 — Yama 09: order positions için bowlAlias katmanı

### Ne aşıldı

Discovery 09'un fiziksel yanlış helper'ı değiştirilmedi:

```text
legacyFixedBowlPours(...)
    position 1 -> B[1]
    position 2 -> B[2]
    position 3 -> B[3]
```

Bu helper hâlâ sabit bowl ID okur.

Patch ayrı alias katmanındadır.

Current exact order için:

```text
bowlAlias[position] = order[position]
```

ilişkisi kurulur.

Python tuple fiziksel düzeninde bunun karşılığı:

```text
bowlAlias[1] = order[0]
...
bowlAlias[6] = order[5]
```

şeklindedir.

### Corrected bowl read

Bütün corrected pour bowl read'leri tek helper üzerinden geçer:

```text
bowlByLegacyPosition(oldBowls, bowlAlias, position)
    -> oldBowls[bowlAlias[position]]
```

`aliasedPositionPours` position 1,2,3 için doğrudan order veya sabit bowl ID okumaz.

Üç read de bu helper'ı kullanır.

### Ne korundu

`BowlAliasPatchWrapper`, yanlış `legacyFixedBowlPours` helper'ını önce gerçekten çalıştırır ve ham fixed-bowl pour tuple'ını scar olarak tutar.

Ardından alias table'ı kurar ve corrected pours üretir.

Yalnızca corrected tuple semantic sonuç olarak döner.

Aşama 18'in normatif pour regresyonunun gövdesi byte-for-byte değiştirilmedi ve yalnızca alias katmanı sayesinde yeşile döndü.

Exact initial bowls, Stage 15 sentinel ve Stage 17 permutation rank patch aynen korunur.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında son drop indeksi, bowlAlias tuple'ı, wrong fixed-bowl pour scar'ı, corrected pour tuple'ı ve patch uygulanma durumu tutulur.

46 visible drop için isolated pour tuple'ları test-only normatif position-based formülle eşleşir.

Bowl stir/update henüz uygulanmaz. `vaultOld`, `pending` ve in-place contamination olan Patch 10 kodu eklenmemiştir.


## Aşama 20 — Keşif 10: kâse güncellemelerini yerinde yaparak sonraki okumaları kirletmek

### Ne sanıldı

Legacy bowl update loop altı position'ı sırayla yürütür.

Her position için current bowl, previous bowl ve next bowl okunur; yeni değer hesaplanır ve aynı bowl storage'a hemen yazılır.

Legacy helper:

```text
legacyInPlaceBowlUpdateWrong(...)
```

tek bir `working` bowl listesi kullanır.

### Ne keşfedildi

Birinci position kendi yazısından önce yalnızca eski değerleri görür.

Fakat birinci position'ın bowl'u yazıldıktan sonra ikinci ve sonraki position'lar komşuluk ilişkisine bağlı olarak bu yeni değeri okuyabilir.

Bu nedenle altı bowl aynı logical step'e ait olmasına rağmen read set'i tek bir eski snapshot'tan gelmez.

Sonuç order-dependent contamination taşır.

### Normatif karşılaştırma

Test-only normatif one-drop formülü her read'i aynı `old` bowl tuple'ından yapar ve altı sonucu ayrı `next_bowls` içine yazar.

Discovery path ise aynı bowl listesine anında yazar.

Drop 1 fixture'ında position 1 henüz contamination görmediği için normatif değerle eşleşir; sonraki positions arasında ayrışma oluşur.

Normatif regresyon position 2, 3 ve 6 bowl sonuçlarını karşılaştırır ve üç alt örnek bilinçli olarak kırmızıdır.

### Gerçek production yolu

Stage 19 corrected pour probe'dan sonra gerçek `calendar_date_spaghetti` state-machine yolu drop 1 için `LegacyBowlUpdateAdapter` çağırır.

Böylece wrong in-place helper gerçekten production path üzerindedir.

Stage 20 yalnızca tek-drop bowl update scar'ını kurar.

46-drop full bowl pass, order-at-46 latch ve post-stir henüz başlatılmaz; böylece Patch 11 erkenden eklenmez.

### Bu aşamada eklenen canavar katmanı

Invocation bağlamında son drop index, input bowl tuple, pour tuple ve yanlış in-place result tutulur.

Bu aşamada snapshot bowl clone, ayrı write buffer veya altı position sonrası toplu commit yoktur.

Stage 15 sentinel, Stage 17 permutation patch ve Stage 19 bowlAlias patch aynen korunur.


## Aşama 21 — Yama 10: tek eski snapshot, ayrı pending buffer ve altı position sonrası commit

Discovery 10'un `legacyInPlaceBowlUpdateWrong` helper'ı fiziksel olarak korunur ve hâlâ aynı working storage'dan okuyup anında aynı storage'a yazar.

Corrected yol önce fiziksel bir eski snapshot oluşturur:

```text
vaultOld = clone(B)
```

Altı position boyunca current, previous ve next bowl read'lerinin tamamı yalnızca `vaultOld` üzerinden yapılır. Yeni bowl değerleri `pending` buffer'a yazılır. Semantic commit ancak altı position tamamlandıktan sonra `pending` tuple olarak döner.

`BowlMutationPatchWrapper` wrong helper'ı önce gerçekten çalıştırıp contaminated raw sonucu scar olarak tutar. Sonra snapshot patch'i çalıştırır. `vaultOld`, `pending`, wrong result, corrected result ve commit-after-six durumu invocation-local bağlamda saklanır.

Aşama 20 normatif bowl-update regresyonunun gövdesi byte-for-byte değiştirilmeden yeşile döner.

Stage 21 hâlâ tek-drop bowl-update katmanını düzeltir. 46-drop full pass, order-at-46 latch ve post-stir henüz yoktur. Stage 15 sentinel, Stage 17 permutation patch ve Stage 19 bowlAlias patch korunur.


## Aşama 22 — Keşif 11: drop 46 order değerini genel order belleğinde tutup post-stir sırasında ezmek

### Ne sanıldı

Legacy katmanda tek bir genel order belleği yeterli sayıldı.

46 drop boyunca her yeni drop order değeri aynı alana yazılır.

Drop 46 tamamlandığında alan geçici olarak doğru drop 46 order değerini taşır.

Ardından 12 post-stir başlar ve her stir kendi order değerini yine aynı genel alana yazar.

Sonuçta query katmanı drop 46 order yerine stir 12 order değerini görür.

### Tam 46-drop ve 12-stir yolu

Bu aşamada production ilk kez:

```text
46 drop bowl round
12 post-stir round
```

zincirini tam olarak yürütür.

Her drop için Stage 19 corrected pour ve Stage 21 snapshot bowl update kullanılır.

Post-stir round formülü exact olarak:

```text
savedStirSum = SAVE(sum(oldBowls) + 149*stir)
order = permutation(savedStirSum)
all reads = same old snapshot
all writes = one pending batch
```

şeklindedir.

Bu tam bowl yolu test-only normatif bowl sonuçlarıyla eşleşir.

Yeni kusur bowl değerlerinde değil, order belleğinin sahipliğindedir.

### Overwrite scar

`legacy_overwritable_order_memory` toplam 58 kez yazılır:

```text
46 drop write
12 stir write
```

Son kaynak `("stir",12)` olur.

`query_order` bu genel belleği döndürür.

Drop 46 için ayrı latch yoktur.

Yeni normatif regresyon semantic `query_order` sonucunu drop 46 exact order ile karşılaştırır. Position 1, 2 ve 6 alt örnekleri bilinçli kırmızıdır.

### Önceki instrumentation genişletmesi

Aşama 18 fixed-pour ve Aşama 20 in-place-update real-path spy testleri daha önce tam bir çağrı bekliyordu.

Full 46-drop production yolu bu scar helper'ları doğal olarak daha fazla çağırdığı için yalnızca instrumentation koşulu genişletildi: ilk gerçek çağrının hâlâ drop 1 probe'u olduğu doğrulanır.

Önceki normatif regresyonlara dokunulmadı.

### Sınır

Bu aşamada drop 46 için ayrı latch yoktur ve `query_order` son yazılan genel order belleğini okur.

Bir sonraki yama latch'i post-stir öncesi tek kez kurmalıdır ve sonra onu bir daha yazmamalıdır.

Queried next-bowl ID mantığı olan Patch 12 henüz eklenmemiştir.
