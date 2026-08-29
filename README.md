# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz yedinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 37/55, `PATCH 18` durumundadır.

`oldJumpGuess(.../365...)` fiziksel olarak aynen korunur ve her jump çağrısında telemetry için gerçekten hesaplanır. Ancak guess artık semantic year number değildir.

`SequentialYearWalkPatchWrapper` anchor Year 5000'den başlayarak hedef current interval içine girene kadar `nextYear` veya `previousYear` callback'ini bir yıl bir yıl çağırır.

Forward step `number+1` ve shared close/open boundary ister. Backward step `number-1` ve shared open/close boundary ister.

Hedef interval kuralı `open_day < target_day <= close_day` olarak uygulanır.

Aşama 36 normatif `/365` regresyonu değiştirilmeden yeşile dönmüştür. Yalnız historical state'i donduran non-normative Stage 36 testi yeni telemetry-only contract'a uyarlanmıştır.

Patch 19 cache-by-year-number kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz yedinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 36'da kırmızı olan üç `/365` jump alt örneği aynı normatif regression gövdesiyle yeşile dönmelidir.
