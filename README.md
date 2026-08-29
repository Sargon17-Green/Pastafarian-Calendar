# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi yedinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 27/55, `PATCH 13` durumundadır.

`biasedLegacyPick(x,N)` direct-modulo scar olarak fiziksel korunur.

Corrected kısa seçim önce:

```text
limit = floor(M_OLD/N)*N
```

hesaplar; sonra aynı answer ring üzerinde `x<=limit` olana kadar ilerler ve legacy helper'ı yalnız accepted `x` ile çağırır.

Aşama 26 normatif biased-selection regresyonu değiştirilmeden yeşile dönmüştür.

Real calendar probe bounded tutulur; bu stage-only probe herhangi bir tarihte uzun rejection yürüyüşü oluşturmaz.

Henüz `N>M_OLD` wide dispatcher veya `wideDetour` yoktur; Patch 14 başlamamıştır.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi yedinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 26'da kırmızı olan üç sauce-derived short-selection alt örneği aynı normatif regresyon gövdesiyle yeşile dönmelidir.
