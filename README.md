# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk sekizinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 48/55, `DISCOVERY 24` durumundadır.

Yeni `legacyChooseEachDaySeparately`, bowl 4 / seal 32 answer ring'i kullanarak her günü ayrı ayrı bir monthId'ye yollar.

Dolu ay seçilirse `wrapMonth` ile circular olarak kalan kapasitesi olan sonraki aya geçer.

Böylece exact month multiplicities korunur; fakat whole legal weaving family'nin first/last occurrence sırası uygulanmaz.

`LegacyMonthWeavingAdapter` old ghost'u doğrudan current semantic weaving olarak kullanır.

Real calendar path Aşama 47'den sonra `(4,4,4)` witness'ını gerçekten çalıştırır.

Üç normatif witness'ın üçünde ghost legal first-occurrence sırasını bozar ve test-only `MonthWeavingFamily` rank sonucundan ayrışır.

Henüz wanted rank, legal-weaving DP unrank veya Patch 25 kodu yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk sekizinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki 313 test geçer. Yeni Discovery 24 non-normative kontrolleri geçer; yalnız `test_current_day_by_day_month_choice_diverges_from_legal_weaving_rank` testinin üç subTest witness'ı beklenen nedenle kırmızı olur. Depo durumu `EXPECTED_RED` olur.
