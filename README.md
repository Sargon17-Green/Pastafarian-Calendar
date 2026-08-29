# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi üçüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 23/55, `PATCH 11` durumundadır.

Discovery 11'in overwrite scar'ı aynen korunur:

```text
legacy_overwritable_order_memory
46 drop + 12 post-stir = 58 write
```

Drop 46 tamamlandıktan ve post-stir başlamadan hemen önce exact order fiziksel clone ile ayrı latch'e yazılır:

```text
orderAt46Latch = clone(order46)
```

Bu latch invocation başına yalnızca bir kez yazılır ve post-stir sırasında hiçbir zaman yeniden yazılmaz.

`query_order` artık overwritable belleği değil yalnızca `orderAt46Latch` değerini okur.

Aşama 22'nin normatif overwritten-order regresyonu değiştirilmeden yeşile dönmüştür.

Patch 12 queried next-bowl logic henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 22'de kırmızı olan position 1, 2 ve 6 query-order alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
