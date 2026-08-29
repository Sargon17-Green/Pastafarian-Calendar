# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on üçüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 13/55, `PATCH 06` durumundadır. Altıncı tarihsel kusur kodda aynen korunur:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Düzeltme onun üstündeki `priorPatch` ve `PriorPatchWrapper` katmanındadır:

```text
slot = i - back

if slot >= 1:
    return legacyPrior(dropStore, i, back)

hiddenK = 1 - slot
return hiddenByNearness(legacyHidden, hiddenK)
```

Pozitif visible-history branch'i eski helper'ı gerçekten çağırır ve hidden storage gerektirmez. Nonpositive branch ise `hiddenK=1-slot` üzerinden önceki hidden near-ness translator'ına gider.

Aşama 12'nin normatif history regresyonu değiştirilmeden artık yeşildir. `legacyPrior` hidden history bilmeyen fiziksel biçimiyle kodda kalır.

Önceki bütün regresyonlar yeşildir. Gelecekteki 07–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 12'de kırmızı olan slot 0, -2 ve -6 hidden-history alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir; pozitif visible slot branch'i `legacyPrior` üzerinden hidden storage gerektirmeden çalışmaya devam eder.
