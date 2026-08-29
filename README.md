# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz birinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 31/55, `PATCH 15` durumundadır.

Discovery 15 helper scar'ı fiziksel olarak korunur:

```text
oldGateQuestionDay(n)=FOUNDATION_DAY_OLD+n
```

`NegativeGatePatchWrapper` bu helper'ı diagnostic olarak gerçekten çağırır.

Semantic sonuç:

```text
signed_step<0 -> FOUNDATION_DAY_OLD-abs(step)
signed_step>=0 -> oldGateQuestionDay(abs(step))
```

şeklindedir.

Aşama 30 normatif negative-gate regresyonu değiştirilmeden yeşile dönmüştür.

Patch 16 year-limit kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz birinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 30'da kırmızı olan `-1`, `-2` ve `-10` negative-gate alt örnekleri aynı normatif regresyon gövdesiyle yeşile dönmelidir.
