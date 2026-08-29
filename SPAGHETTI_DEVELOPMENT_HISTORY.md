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


## Aşama 23 — Yama 11: drop 46 order için tek-yazımlı latch

Discovery 11'in genel order belleği fiziksel olarak korunur. Bu alan 46 drop ve 12 post-stir boyunca toplam 58 kez yazılır ve sonunda stir 12 order değerini taşır.

Drop 46 bowl roundu bittikten ve ilk post-stir başlamadan hemen önce exact drop 46 order fiziksel clone ile ayrı latch'e yazılır:

```text
orderAt46Latch = clone(order46)
```

Latch invocation başına yalnızca bir kez yazılır. İkinci yazma girişimi reddedilir. Post-stir sırasında latch'e hiçbir write yapılmaz.

`query_order` artık genel overwritable belleği değil yalnızca `orderAt46Latch` değerini okur.

Aşama 22 normatif overwritten-order regresyonunun gövdesi byte-for-byte değiştirilmeden yeşile döner.

Aşama 1 future-patch isim guard'ında `orderAt46Latch` artık gelecek kod olmadığı için yalnızca bu token yasak listesinden çıkarılmıştır; Patch 12 ve sonrası yasakları korunur.

Stage 15 sentinel, Stage 17 permutation patch, Stage 19 bowlAlias patch ve Stage 21 snapshot/pending patch aynen korunur. Patch 12 queried next-bowl logic henüz yoktur.


## Aşama 24 — Keşif 12: sonraki kâseyi current order yerine sabit ID halkasından almak

Legacy kod bowl ID değerlerinin doğal olarak fiziksel sırada dizildiğini varsayar. `oldNextBowlFixedName(id)` bu nedenle `1->2->3->4->5->6->1` halkasını "sonraki kâse" kabul eder.

Stage 23 exact drop 46 order değerini `orderAt46Latch` içinde korur. Bu fixture'da latch `(1,2,3,4,6,5)` değeridir. Dolayısıyla queried 4 için next 6, queried 6 için next 5 ve queried 5 için next 1 olmalıdır. Legacy helper sırasıyla 5, 1 ve 6 üretir.

`LegacyNextBowlAdapter`, Stage 23 latch hazırlandıktan sonra gerçek `calendar_date_spaghetti` state-machine zincirine bağlanır. Production probe queried ID'yi latch'in dördüncü position'ından alır; yani geçersiz veya yapay bir ID kullanmaz.

Yeni normatif regresyon actual adapter yolunu queried ID 4, 5 ve 6 için test eder ve expected değeri test-only olarak latch içindeki circular successor'dan hesaplar. Üç alt örnek bilinçli kırmızıdır.

Bu aşamada production içinde latch-position arama veya corrected circular-successor detour'u yoktur. Aşama 1 future-name guard zaten Patch 13+ isimleriyle sınırlı olduğundan değiştirilmemiştir. Patch 13 ve sonrası kod eklenmemiştir.


## Aşama 25 — Yama 12: queried ID için latch-position circular successor

### Ne korundu

Discovery 12'nin tarihsel helper'ı fiziksel olarak kalır:

```text
oldNextBowlFixedName(id)
1->2->3->4->5->6->1
```

Bu helper hâlâ yanlış fixed numeric ID successor üretir.

`NextBowlPatchWrapper` helper'ı diagnostic scar olarak gerçekten çağırır ve sonucunu invocation-local bağlamda saklar.

### Authoritative semantic yol

Corrected yol queried ID'yi `orderAt46Latch` içinde arar.

Bulunan position için semantic next bowl:

```text
orderAt46Latch[(position+1) mod 6]
```

değeridir.

Bu yol numeric ID sırasına hiçbir anlam yüklemez.

Latch son position için wraparound ilk position'a gider.

### Regresyon

Aşama 24'ün normatif next-bowl regresyonunun gövdesi byte-for-byte değiştirilmedi.

Queried ID 4, 5 ve 6 alt örnekleri yalnızca latch-position circular successor detour'u sayesinde yeşile döndü.

Ayrıca latch içindeki altı ID'nin tamamı corrected adapter üzerinden test edilir.

### Sınır

Patch 13 biased modulo selection kodu henüz yoktur.

Stage 15 sentinel, Stage 17 permutation patch, Stage 19 bowlAlias patch, Stage 21 snapshot/pending patch ve Stage 23 orderAt46Latch aynen korunur.


## Aşama 26 — Keşif 13: rejection öncesi doğrudan modulo selection

### Answer ring

Bu aşamada production answer ring katmanı eklenir.

Final post-stir bowl state ve Stage 25 latch-based next-bowl semantics kullanılarak:

```text
first = SAVE((B[queried]+seal+181)^2 + B[next]*179 + seal)
directionNumber = SAVE((first+seal+1+193)^2 + first*193 + B[6]*197)
step = odd(directionNumber) ? +1 : -1
answerAt(k) = 1 + regularMod(first-1 + step*k, M)
```

hesaplanır.

Bu bölüm test-only normatif answer stream ile eşleşir.

### Tarihsel kusur

`biasedLegacyPick(x,N)` doğrudan:

```text
regularMod(x-1,N)+1
```

döndürür.

Acceptance/rejection kontrolü yoktur.

`LegacyBiasedSelectionAdapter`, real answer ring'in ilk cevabını alır ve helper'ı hemen çağırır.

### Normatif ayrışma

Test fixture'ları gerçek sauce state'inden üretilir.

Queried/seal çiftleri:

```text
(1,21)
(5,21)
(2,31)
```

için ring direction `-1` ve first değeri `M/2` üstündedir.

Test probe family size:

```text
N = first - 1
```

seçildiğinde first answer rejection bölgesindedir ve aynı answer ring'de tek geri adım kabul bölgesine girer.

Legacy direct modulo ile rejection sonrası modulo bu üç gerçek adapter yolunda ayrışır.

### Sınır

Production bu aşamada `limit=floor(M/N)*N` hesaplamaz.

Production answer ring üzerinde rejection ilerlemesi yapmaz.

`biasedLegacyPick` acceptance yapılmadan çağrılır.

Aşama 1 future-name guard içinde `biasedLegacyPick` artık current Discovery 13 olduğu için yalnızca bu token gelecek-kod listesinden çıkarılmıştır.

Patch 14 wide selection kodu henüz yoktur.


## Aşama 27 — Yama 13: aynı answer ring üzerinde rejection, sonra legacy modulo

Discovery 13'ün `biasedLegacyPick(x,N)` helper'ı fiziksel olarak ve doğrudan modulo davranışıyla korunur.

`SelectionRejectionPatchWrapper` kısa seçimde `limit=floor(M_OLD/N)*N` hesaplar, offset 0'dan başlar ve yalnız aynı `LegacyAnswerRing` üzerinde `x<=limit` olana kadar ilerler. Legacy helper rejected answer için çağrılmaz; yalnız accepted answer bulunduktan sonra çağrılır.

Aşama 26 normatif biased-selection regresyonunun gövdesi byte-for-byte değiştirilmeden yeşile döner. Üç sauce-derived fixture'da first answer reddedilir ve aynı ring'de offset 1 accepted answer olur.

`x==limit`, `N=1` ve `N=M_OLD` sınırları ayrıca doğrulanır.

Real calendar probe, eski testlerin kullandığı herhangi bir tarihte uzun ring yürüyüşü oluşturmamak için bounded tutulur: direction `-1` ve first `M/2` üstündeyse `N=first-1` ile tek-adımlı rejection kullanılır; diğer durumlarda `N=M_OLD` seçilip first answer hemen kabul edilir. Bu yalnız stage probe güvenliğidir; semantic short-selection wrapper aynı authoritative rejection kuralını uygular.

`N>M_OLD` wide dispatcher ve `wideDetour` henüz yoktur.


## Aşama 28 — Keşif 14: N>M ailesini short-only dispatcher'a zorlamak

### Tarihsel varsayım

Legacy selection katmanı yalnız kısa aileleri bilir.

Stage 27 short path contract'ı:

```text
1 <= N <= M_OLD
```

ile sınırlıdır.

Yeni `LegacyShortOnlySelectionDispatcher`, family size ne olursa olsun bu short adapter'ı çağırır.

### N>M davranışı

`N>M_OLD` geldiğinde short adapter doğal olarak `ValueError` üretir.

Discovery dispatcher bu exception'ı wide destek yokluğunun scar'ı olarak kaydeder:

```text
legacy_wide_selection_unsupported = True
legacy_wide_selection_error = ...
legacy_general_selection_result = None
```

Bu recovery yalnız stage state-machine'in StageNotIntegratedError noktasına ulaşmasını sağlar; semantic wide rank değildir.

### Gerçek production yolu

Real calendar path Stage 27 short probe'undan sonra aynı exact answer ring ile:

```text
N = M_OLD + 1
```

wide family girişimini gerçekten çalıştırır.

Bu girişim short-only dispatcher tarafından unsupported olarak kaydedilir.

### Normatif regresyon

Normatif regresyon aynı production adapter'ı üç wide family size için çağırır:

```text
M_OLD + 1
M_OLD^2
M_OLD^3
```

Test-only oracle her biri için exact wide rank üretir.

Legacy dispatcher ise üçünde de semantic result üretemez; üç alt örnek bilinçli kırmızıdır.

### Sınır

Bu aşamada production içinde:

```text
if N<=M: short
else: patched wide path
```

dispatcher yoktur.

Multi-place base-M wide number inşası yoktur.

Wide number rejection walk yoktur.

Rejection sırasında digits üretme veya üretmeme davranışı production'da henüz başlamamıştır.

Stage 29 yalnız bu kusuru patch edecektir.


## Aşama 29 — Yama 14: wide dispatcher ve tek-seferlik base-M digits

### Legacy scar

Discovery 14'ün `LegacyShortOnlySelectionDispatcher` adı ve short-only varsayımı fiziksel olarak korunur.

`N>M_OLD` geldiğinde patched wrapper eski short adapter'ı diagnostic scar olarak gerçekten çağırır. Short adapter ValueError üretir ve unsupported-wide scar durumu saklanır.

Bu error artık semantic sonucu durdurmaz.

### Dispatcher

`WideSelectionPatchWrapper`:

```text
if N<=M_OLD:
    Stage 27 short path
else:
    diagnostic old short attempt
    wideDetour
```

zincirini uygular.

Short path değiştirilmez.

### Wide detour

`N>M_OLD` için minimal places bulunur:

```text
places = 1
space = M_OLD
while space < N:
    places += 1
    space *= M_OLD
```

Digits yalnız bir kez aynı answer ring'den alınır:

```text
digits[j] = answerAtRing(ring,j)-1
wide = 1 + Σ digits[j]*M_OLD^j
```

Digits little-endian base-M ağırlıklarıyla birleşir.

### Wide rejection

Acceptance limit:

```text
acceptance_limit = floor(space/N)*N
```

olur.

`wide > acceptance_limit` olduğu sürece:

```text
wide = 1 + regularMod(
    wide - 1 + direction_step,
    space
)
```

uygulanır.

Rejection sırasında `answerAtRing` yeniden çağrılmaz ve yeni digit üretilmez.

### Regresyon

Aşama 28 normatif wide-selection regresyonunun gövdesi byte-for-byte değiştirilmedi.

`M_OLD+1`, `M_OLD^2` ve `M_OLD^3` alt örnekleri yalnız wide detour sayesinde yeşile döner.

Synthetic -1 ve +1 direction testleri rejection boyunca answerAtRing çağrı sayısının yalnız `places` kadar kaldığını doğrular.

### Sınır

Patch 15 negative gate question kodu henüz yoktur.

Stage 27 short rejection, Stage 25 next-bowl, Stage 23 latch ve tüm önceki scar'lar korunur.


## Aşama 30 — Keşif 15: negatif gate sorusunu pozitif tarafa yöneltmek

### Tarihsel helper

Yeni legacy helper fiziksel olarak:

```text
oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n
```

davranışını taşır.

Helper yön işareti bilmez; yalnız sıfır veya pozitif uzaklık alır.

### Legacy adapter

`LegacyGateQuestionAdapter` signed gate step değerini alır fakat:

```text
magnitude=abs(signed_step)
question_day=oldGateQuestionDay(magnitude)
```

uygular.

Bu nedenle pozitif step değerleri legacy ile uyumludur fakat negatif step değerleri Foundation'ın yanlış tarafına gider.

### Gerçek production yolu

`calendar_date_spaghetti` Stage 29 wide-selection probe'undan sonra:

```text
signed_step=-1
```

ile legacy gate-question adapter'ı gerçekten çalıştırır.

Patch 15 detour'u olmadığı için real path yanlış positive-side günü üretir.

### Normatif regresyon

Yeni normatif regresyon actual adapter yolunu:

```text
-1
-2
-10
```

signed step değerlerinde çalıştırır.

Beklenen gün:

```text
FOUNDATION_DAY-abs(signed_step)
```

olur.

Legacy actual gün:

```text
FOUNDATION_DAY+abs(signed_step)
```

olduğu için üç alt örnek bilinçli kırmızıdır.

### Sınır

Bu aşamada `signed_step<0` için ayrı corrected detour yoktur.

`oldGateQuestionDay` değiştirilmemiştir.

Patch 16 `LEGACY_YEAR_MAX=5781` kodu henüz yoktur.


## Aşama 31 — Yama 15: yalnız negatif gate adımında Foundation'ın negatif tarafına geçmek

### Korunan legacy scar

`oldGateQuestionDay(n)` fiziksel olarak değişmeden kalır:

```text
oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n
```

`NegativeGatePatchWrapper`, bütün signed step değerleri için bu helper'ı diagnostic scar olarak gerçekten çağırır.

### Semantic detour

Wrapper:

```text
magnitude=abs(signed_step)
legacy_positive_day=oldGateQuestionDay(magnitude)

if signed_step<0:
    corrected_day=FOUNDATION_DAY_OLD-magnitude
else:
    corrected_day=legacy_positive_day
```

uygular.

Bu nedenle zero ve positive step davranışı legacy ile aynen kalır.

Yalnız negative step semantic question day Foundation'ın negatif tarafına taşınır.

### Regresyon

Aşama 30 normatif negative-gate regresyonunun gövdesi byte-for-byte değiştirilmedi.

`-1`, `-2` ve `-10` alt örnekleri yalnız Patch 15 detour'u sayesinde yeşile döner.

Ek testler `-101`, zero/positive uyumluluğu, invocation-local patch state ve gözlem verilerinin semantic sonucu değiştirmemesi durumlarını doğrular.

### Sınır

Patch 16 `LEGACY_YEAR_MAX=5781` ve 5778 late-filter kodu henüz yoktur.

Stage 29 wide patch ve tüm önceki scar'lar aynen korunur.


## Aşama 32 — Keşif 16: legacy yıl tavanını 5781 olarak sort/selection girişine taşımak

Production içine zorunlu `LEGACY_YEAR_MAX=5781` sabiti eklenir ve `legacyYearCandidateAllowed` bu sabiti gerçek candidate ceiling olarak kullanır.

Legacy candidate koşulu:

```text
gate_gap_count>=6
252<=candidate.length<=LEGACY_YEAR_MAX
```

olduğundan 5779, 5780 ve 5781 günlük adaylar kabul edilir.

`LegacyYearCandidateAdapter.prepare_for_selection` accepted family'yi mevcut historical stable length-only sort girişine taşır. Adapter ayrıca selection metodunu da taşır; ancak real calendar boundary probe önceki selection call-count scar sözleşmelerini bozmamak için bu aşamada yalnız acceptance/sort girişini çalıştırır.

Real `calendar_date_spaghetti` state-machine Stage 31 gate-question katmanından sonra `5778,5779,5780,5781` boundary candidate ailesini actual adapter üzerinden çalıştırır. Dördü de legacy ceiling'den geçer.

Test-only normatif sınır `YEAR_MAX_DAYS=5778` olduğundan 5779, 5780 ve 5781 alt örnekleri bilinçli kırmızıdır.

Production içinde `REAL_YEAR_MAX_PATCH=5778` veya 5778 üstünü sort/selection öncesi atan filtre henüz yoktur. Legacy sabit değiştirilmez. Patch 17 tie düzeltmesi de henüz yoktur.


## Aşama 33 — Yama 16: 5781 scar üstünde 5778 early candidate filtresi

### Değişmeyen legacy sabit

Discovery 16 sabiti aynen korunur:

```text
LEGACY_YEAR_MAX=5781
```

`legacyYearCandidateAllowed` hâlâ bu legacy ceiling'i kullanır ve 5779, 5780, 5781 adaylarını kendi katmanında kabul eder.

### Ayrı gerçek tavan

Yeni patch sabiti:

```text
REAL_YEAR_MAX_PATCH=5778
```

olarak eklenir.

`YearMaxPatchWrapper` her candidate için önce legacy helper'ı gerçekten çalıştırır ve legacy-accepted family'yi diagnostic scar state içinde saklar.

Ardından yalnız legacy kabulünden geçmiş candidate için:

```text
if candidate.length>REAL_YEAR_MAX_PATCH:
    reject
```

uygular.

### Sıralama ve selection öncesi filtre

Patch sonucu kabul edilmeyen candidate `accepted` listesine hiç eklenmez.

Bu nedenle 5779..5781 adayları:

```text
legacy scar family: var
semantic pre-sort family: yok
sorted family: yok
selection family: yok
```

durumundadır.

Stable length-only legacy sort fiziksel olarak korunur ve yalnız patched family üzerinde çalışır.

### Regresyon

Aşama 32 normatif 5781-ceiling regresyonunun gövdesi byte-for-byte değiştirilmedi.

5779, 5780 ve 5781 alt örnekleri yalnız early 5778 filter sayesinde yeşile döner.

Ek testler legacy helper'ın gerçekten çağrılmasını, exact 5778/5779 sınırını, selection family size değerinin overlong adayları içermemesini, invocation-local scar state'i ve observability invariance davranışını doğrular.

### Sınır

Patch 17 year-5000 tie düzeltmesi henüz yoktur.

Legacy stable sort by length only aynen kalır; eşit uzunluk runs için gate-opening düzeltmesi eklenmemiştir.


## Aşama 34 — Keşif 17: Year 5000 tie içinde stable length-only sırasını korumak

Stage 33 `prepare_for_selection` içindeki fiziksel `accepted.sort(key=length)` scar aynen bırakılır.

Buna paralel olarak Year-5000 historical yolu için `legacyStableSortByLength(candidates)` eklenir. Bu helper da yalnız `candidate.length` anahtarıyla stable sort yapar; equal-length run giriş sırası değişmez.

`LegacyYearCandidateAdapter.sort_year5000_candidates_after_filter`, candidate family'nin `open_day < calculation_day <= close_day` containment şartını ve `length<=5778` post-filter contract'ını doğrulayıp aynı historical length-only helper'a gider.

Real `calendar_date_spaghetti` state-machine üç equal-length candidate içeren opening-order witness family'yi actual adapter üzerinden çalıştırır. Giriş sırası `geç, erken, orta` olduğu için legacy stable sort aynı sırayı korur.

Test-only expected yol önce length sort yapar, sonra yalnız equal-length run içinde `open_day` ascending uygular. Üç farklı tie permütasyonunda expected `erken, orta, geç` iken actual input-stable run farklı kalır; üç alt örnek bilinçli kırmızıdır.

Production içinde equal-length run taraması, run içi opening-day sort veya temiz `(length,open_day)` sort yoktur. Patch 18 `oldJumpGuess` da henüz yoktur.


## Aşama 35 — Yama 17: legacy sort sonrasında yalnız equal-length runs düzeltmek

Stage 33 fiziksel `accepted.sort(key=length)` ve Stage 34 `legacyStableSortByLength` helper'ı aynen korunur.

Year-5000 adapter önce `legacy_result=legacyStableSortByLength(candidates)` çalıştırır ve raw legacy result mevcut `legacy_year5000_tie_sorted_*` alanlarında saklanır.

Yalnız bundan sonra `Year5000TiePatchWrapper` çağrılır. Wrapper legacy-sorted family'nin nondecreasing length contract'ını doğrular, contiguous equal-length runs bulur ve yalnız run uzunluğu birden büyük olan parçaları `run.sort(key=open_day)` ile kendi içinde düzeltir. Singleton ve farklı-length bölümler değişmez. Global `(length,open_day)` sort kullanılmaz.

Aşama 34 normatif Year-5000 tie regresyonunun gövdesi byte-for-byte değiştirilmeden yeşile döner. Raw legacy state yanlış input-stable sırayı göstermeye devam ederken semantic dönüş corrected earlier-opening sırasını verir.

Patch 18 `oldJumpGuess` ve year-by-year traversal henüz yoktur.


## Aşama 36 — Keşif 18: Year 5000'den 365 günlük ortalamayla sıçramak

### Tarihsel tahmin

Production içine exact legacy helper eklenir:

```text
oldJumpGuess(anchor,targetDay)
=
anchor.number
+
floorDiv(targetDay-anchor.first_day,365)
```

Python `//` işlemi integer floor division olarak kullanılır; negative delta davranışı da legacy formülle aynıdır.

### Historical semantic kusur

`LegacyYearJumpAdapter`, guess sonucunu diagnostic state'e yazar.

Fakat Keşif 18 aşamasında tahmin henüz telemetry-only değildir.

Aynı guess doğrudan:

```text
legacy_jump_semantic_year_number
```

olarak kullanılır.

Bu nedenle 365 günlük ortalama gerçek year transition zincirinin yerine geçer.

### Gerçek production yolu

Real `calendar_date_spaghetti` state-machine, Stage 35 Year-5000 tie katmanından sonra number 5000 olan, 5000 günlük valid ceiling-altı witness anchor oluşturur.

Hedef:

```text
anchor.close_day+1
```

olur.

Ardışık yıl semantiğinde bu gün yalnız year 5001 olabilir.

Legacy `/365` tahmini ise 5000 günlük anchor üzerinde çok ileri bir year number üretir ve actual semantic path bu yanlış değeri kullanır.

### Normatif ayrışma

Yeni normatif regresyon actual adapter yolunda üç hedefi yoklar:

```text
anchor.first_day+365
anchor.close_day
anchor.close_day+1
```

İlk iki hedef hâlâ year 5000 aralığındadır.

Üçüncü hedef close gate sonrasındaki ilk gün olduğu için year 5001'dir.

Legacy jump guess üçünde de farklı semantic year number üretir.

Üç alt örnek bilinçli kırmızıdır.

### Sınır

Production içinde `previousYear` veya `nextYear` walk yoktur.

`oldJumpGuess` sonucu henüz ignored telemetry değildir.

Patch 19 bad cache key kodu henüz yoktur.


## Aşama 37 — Yama 18: /365 tahminini telemetry yapıp year-by-year yürümek

Aşama 36 `oldJumpGuess(anchor,targetDay)` helper gövdesi aynen korunur. Her adapter call içinde helper semantic walk başlamadan önce gerçekten çalıştırılır ve raw guess diagnostic state'te kalır.

`SequentialYearWalkPatchWrapper` anchor year'dan başlar. `target_day>current.close_day` iken `nextYear`, `target_day<=current.open_day` iken `previousYear` tam bir yıl bir yıl çağrılır. Forward transition number `+1` ve shared close/open boundary, backward transition number `-1` ve shared open/close boundary taşımak zorundadır. Yürüyüş yalnız `open_day<target_day<=close_day` sağlandığında biter.

Aşama 36 normatif `/365` regression gövdesi byte-for-byte değiştirilmeden yeşile döner. Stage 36'nın yalnız historical state'i donduran non-normative testi, patch sonrası yeni state contract'ı için minimal olarak güncellenir: raw guess ayrı kalır ve `legacy_jump_guess_used_as_semantic=False` beklenir.

Patch wrapper arbitrary uzak hedeflerde caller tarafından verilen gerçek transition callback'leriyle bir yıl bir yıl yürür. Real Stage 37 production witness yalnız `close_day+1` adımını gerektirdiği için local fallback yalnız bu tek boundary adımını çözer; uzak hedefte gerçek transition provider zorunludur.

Patch 19 cache-by-year-number code henüz yoktur.


## Aşama 38 — Keşif 19: cache key olarak yalnız year.number kullanmak

Production içine `LegacyYearNumberOnlyCacheMap` eklenir. Map key'i yalnız `year.number` değeridir.

Request üzerinde `calculation_day`, `open_gate` ve `close_gate` bulunur, fakat legacy hit kararında bu alanların hiçbiri okunmaz. Map value yalnız opaque `LegacyYearCacheValue` değeridir; Patch 19 guard entry biçimi henüz yoktur.

Real state-machine cache key'ini doğrudan Stage 37 `LegacyYearJumpAdapter` semantic sonucundaki `legacy_jump_semantic_year_number` değerinden alır.

Aynı manager-owned cache'e aynı resolved year number ile iki request yapılır. İkinci request calculation day değerini değiştirir ve farklı value ister; legacy map yalnız year number gördüğü için ilk value yeniden kullanılır.

Yeni regression aynı year number için calculation day, open gate ve close gate değişimlerini ayrı ayrı sınar. Üç alt örnek bilinçli kırmızıdır.

Production içinde `calculationDayFingerprint` guarded entry, openGate/closeGate hit guard veya Patch 20 `oldStructureSauce` ghost kodu yoktur.


## Aşama 39 — Yama 19: kötü year.number key üstünde action guards

### Kötü key aynen kalır

Map hâlâ yalnız:

```text
year.number
```

ile anahtarlanır.

`legacyYearNumberOnlyLookup` yalnız bu key ile `map.get` eşdeğerini yapar ve gerçek lookup yolunda guard kontrollerinden önce çağrılır.

### Guarded value

Map value artık exact dört alan taşır:

```text
calculationDayFingerprint
openGate
closeGate
value
```

`calculationDayFingerprint` doğrudan request `calculation_day` yani authoritative pseudocode içindeki `cDay` değeridir.

### Hit kuralı

`YearCacheActionGuardPatchWrapper.cacheGetWithActionGuard` önce kötü legacy key ile entry arar.

Entry yoksa MISS.

`calculationDayFingerprint != calculation_day` ise MISS.

`openGate != open_gate` ise MISS.

`closeGate != close_gate` ise MISS.

Yalnız üç guard eşleşirse cached `value` HIT olarak döner.

### Miss overwrite

MISS durumunda `cachePutWithGuard` aynı `year.number` key altında yeni guarded entry yazar.

Composite key yapılmaz.

Böylece key'in tarihsel kusuru fiziksel olarak kalır; yanlış reuse guard ile engellenir.

### Stage 38 regression

Aşama 38 normatif stale-cache regression gövdesi byte-for-byte değiştirilmedi ve üç guard-source alt örneği yeşile döndü.

Aşama 38'in yalnız historical bug state'ini donduran iki non-normative testi yeni patch contract'ına minimal uyarlanır: key'in hâlâ tek `year.number` olduğu ve guard mismatch'in MISS olduğu doğrulanır.

### Sınır

Patch 20 `oldStructureSauce` ghost kodu henüz yoktur.

Structure target replacement veya year.firstDay sauce recomputation production'a eklenmemiştir.


## Aşama 40 — Keşif 20: structure sauce için original target kullanmak

### Historical helper

Production içine exact iki-argüman helper eklenir:

```text
oldStructureSauce(cDay,originalTargetDay)
```

Real calendar path original-target sauce'u daha önce zaten hesapladığı için helper bu mevcut final bowls ve drop-46 latch sonucunu invocation-local binding üzerinden kullanır. Böylece önceki aşamaların real-path call-count scar'ları ikinci kez çalıştırılmaz.

Standalone çağrıda `sauceWithCurrentScars` current Python implementation'ın kendi adapter zinciriyle aynı sauce sonucunu yeniden üretebilir.

### Real semantic kusur

`LegacyStructureSauceAdapter` resolved year first day değerini diagnostic state'te tutar.

Fakat semantic structure sauce hâlâ `oldStructureSauce(cDay,originalTargetDay)` sonucudur.

Old result doğrudan `LegacyStructureSelectorAdapter` inputuna gider.

### Production witness

Real `calendar_date_spaghetti` Stage 39 cache katmanından sonra Stage 37 resolved year open gate üzerinden `year_first_day=open_gate+1` hesaplar.

User original target bu first day'den farklıdır.

Buna rağmen old helper exact user original target ile çağrılır ve selector input target day aynı original target olarak kalır.

Aşama 39 terminal error string'i önceki regression scar'ı olduğu için fiziksel olarak aynen korunur.

### Normatif ayrışma

Yeni regression üç bağımsız `(cDay,originalTargetDay,yearFirstDay)` witness üzerinde actual adapter selector token değerini test-only authoritative `sauce(cDay,yearFirstDay).bowls[2]` ile karşılaştırır.

Üç witness'ta actual original-target sauce token ile authoritative year-first-day token ayrışır.

Üç alt örnek bilinçli kırmızıdır.

### Sınır

Production içinde old sauce ghost değildir.

Authoritative `(cDay,year.firstDay)` recomputation semantic yola eklenmemiştir.

Old result selector'dan ayrılmamıştır.

Patch 21 cutlet partition prefix-gate filter kodu henüz yoktur.


## Aşama 41 — Yama 20: old structure sauce'u ghost yapıp year first day sauce kullanmak

Aşama 40 `oldStructureSauce(cDay,originalTargetDay)` helper gövdesi byte-for-byte korunur ve her structure adapter çağrısında semantic patch'ten önce gerçekten çalışır.

Old result `patch20_old_ghost_*` state alanlarında saklanır; `patch20_old_ghost_reached_selector=False` olur.

`originalTargetDay!=year_first_day` ise `StructureSaucePatchWrapper`, current Python implementation ile `sauceWithCurrentScars(cDay,year_first_day)` sonucunu yeniden hesaplar. Selector yalnız bu semantic result'u görür. İki target eşitse old result zaten authoritative olduğu için ikinci recomputation yapılmaz.

Real calendar path old original-target sauce için mevcut final bowls/drop-46 latch sonucunu invocation-local binding ile reuse eder. Ayrı year-first-day semantic recomputation current production function gövdelerini kullanır; eski aşamaların real-path call-count instrumentation'ı bu semantic shadow calculation'ı ikinci historical traversal olarak saymaz.

Aşama 40 normatif original-target-versus-year-first-day regression gövdesi byte-for-byte değiştirilmeden yeşile döner. Historical bug state'ini donduran non-normative Stage 40 testleri yalnız patch'in zorunlu olarak değiştirdiği ghost-versus-selector contract'ına uyarlanır.

Patch 21 cutlet partition prefix-gate filter kodu henüz yoktur.


## Aşama 42 — Keşif 21: internal calculation-day gate'i yok sayan köfte bölümü

### Ne sanıldı

Köfte partition ailesinin yalnızca `gate_gap_count` toplamına sahip bütün pozitif `cutlet_count` bileşimlerinden oluşmasının yeterli olduğu sanıldı.

Bu historical family `LegacyAllPositiveCutletPartitionFamily` ile exact count ve lexicographic unrank olarak temsil edilir; dev bir liste materialize edilmez.

### Gerçek production yolu

`LegacyCutletPartitionAdapter`, Aşama 20 tarafından üretilen semantic structure sauce bowls/drop-46 order state'inden bowl 2, seal 21 answer ring kurar.

Seçim current kısa seçim semantiğiyle yapılır. Rank compatibility ayrı regresyonda aynı Python çizgisinin test-only normatif seçimiyle doğrulanır; böylece kırmızılığın seçim bias/rejection kusurundan gelmediği sabitlenir.

Real calendar state-machine witness olarak:

```text
gate_gap_count=9
cutlet_count=6
internal_gate_offset=4
```

verilerini gerçekten adapter'a geçirir.

### Ne keşfedildi

Legacy family internal calculation-day gate offsetini yalnız state'te kaydeder ve semantic family üzerinde hiçbir filtre uygulamaz.

Üç bağımsız structure-sauce witness'ında aynı bowl 2 / seal 21 answer stream kullanıldığında all-positive legacy family'den seçilen composition, test-only authoritative `CutletPartitionFamily(..., required_boundary=4)` seçimiyle ayrışır.

Bu üç alt örnek Aşama 42'nin beklenen tek kırmızılığıdır.

### Bilinçli sınır

`CutletPartitionGatePatchWrapper`, filtered legacy family, prefix-boundary semantic filter veya `patch21_applied` henüz production'da yoktur.

Patch 22 repeated-name generator kodu da eklenmemiştir.


## Aşama 43 — Yama 21: internal calculation-day gate için filtered legacy family

Aşama 42 `LegacyAllPositiveCutletPartitionFamily` gövdesi ve `LegacyCutletPartitionAdapter.call_with_ring` raw legacy metodu byte-for-byte korunur.

Her `LegacyCutletPartitionAdapter.call` içinde aynı bowl 2 / seal 21 answer ring kurulduktan sonra raw legacy selection önce gerçekten çalışır ve historical all-positive family sonucu diagnostic state'te kalır.

`FilteredLegacyCutletPartitionFamily` DP count/unrank kullanır. `required_boundary` internal gate offsetidir. Legal composition yalnız partial prefix sum'lardan biri exact bu boundary değerine eşitse ailede kalır.

DP unrank, all-positive legacy family'nin aynı lexicographic sırasını korur; yani filtered aile yalnız legacy sıradan eleme yapar, yeni bir sıralama tanımlamaz.

`CutletPartitionGatePatchWrapper` internal gate varsa filtered family count üzerinden current selection semantiğini uygular. Short count için Stage 13 rejection semantiğiyle uyumlu rank, wide count için Stage 14 wide-number semantiği kullanılır. Seçilen semantic composition gerekli internal boundary'yi vurmak zorundadır.

Internal gate yoksa filtered detour uygulanmaz ve raw legacy partition aynen semantic sonuç olur.

Aşama 42 normatif regression gövdesi byte-for-byte değiştirilmeden yeşile dönmüştür. Patch 22 repeated-name generator kodu henüz yoktur.


## Aşama 44 — Keşif 22: tekrar kabul eden ad üreteci

Bir yıl içindeki köfte adlarını seçmek için her pozisyonun frozen canonicalIndex havuzundan bağımsız alınabileceği sanıldı.

Historical family `master_count^item_count` büyüklüğündeki bütün lexicographic canonicalIndex dizileridir. `LegacyRepeatedNameGenerator` aynı canonicalIndex'in birden fazla pozisyonda görünmesine izin verir.

Aşama 20 semantic structure sauce state'inden bowl 5, seal 22 answer ring kurulur. Rank seçimi ayrı bir compatibility copy ile current short/wide selection semantiğine eşit tutulur; eski Patches 13–14 real-path instrumentation call-count scars ikinci historical traversal olarak tetiklenmez.

Aşama 43 semantic cutlet partition sonrasında real calendar handler frozen `SourceLanguageCatalog` içindeki 17 köfte canonicalIndex'i ve actual cutlet count ile generator'ı gerçekten çağırır. Türkçe name text selection/rank hesabına girmez.

Üç bağımsız witness'ın her birinde old `17^6` candidate gerçekten repeated canonicalIndex içerir. Expected test-only normative path `falling_factorial(17,6)`, bowl 5 / seal 22 rank seçimi ve `unrank_distinct_indices` ile hesaplanır. Üç witness yalnız repeated-name family yanlışlığı nedeniyle kırmızıdır.

Production içinde partial-permutation correction, `RepeatedNamePatchWrapper` veya `patch22_applied` yoktur. Patch 23 `VirtualLegacyList` kodu da eklenmemiştir.


## Aşama 45 — Yama 22: repeated legacy candidate üstüne distinct partial-permutation detour

Aşama 44 `LegacyRepeatedNameGenerator.call_with_ring` gövdesi byte-for-byte korunur ve `call_cutlet_names` içinde önce gerçekten çalışarak `bad` candidate üretir.

`fallingFactorialDistinct(master_count,item_count)` distinct family boyutunu exact düşen faktöriyel ile hesaplar.

`partialPermutationUnrank` 1-based rank değerini lexicographic distinct canonicalIndex sırasına exact açar.

`RepeatedNamePatchWrapper` aynı bowl 5 / seal 22 answer ring üzerinde distinct family count için `compatibleRepeatedNameRank` kullanarak `correct` candidate üretir.

Historical davranış gereği:

```text
if bad == correct:
    return bad
else:
    return correct
```

uygulanır.

Raw repeated candidate `legacy_name_candidate_indices` ve `patch22_bad_indices` içinde kalır. Semantic name indices patch sonucuna güncellenir.

Aşama 44 normatif equality regression korunur. Discovery testinin aynı method içindeki historical-repeat witness assert'i, final semantic result yerine raw `legacy_name_candidate_indices` scar'ını kontrol edecek şekilde zorunlu minimal uyarlanır; aksi halde patch sonrası distinct semantic output ile historical bad scar aynı nesneymiş gibi davranmak gerekirdi.

Patch 23 `VirtualLegacyList` month-length kodu henüz yoktur.


## Aşama 46 — Keşif 23: ay-uzunluğu bütün yollarını concrete materialize etmek

### Ne sanıldı

Legacy API'nin “bütün yolların listesi” ifadesi literal Python tuple listesi olarak yorumlandı.

`LegacyAllMonthLengthWaysAPI.list_all_ways` year-day toplamını `month_count` adet 4..123 aralığındaki ay uzunluğuna bölen bütün bounded compositions'ı lexicographic sırada concrete olarak üretir.

Küçük uzaylarda Python force brute ile exact sıra ve içerik doğrulanır.

### Ne keşfedildi

Bu family gerçek calendar sınırları içinde bile astronomik olabilir.

OOM üretmeden bunu kanıtlamak için `proveLegacyMonthLengthFamilyLowerBound` exact family count hesaplamaz. İlk `month_count-1` pozisyon için öyle bir `[prefix_low,prefix_high]` aralığı bulur ki bu aralıktaki bütün Cartesian seçimlerde son ay otomatik olarak 4..123 içinde kalır.

Dolayısıyla:

```text
(prefix_high-prefix_low+1)^(month_count-1)
```

gerçek family için matematiksel lower bound'dur.

300 gün / 10 ay, 400 gün / 10 ay ve 1000 gün / 20 ay witness'larında bu lower bound safe concrete-list sınırını aşar. Test-only `BoundedCompositionFamily.count()` yalnız proof kontrolü için exact count'un lower bound'dan küçük olmadığını doğrular; production oracle kullanmaz.

### Safe recovery

Historical materializer production'da aynen concrete-list backend'dir.

Ancak güvenli recovery, kanıtlanmış lower bound 100000'i aştığında allocation başlamadan `LegacyMaterializationTooLargeError` üretir; recursion içinde de aynı cap tekrar kontrol edilir. Böylece Discovery OOM yaratmaz.

`LegacyMonthLengthMaterializationAdapter` bu historical failure'ı invocation-local blocked state olarak kaydeder.

Real calendar path 300 gün / 10 ay witness'ını gerçekten adapter'a geçirir.

### Bilinçli sınır

`VirtualLegacyList`, exact DP count, exact lexicographic `itemAt1` ve `patch23_applied` henüz production'da yoktur.

Patch 24 `legacyChooseEachDaySeparately` kodu da eklenmemiştir.


## Aşama 47 — Yama 23: VirtualLegacyList exact DP backend

Aşama 46 `LegacyAllMonthLengthWaysAPI.list_all_ways` concrete materializer metodu byte-for-byte korunur.

`LegacyMonthLengthMaterializationAdapter.call` her invocation'da önce bu old backend'i gerçekten çağırır. Küçük family'de concrete tuple listesi oluşur; huge family'de Aşama 46 safe cap scar'ı allocation başlamadan blocked olur. Her iki durumda da historical state `legacy_month_length_*` alanlarında kalır.

Bundan sonra `MonthLengthVirtualPatchWrapper` çalışır.

`VirtualLegacyList` API contract:

```text
count()   = bounded composition family exact DP count
itemAt1(r)= exact 1-based lexicographic unrank
```

DP tablo yapısı slots ve subtotal eksenlerinde sliding-window recurrence kullanır. Dolayısıyla bütün family materialize edilmez.

`itemAt1` her pozisyonda 4..123 değerlerini ascending dener ve suffix DP block count değerlerini rank'ten çıkarır. Bu nedenle sıra, old concrete materializer'ın lexicographic sırasıyla exact aynıdır.

Semantic `LegacyMaterializationAttempt` huge family'de `blocked=False` döner, `exposed_count` virtual exact count verir ve `itemAt1` virtual backend'e delegasyon yapar. `concrete_ways` huge family'de `None` kalır.

Small family'de old concrete scar yine gerçekten materialize edilir; semantic backend yine VirtualLegacyList'tir ve virtual itemAt1 bütün old concrete rows ile aynı sırayı verir.

Aşama 46 normatif huge-family regression gövdesi değiştirilmeden yeşile dönmüştür.

Aşama 1 future-token guard yalnız artık current Patch 23 olan `VirtualLegacyList` tokenını yasak listesinden çıkarmak üzere minimal güncellenmiştir; Patch 24 ve Patch 25 tokenları hâlâ yasaktır.

Patch 24 month weaving ghost/DP detour kodu henüz yoktur.


## Aşama 48 — Keşif 24: ayı her gün ayrı seçen legacy weaving

### Historical helper

`legacyChooseEachDaySeparately(lengths, answer_stream)` her day position için answer ring'in o konumundaki cevabını month count moduna indirger.

Seçilen ayın remaining kapasitesi sıfırsa `wrapMonth` ile circular olarak sıradaki dolmamış aya geçer.

Bu nedenle helper her zaman:

```text
toplam gün sayısını korur
her monthId için exact multiplicity'yi korur
```

fakat bir bütün legal weaving family'den rank seçmez.

Özellikle ayların first occurrence sırasını ve last occurrence sırasını enforce etmez.

### Real production yolu

Aşama 20 semantic structure sauce bowls/drop-46 state'inden bowl 4 / seal 32 answer ring kurulur.

Aşama 47 month-length materialization aşamasından sonra real calendar state-machine `(4,4,4)` witness'ını `LegacyMonthWeavingAdapter` üzerinden gerçekten çalıştırır.

Adapter old ghost'u hem diagnostic hem current semantic weaving olarak kaydeder.

### Normatif divergence

Üç independent structure-sauce witness aynı `(4,4,4)` lengths ile kullanılır.

Her üç old ghost ilk pozisyonda month 1 yerine başka bir monthId ile başlar; dolayısıyla legal first-occurrence order'ı gerçekten bozar.

Test-only expected aynı bowl 4 / seal 32 stream üzerinde:

```text
family = MonthWeavingFamily(lengths)
rank = choose_rank(stream, family.count())
expected = family.unrank1(rank)
```

olarak hesaplanır.

Üç witness yalnız day-by-day local chooser bir whole-weaving rank seçmediği için kırmızıdır.

### Bilinçli sınır

Production içinde `wantedRank`, `DPUnrankLegalWeaving`, `MonthWeavingPatchWrapper` veya `patch24_applied` yoktur.

Patch 25 `oldContiguousMonthDayGuess` da henüz yoktur.

Stage 1 future-token guard'dan yalnız current Discovery 24 helper adı çıkarılmıştır; Patch 25 tokenı yasak kalır.


## Aşama 49 — Yama 24: day-by-day ghost üstüne legal whole-weaving DP detour

Aşama 48 `legacyChooseEachDaySeparately` raw helper gövdesi byte-for-byte korunur.

`LegacyMonthWeavingAdapter.call` aynı bowl 4 / seal 32 answer ring üzerinde önce bu helper'ı gerçekten çalıştırır ve historical `ghost` state'ini kaydeder.

`LegalMonthWeavingDP`, legal month weaving family'nin first-occurrence ve last-occurrence sırasını exact olarak temsil eder.

`count()` exact legal family count verir.

`unrank1(rank1)` move sırasını ascending monthId düzeninde dolaşır ve suffix state count değerlerini kullanarak exact 1-based lexicographic legal weaving unrank yapar.

`compatibleMonthWeavingRank` same ring üzerinde current short/wide selection semantiğini legal family count'a uygular ve `wantedRank` üretir.

`MonthWeavingPatchWrapper`:

```text
wantedRank = compatibleMonthWeavingRank(ring, legal_count)
correct_weaving = DPUnrankLegalWeaving(lengths, wantedRank)

if ghost == correct_weaving:
    return ghost
else:
    return correct_weaving
```

semantiğini uygular.

Ghost ve correct aynıysa aynı ghost tuple nesnesi döndürülür.

Ghost diagnostic scar olarak `legacy_month_weaving_ghost` ve `patch24_ghost` içinde kalır. Current semantic weaving `patch24_semantic_weaving` olur.

Aşama 48 expected legal-weaving hesabı ve final `actual == expected` assertion'ı korunmuştur. Aynı regression içindeki historical “ghost ilk symbol month 1 değil” kanıtı final semantic result yerine raw ghost state'ine yönlendirilmiştir; bu Patch 24 sonrası zorunlu minimal uyarlamadır.

Patch 25 `oldContiguousMonthDayGuess` kodu henüz yoktur.


## Aşama 50 — Keşif 25: month occurrence'ları contiguous sanan day-in-month hesabı

### Historical helper

`oldContiguousMonthDayGuess(weaving,target_position)` target position'daki monthId'yi bulur.

Sonra aynı monthId'nin yıl içindeki ilk occurrence position'ını arar ve:

```text
guessed_day = target_position - first_position + 1
```

hesaplar.

Bu ancak o monthId'nin bütün occurrence'ları gerçekten contiguous ise doğrudur.

Legal month weaving interleaved olabilir. Bu durumda aradaki başka monthId günleri de yanlışlıkla day-in-month hesabına eklenir.

### Real production yolu

`LegacyContiguousMonthDayAdapter` Patch 24 corrected semantic weaving hazırlandıktan sonra çalışır.

Real calendar witness yılın dördüncü position'ını kullanır.

Stage 49 semantic `(4,4,4)` weaving bu noktada month 1'i non-contiguous taşır; old helper ilk occurrence ile target arasındaki bütün positions'ı month 1 günü sanır.

Adapter guessed value'yu hem diagnostic hem current semantic day-in-month state olarak kaydeder.

### Normatif divergence

Üç structure-sauce witness için Stage 49 legal semantic weaving kullanılır.

Target positions sırasıyla 4, 5 ve 4'tür.

Expected yalnız test tarafında:

```text
monthId = weaving[target_position-1]
expected = count(weaving[1..target_position] == monthId)
```

şeklinde doğrudan occurrence count ile hesaplanır.

Üç witness'ın üçünde old contiguous guess expected occurrence count'tan büyüktür ve yalnız bu nedenle kırmızıdır.

### Bilinçli sınır

Production içinde `countMonthOccurrencesThroughTarget`, `MonthDayOccurrencePatchWrapper`, `correct_day_in_month` veya `patch25_applied` yoktur.

Patch 26 opening-gate interval correction kodu da henüz yoktur.

Stage 1 future-token guard current oldContiguousMonthDayGuess tokenını artık yasaklamaz.


## Aşama 51 — Yama 25: contiguous guess üstüne occurrence-count overwrite

Aşama 50 `oldContiguousMonthDayGuess` raw helper gövdesi byte-for-byte korunur.

`LegacyContiguousMonthDayAdapter.call`, Patch 24 corrected semantic weaving üzerinde önce bu old helper'ı gerçekten çalıştırır ve `legacy_month_day_guessed_day` state'ini bırakır.

`countMonthOccurrencesThroughTarget(weaving,target_position)` target position'daki monthId'yi alır ve weaving başlangıcından target dahil prefix sonuna kadar aynı monthId occurrence sayısını exact hesaplar.

`MonthDayOccurrencePatchWrapper` old wrong guess'i diagnostic state'te tutar ve semantic day-in-month değerini occurrence count ile unconditional overwrite eder.

Bu nedenle contiguous month occurrence durumunda old ve correct sayılar eşit kalabilir; interleaved durumda old mesafe tahmini correct occurrence count ile değiştirilir.

Aşama 50 expected occurrence-count hesabı ve final `actual == expected` assertion'ı korunmuştur. Historical `old > expected` witness assertion'ı final semantic result yerine raw `legacy_month_day_guessed_day` scar'ına yönlendirilmiştir.

Patch 26 opening-gate interval correction kodu henüz yoktur.


## Aşama 52 — Keşif 26: opening gate'i current year'a bağlayan kapalı-sol interval

### Historical interval

`legacyFindYearClosedOpeningInterval` historical year containment kuralını:

```text
[open, close]
```

olarak uygular.

Backward search condition:

```text
while target_day < current.open_day
```

şeklindedir.

Bu nedenle `target_day == current.open_day` olduğunda `previousYear` hiç çağrılmaz.

Opening gate current year'a atanır.

### Authoritative divergence

Normatif year interval:

```text
(open, close]
```

olmalıdır.

Dolayısıyla current year'in opening gate günü current year'e ait değildir; önceki year'in closing gate günüdür.

Discovery 26 bunu üç bağımsız numeric year witness ile gösterir.

Her witness'ta actual legacy result current year number'dır, expected previous year number'dır.

### Real production yolu

Aşama 51 month-day occurrence patch tamamlandıktan sonra dispatcher yeni `LegacyOpeningGateIntervalAdapter` katmanına geçer.

Anchor, Aşama 18 resolved year state'inden alınır.

Witness target doğrudan `anchor.open_day` yapılır.

Safe previous-year provider boundary continuity'yi taşır:

```text
previous.number = current.number - 1
previous.close_day = current.open_day
```

Legacy `<` condition nedeniyle provider real witness'ta çağrılmaz ve backward step 0 kalır.

### Bilinçli sınır

`OpeningGateIntervalPatchWrapper`, `correctOpeningGateInterval`, `patch26_applied` veya bu yeni layer içinde `while target_day <= current.open_day` correction path'i yoktur.

Aşama 18'in daha önceki authoritative sequential-year walk implementation'ı değiştirilmemiştir; Keşif 26 kendi historical interval layer'ını gerçek dispatcher path sonunda açıkça taşır.


## Aşama 53 — Yama 26: [open,close] scar üstüne (open,close] detour

Aşama 52 `legacyFindYearClosedOpeningInterval` raw historical function gövdesi byte-for-byte korunur.

`LegacyOpeningGateIntervalAdapter.call` önce bu old path'i gerçekten çalıştırır. Bu path `target_day == open_day` boundary'sinde backward step 0 bırakır ve current year'ı raw result olarak kaydeder.

`correctOpeningGateInterval` aynı original anchor ve aynı `previousYear` zinciri üzerinde:

```text
while target_day <= current.open_day
```

koşuluyla geri yürür.

Final invariant:

```text
current.open_day < target_day <= current.close_day
```

olmalıdır.

`OpeningGateIntervalPatchWrapper` old raw result'u diagnostic scar olarak tutar ve semantic year assignment'ı correct `(open,close]` result ile değiştirir.

Old ve correct result aynıysa old result nesnesi yeniden kullanılabilir. Opening-boundary case'te old current year state'te kalırken semantic result previous year olur.

Aşama 52 normatif regression gövdesi değiştirilmeden yeşile dönmüştür. Yalnız Patch 26 absence testleri current presence durumuna ilerletilmiştir.

Aşama 54 integration layer henüz eklenmemiştir.


## Aşama 54 — Final spaghetti-monster integration

Yirmi altı discovery/patch çifti tamamlandıktan sonra historical zincir artık geçici `StageNotIntegratedError` noktasında durmaz. Aynı exact Aşama 39 terminal metni source içinde diagnostic scar olarak kalır, fakat semantic kontrol `FinalSpaghettiIntegrationManager` katmanına aktarılır.

### Authoritative main path

`calendar_date_spaghetti` önce bütün önceki dispatcher/handler/adapter/patch zincirini gerçek olarak çalıştırır. Ardından integration manager uzun bir program-counter machine ile `YIL_5000 -> CACHE -> YAPI -> SONUÇ -> BİTTİ` akışını yürütür.

Bu machine semantic state için old/pending/rollback snapshot alanlarını, commit token'larını, finite retry budget'ını, compatibility flags'ı ve result validation hook'unu taşır. Logs, metrics ve diagnostics semantic kararlara geri okunmaz.

### Sauce ve gate/year zinciri

`sauceWithScars` mevcut Stage 1–20 production sauce katmanlarını kullanır. Gate cache Foundation etrafında positive/negative gate sorularını exact answer-ring seçimiyle üretir. Year candidate discovery historical 5781 üst sınırına kadar scar olarak yürür; 5779–5781 candidates selector'a ulaşmadan late 5778 filter ile elenir. Year 5000 tie sırası length ve open-day detour'u ile belirlenir. Target year, `oldJumpGuess` telemetrisine rağmen sequential year walk ile bulunur ve `(open,close]` boundary semantics korunur.

### Guarded cache ve structure ghost

Year cache key fiziksel olarak yalnız year number kalır. Calculation-day fingerprint, open gate ve close gate guard'ları uyuşmadan hit semantic olarak kullanılamaz.

Structure sauce önce original target ghost'unu taşır; authoritative structure sauce `(calculation_day, year.first_day)` ile seçilir.

### Cutlet ve ad detour'ları

Cutlet partition önce unrestricted positive-composition legacy universe'ü üretir; internal calculation-day gate varsa filtered legacy family aynı lexicographic sırada authoritative rank/unrank sonucu verir.

Cutlet ve month name seçimlerinde repeated-name legacy candidate gerçekten üretilir. Distinct partial-permutation detour authoritative sonucu verir; semantic ordering yalnız canonical index üzerinden yapılır.

### Month length, weaving ve day-in-month

Month length family `VirtualLegacyList` ile exact count/itemAt1 semantics taşır. Concrete-all-ways historical scar temizlenmez.

Month weaving için `legacyChooseEachDaySeparately` ghost gerçekten çalışır. Authoritative weaving `LegalMonthWeavingDP` ile seçilir. Büyük family'lerde integration exact hızlı unrank, küçük family brute/current DP eşitliğiyle doğrulanmıştır.

Final month arithmetic önce `oldContiguousMonthDayGuess` ghost'unu gerçekten çalıştırır. Semantic `day_in_month`, year başlangıcından target dahil aynı monthId occurrence sayısıdır.

### Exactly-five result ve oracle separation

Final result yalnız beş alandır ve source-language display textleri frozen `SourceLanguageCatalog` üzerinden resolve edilir. Production hiçbir yerde test-only `normative_reference` import/call/fallback yapmaz.

### Verification

Yüklenen Aşama 53 baseline yeniden kuruldu: `365/365 PASS`.

Aşama 54 değişikliklerinden sonra historical regressions ayrı process'te: `365/365 PASS`.

Aşama 54 integration suite taze ayrı Python process'te: `10/10 PASS`.

Toplam: `375` test, `0 failure`, `0 error`.

Process isolation yalnız test harness kaynak tüketimini sınırlar; production mode veya semantic branch değildir.

Aşama 55 audit henüz başlamamıştır.
