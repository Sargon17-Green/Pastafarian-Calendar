# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz altıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 36/55, `DISCOVERY 18` durumundadır.

Exact legacy jump helper:

```text
oldJumpGuess(anchor,targetDay)
=
anchor.number
+
floorDiv(targetDay-anchor.first_day,365)
```

olarak production'a eklenmiştir.

`LegacyYearJumpAdapter` bu tahmini diagnostic state'te saklar, fakat historical kusur gereği aynı guess henüz doğrudan semantic target year number olarak kullanılır.

Real calendar state-machine Year-5000 witness anchor için `close_day+1` hedefinde bu yolu gerçekten çalıştırır.

Yeni normatif regresyon üç hedefte 365 günlük tahmini gerçek ardışık-year interval semantiğiyle karşılaştırır ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 18` yoktur: `oldJumpGuess` telemetry-only değildir ve `previousYear`/`nextYear` one-at-a-time walk production'a eklenmemiştir.

Patch 19 cache kodu da henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz altıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–35 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni `/365` jump-versus-sequential-year normatif regresyonunun üç alt örneği başarısız olur.
