# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin elli birinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 51/55, `PATCH 25` durumundadır.

Aşama 50 `oldContiguousMonthDayGuess` helper'ı aynen kalır ve önce gerçekten çalışır.

Yeni `countMonthOccurrencesThroughTarget`, target dahil year-prefix içinde target monthId occurrence sayısını exact hesaplar.

`MonthDayOccurrencePatchWrapper` old guessed value'yu diagnostic scar olarak bırakır ve current semantic day-in-month değerini occurrence count ile overwrite eder.

Contiguous month occurrence durumunda old ve correct değer aynı olabilir; interleaved durumda old mesafe tahmini düzeltilir.

Aşama 50 expected hesabı ve final semantic equality assertion'ı korunarak üç normatif witness yeşile dönmüştür.

Patch 26 opening-gate interval kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam elli birinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: 348 testin tamamı geçer ve depo durumu `GREEN` olur. Aşama 50'de kırmızı olan üç contiguous-month-day witness occurrence-count overwrite ile yeşile dönmelidir.
