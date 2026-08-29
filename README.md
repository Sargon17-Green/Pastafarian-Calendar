# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 12/55, `DISCOVERY 06` durumundadır. Altıncı tarihsel kusur eklenmiştir:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Bu legacy history yardımcı yalnızca `i-back >= 1` olduğunda görünür `dropStore` slotunu bulabilir. İlk görünür damlalarda gereken `slot=0..-6` hidden geçmişini bilmez.

`LegacyPriorAdapter`, fonksiyonu gerçek `calendar_date_spaghetti` state-machine yoluna bağlar. Visible-drop hesabı henüz kurulmadığı için ana yol semantic sonucu etkilemeyen valid-slot probe çalıştırır.

Yeni normatif regresyon gerçek adapter yolunu `slot=0`, `slot=-2` ve `slot=-6` için test-only normatif hidden değerleriyle karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 06` yoktur: `priorPatch`, `hiddenK=1-slot` ve `hiddenByNearness` üzerinden nonpositive slot çevirisi eklenmemiştir.

Önceki Aşama 1–11 regresyonlarının tamamı yeşildir. Gelecekteki 07–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–11 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni prior/history normatif regresyonunun `slot=0`, `slot=-2` ve `slot=-6` alt örnekleri başarısız olur.
