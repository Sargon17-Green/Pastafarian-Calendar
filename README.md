# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz üçüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 33/55, `PATCH 16` durumundadır.

Discovery 16 legacy ceiling'i fiziksel olarak ve aktif biçimde korunur:

```text
LEGACY_YEAR_MAX=5781
```

Ayrı patch ceiling:

```text
REAL_YEAR_MAX_PATCH=5778
```

olarak eklenmiştir.

Her candidate önce legacy 5781 acceptance helper'ından geçer; bu sonuç diagnostic scar olarak saklanır. Ardından `candidate.length>5778` olan candidate semantic family'den atılır.

Filtre `accepted.sort(...)` ve selection çağrısından önce uygulanır.

Böylece 5779, 5780 ve 5781 legacy scar katmanında hâlâ kabul edilmiş görünür, fakat sort/selection family'ye girmez.

Aşama 32 normatif regresyonu değiştirilmeden yeşile dönmüştür.

Patch 17 year-5000 tie düzeltmesi henüz yoktur; legacy stable length-only sort aynen kalır.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz üçüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 32'de kırmızı olan 5779, 5780 ve 5781 alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
