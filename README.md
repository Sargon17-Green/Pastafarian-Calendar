# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin dokuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 9/55, `PATCH 04` durumundadır. Dördüncü tarihsel kusur kodda aynen korunur: `mutateStonesWrong` hâlâ aynı mutable state'i sequential biçimde kirletir.

Düzeltme onun üstündeki `stonePatch` katmanındadır:

```text
old = clone(S)
garbage = mutateStonesWrong(i, clone(S))

garbage.w = savePatch(old.w*old.w + 3*old.b + i)
garbage.b = savePatch(old.b*old.b + 5*old.s + old.w)
garbage.s = savePatch(old.s*old.s + 7*old.m + old.b)
garbage.m = savePatch(old.m*old.m + 11*old.r + old.s)
garbage.r = savePatch(old.r*old.r + 13*old.w + old.m)
```

Legacy çağrısı gerçek bir clone üzerinde çalışır ve gerçek garbage üretir; ardından beş alanın tamamı yalnızca old snapshot okuyan formüllerle ezilir.

`getStoneTableThroughLegacyBuilder` artık 2–46 satırlarını `stonePatch` üzerinden üretir. Aşama 8'in normatif taş-tablosu regresyonu değiştirilmeden yeşile dönmüştür.

Adapter son patch satırının old snapshot, legacy garbage ve committed row scar durumlarını invocation'a ait `MonsterContext` içinde ayrı tutar. Önceki bütün regresyonlar yeşildir. Gelecekteki 05–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam dokuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 8'de kırmızı olan 2, 3 ve 46 numaralı taş satırı regresyonları aynı gövdeyle yeşile dönmelidir; `mutateStonesWrong` kusurunu doğrudan doğrulayan testler eski yanlış davranışı korumaya devam eder.
