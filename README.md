# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi beşinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 25/55, `PATCH 12` durumundadır.

Discovery 12 fixed-ID scar'ı fiziksel olarak korunur:

```text
oldNextBowlFixedName(id)
1->2->3->4->5->6->1
```

`NextBowlPatchWrapper` bu helper'ı diagnostic olarak gerçekten çağırır, fakat semantic sonucu ondan almaz.

Corrected yol:

```text
position = queriedId'nin orderAt46Latch içindeki konumu
next = orderAt46Latch[(position+1) mod 6]
```

şeklindedir.

Aşama 24'ün normatif next-bowl regresyonu değiştirilmeden yeşile dönmüştür. Latch içindeki altı ID'nin tamamı circular successor semantiğiyle doğrulanır.

Patch 13 biased modulo selection kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi beşinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 24'te kırmızı olan queried ID 4, 5 ve 6 alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
