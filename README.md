# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin elli üçüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 53/55, `PATCH 26` durumundadır.

Aşama 52 historical `[open,close]` search aynen kalır ve önce gerçekten çalışır.

Yeni `correctOpeningGateInterval`, backward boundary koşulunda `target_day <= current.open_day` kullanır ve final year containment'i `(open,close]` olarak doğrular.

`OpeningGateIntervalPatchWrapper` wrong legacy result'u scar olarak saklar, semantic year result'u correct assignment ile değiştirir.

Opening gate witness'ında raw legacy backward step 0 ve current year result korunur; corrected semantic path bir year geri gider.

Aşama 52 normatif regression değiştirilmeden yeşile dönmüştür.

Bütün 26 discovery/patch çifti artık tamamlanmıştır. Aşama 54 integration henüz yapılmamıştır.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam elli üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: 365 testin tamamı geçer ve depo durumu `GREEN` olur. Aşama 52'de kırmızı olan üç opening-gate boundary witness aynı normatif regression gövdesiyle yeşile dönmelidir.
