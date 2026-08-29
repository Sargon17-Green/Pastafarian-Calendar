# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk yedinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 47/55, `PATCH 23` durumundadır.

Aşama 46 concrete `LegacyAllMonthLengthWaysAPI.list_all_ways` scar'ı aynen kalır ve semantic adapter içinde önce gerçekten çalışır.

Huge family'de old backend safe cap nedeniyle blocked diagnostic state bırakır.

Yeni `VirtualLegacyList`, aynı “bütün yollar” family için:

```text
count() = exact DP count
itemAt1(rank1) = exact lexicographic unrank
```

sağlar.

Bütün family hiçbir zaman materialize edilmez.

Semantic `LegacyMaterializationAttempt` huge family'yi `blocked=False` olarak expose eder; `exposed_count` exact virtual count, `itemAt1` virtual unrank sonucudur.

Small family'de old concrete scar da oluşur, fakat semantic backend yine virtual'dır ve sıra birebir aynıdır.

Aşama 46 normatif huge-family regression gövdesi değiştirilmeden yeşile dönmüştür.

Patch 24 month weaving kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk yedinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: 313 testin tamamı geçer ve depo durumu `GREEN` olur. Aşama 46'da kırmızı olan üç huge-family witness aynı normatif regression gövdesiyle yeşile dönmelidir.
