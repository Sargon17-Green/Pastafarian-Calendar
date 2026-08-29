# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz sekizinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 38/55, `DISCOVERY 19` durumundadır.

`LegacyYearNumberOnlyCacheMap` map key olarak yalnız `year.number` kullanır. Request `calculation_day`, `open_gate` ve `close_gate` bilgilerini taşısa da legacy hit kararı bunları görmez.

Real calendar state-machine cache key'ini Stage 37 `LegacyYearJumpAdapter` tarafından semantic olarak çözülen year number üzerinden alır ve aynı year number için calculation day değiştirilmiş ikinci request'i aynı cache'e yollar.

Legacy cache ikinci request'te stale ilk value değerini semantic token olarak yeniden kullanır.

Yeni normatif regression aynı year number altında calculation day, open gate ve close gate değişimlerini ayrı ayrı yoklar ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 19` yoktur: guarded cache entry içinde `calculationDayFingerprint/openGate/closeGate/value` tutulmaz ve hit için üç guard karşılaştırılmaz.

Patch 20 `oldStructureSauce` kodu da henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz sekizinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–37 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni year-number-only cache regressionunun calculation day, open gate ve close gate alt örnekleri başarısız olur.
