# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin ellinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 50/55, `DISCOVERY 25` durumundadır.

Yeni `oldContiguousMonthDayGuess`, target month'un ilk occurrence position'ı ile target position arasındaki mesafeyi day-in-month sanır.

Bu historical hesap month occurrence'larının contiguous olduğunu varsayar.

Patch 24 legal semantic weaving interleaved olabildiği için aradaki başka monthId positions yanlışlıkla aynı ayın günleri sayılır.

`LegacyContiguousMonthDayAdapter` bu old helper'ı real calendar path üzerinde corrected weaving'den sonra gerçekten çalıştırır ve guessed value'yu current semantic day-in-month state yapar.

Üç normatif witness occurrence count ile karşılaştırıldığında tam üç expected divergence üretir.

Henüz occurrence-count correction veya Patch 26 kodu yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam ellinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki 331 test geçer. Yeni Discovery 25 non-normative kontrolleri geçer; yalnız `test_current_contiguous_month_day_guess_diverges_from_occurrence_count` testinin üç subTest witness'ı beklenen nedenle kırmızı olur. Depo durumu `EXPECTED_RED` olur.
