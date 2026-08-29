# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk dokuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 49/55, `PATCH 24` durumundadır.

Aşama 48 `legacyChooseEachDaySeparately` helper'ı aynen kalır ve önce gerçek ghost üretir.

Yeni `LegalMonthWeavingDP` legal whole-weaving family için exact count ve exact lexicographic unrank sağlar.

Same bowl 4 / seal 32 answer ring üzerinde legal family count ile `wantedRank` seçilir.

`MonthWeavingPatchWrapper` correct weaving'i DP-unrank eder.

Ghost correct ile tamamen aynıysa aynı ghost tuple döner; aksi halde correct semantic weaving döner.

Historical ghost state'te kalır, current semantic weaving corrected result olur.

Aşama 48 expected hesabı ve final semantic equality assertion'ı korunarak üç normatif witness yeşile dönmüştür.

Patch 25 contiguous month-day kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk dokuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: 331 testin tamamı geçer ve depo durumu `GREEN` olur. Aşama 48'de kırmızı olan üç day-by-day weaving witness corrected legal whole-weaving semantic result ile yeşile dönmelidir.
