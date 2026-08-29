# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk üçüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 43/55, `PATCH 21` durumundadır.

Aşama 42 all-positive legacy family ve raw `call_with_ring` scar'ı aynen kalır ve gerçekten çalışır.

Yeni `FilteredLegacyCutletPartitionFamily`, internal calculation-day gate offsetini bir partial prefix sum olarak vuran legacy composition'ların tam alt ailesini DP count/unrank ile temsil eder.

Filtered aile legacy family'nin aynı lexicographic sırasını korur.

`CutletPartitionGatePatchWrapper`, internal gate varsa aynı bowl 2 / seal 21 answer ring üzerinde filtered family count ile selection yapar ve yalnız filtered semantic partition döndürür.

Internal gate yoksa raw legacy sonuç aynen kullanılır.

Aşama 42 normatif regression gövdesi değiştirilmeden yeşile dönmüştür.

Patch 22 repeated-name generator kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: 278 testin tamamı geçer ve depo durumu `GREEN` olur. Aşama 42'de kırmızı olan üç internal-gate witness aynı normatif regression gövdesiyle yeşile dönmelidir.
