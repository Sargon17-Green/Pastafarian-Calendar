# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz beşinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 35/55, `PATCH 17` durumundadır.

Historical stable length-only scar'lar aynen korunur.

Year-5000 semantic yolu önce legacy sort'u çalıştırır ve raw input-stable sonucu diagnostic state'te saklar.

Ardından `Year5000TiePatchWrapper` yalnız contiguous equal-length runs bulur. Yalnız run uzunluğu birden büyük olan parçalar `candidate.open_day` ascending ile earlier gate opening sırasına alınır.

Singleton ve farklı-length bölümler değiştirilmez. Global `(length,open_day)` sort kullanılmaz.

Aşama 34 normatif tie regresyonu değiştirilmeden yeşile dönmüştür.

Patch 18 `oldJumpGuess` ve year-by-year traversal kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz beşinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 34'te kırmızı olan üç Year-5000 tie permütasyonu aynı normatif regresyon gövdesiyle yeşile dönmelidir.
