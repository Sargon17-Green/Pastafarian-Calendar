# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin sekizinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 8/55, `DISCOVERY 04` durumundadır. Dördüncü tarihsel kusur gerçek çağrı zincirine eklenmiştir.

`mutateStonesWrong`, beş taş değerini aynı mutable state üzerinde sırayla değiştirir. İlk `w` hesabı eski satırı görürken sonraki hesaplar daha önce aynı çağrıda yazılmış yeni değerleri okur.

`getStoneTableThroughLegacyBuilder`, 1 numaralı başlangıç satırından sonra 2–46 satırlarını bu yanlış in-place mutasyonla üretir. `LegacyStoneBuilderAdapter` tabloyu gerçek `calendar_date_spaghetti` yoluna bağlar.

Yeni normatif regresyon gerçek builder yolunun 2, 3 ve 46 numaralı satırlarını test-only normatif taş tablosuyla karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 04` yoktur: eski snapshot, clone üzerinde korunmuş legacy çağrısı, `garbage` sonucu veya beş alanı snapshot'tan yeniden yazan `stonePatch` eklenmemiştir.

Önceki Aşama 1–7 regresyonlarının tamamı yeşildir. Gelecekteki 05–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam sekizinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–7 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni taş-tablosu normatif regresyonunun 2, 3 ve 46 numaralı satır alt örnekleri başarısız olur.
