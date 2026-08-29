# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz dokuzuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 39/55, `PATCH 19` durumundadır.

Legacy cache map key olarak yalnız `year.number` kullanmaya devam eder.

Raw `legacyYearNumberOnlyLookup` yalnız bu kötü key ile entry arar ve guard kontrollerinden önce gerçekten çağrılır.

Map value artık:

```text
calculationDayFingerprint
openGate
closeGate
value
```

alanlarını taşır.

`calculationDayFingerprint` doğrudan current `calculation_day` değeridir.

Hit yalnız calculation day fingerprint, open gate ve close gate guard'larının üçü de eşleşirse kabul edilir.

Herhangi bir guard mismatch `MISS` olur ve aynı `year.number` key altında yeni guarded entry yazılır.

Composite key kullanılmaz.

Aşama 38 normatif stale-cache regression gövdesi değiştirilmeden yeşile dönmüştür.

Patch 20 `oldStructureSauce` ghost kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz dokuzuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: bütün testler geçer ve depo durumu `GREEN` olur. Aşama 38'de kırmızı olan calculation day, open gate ve close gate cache alt örnekleri aynı normatif regression gövdesiyle yeşile dönmelidir.
