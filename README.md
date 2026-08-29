# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yedinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 7/55, `PATCH 03` durumundadır. Üçüncü tarihsel kusur kodda aynen korunur:

```text
oldDistance(calculationDay, targetDay) =
    abs(
        dayTagWithFoundationScar(calculationDay)
        - dayTagWithFoundationScar(targetDay)
    )
```

Düzeltme onun üstündeki `patchedCounts` ve `DistancePatchWrapper` katmanındadır:

```text
legacy = oldDistance(calculationDay, targetDay)
chronological = abs(targetDay - calculationDay)

if legacy != chronological:
    legacy = chronological

distance = legacy + 1
```

Gerçek `LegacyDistanceAdapter` yolu bu yamadan geçer. Ham legacy mesafe, kronolojik ara fark, son mesafe ve legacy değerin değiştirildiğini gösteren durum çağrıya ait `MonsterContext` içinde ayrı tutulur.

Aşama 6'nın normatif regresyonu değiştirilmeden artık yeşildir. Önceki bütün regresyonlar geçer. Gelecekteki 04–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yedinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 6'da kırmızı olan mesafe normatif regresyonu aynı gövdeyle yeşile dönmelidir; `oldDistance` kusurunu doğrudan doğrulayan testler eski yanlış sonuçları korur.
