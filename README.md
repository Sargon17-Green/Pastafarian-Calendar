# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin elli ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 52/55, `DISCOVERY 26` durumundadır.

Yeni `legacyFindYearClosedOpeningInterval`, historical year interval'ını `[open,close]` kabul eder.

Backward search yalnız `target_day < current.open_day` iken geri yürür.

Bu yüzden target tam opening gate olduğunda current year yanlışlıkla seçilir.

Authoritative interval `(open,close]` olduğundan opening gate önceki year'in closing boundary günüdür.

`LegacyOpeningGateIntervalAdapter` bu kusuru real calendar path sonunda, Aşama 18 resolved year anchor'ının tam open-day boundary witness'ında gerçekten çalıştırır.

Üç normatif witness yalnız bu boundary koşulu yüzünden expected previous year'dan ayrışır.

Patch 26 correction henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam elli ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki 348 test geçer. Yeni Discovery 26 non-normative kontrolleri geçer; yalnız `test_current_closed_opening_interval_assigns_open_gate_to_wrong_year` testinin üç subTest witness'ı beklenen nedenle kırmızı olur. Depo durumu `EXPECTED_RED` olur.
