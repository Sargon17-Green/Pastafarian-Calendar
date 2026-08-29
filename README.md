# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on birinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 11/55, `PATCH 05` durumundadır. Beşinci tarihsel kusurun fiziksel storage'ı aynen korunur:

```text
legacyHidden[1] = hidden7
...
legacyHidden[7] = hidden1
```

Aşama 10'un yanlış direct accessor'ı da kodda kalır. Düzeltme yalnızca üst erişim katmanındadır:

```text
hiddenByNearness(legacyHidden, k)
    -> legacyHidden[8-k]
```

`LegacyHiddenDropAdapter.read_by_nearness`, `HiddenNearnessPatchWrapper` üzerinden önce yanlış direct accessor'ı gerçekten çalıştırır, ham legacy değerini scar olarak tutar ve authoritative sonuç olarak 8-k çevirmeninin değerini döndürür.

Aşama 10'un normatif hidden near-ness regresyonu değiştirilmeden artık yeşildir. Backward storage fiziksel olarak ters çevrilmemiştir.

Önceki bütün regresyonlar yeşildir. Gelecekteki 06–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on birinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 10'da kırmızı olan `k=1,2,6,7` hidden near-ness alt örnekleri aynı regresyon gövdesiyle yeşile dönmelidir; backward physical storage ve yanlış direct accessor ayrı testlerde korunmaya devam eder.
