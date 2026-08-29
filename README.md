# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin altıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 6/55, `DISCOVERY 03` durumundadır. Üçüncü tarihsel kusur gerçek çağrı zincirine eklenmiştir:

```text
oldDistance(calculationDay, targetDay) =
    abs(
        dayTagWithFoundationScar(calculationDay)
        - dayTagWithFoundationScar(targetDay)
    )
```

`LegacyDistanceAdapter` bu yanlış değeri gerçek `calendar_date_spaghetti` yolunda üretir ve çağrıya ait `MonsterContext` içinde saklar.

Yeni normatif regresyon gerçek adapter yolunu `abs(targetDay-calculationDay)+1` mesafesiyle karşılaştırır. Aynı gün, daha uzun aynı-yön örneği ve kuruluşu aşan örnekler bilinçli olarak kırmızıdır. Bir günlük kuruluş-sonrası örneği tesadüfen geçer.

Henüz `PATCH 03` yoktur: kronolojik farkla karşılaştırma, legacy sonucu kronolojik değerle değiştirme ve son `+1` eklenmemiştir.

Yama 01 ve Yama 02 ile önceki tarihsel yaralar korunur; önceki bütün regresyonlar yeşil kalır. Gelecekteki 04–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam altıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–5 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni mesafe normatif regresyonunun gerçekten ayrışan alt örnekleri başarısız olur. Bu kırmızılık `DISCOVERY 03` aşamasının beklenen sonucudur.
