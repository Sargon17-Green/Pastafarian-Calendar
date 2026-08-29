# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin dördüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 4/55, `DISCOVERY 02` durumundadır. Yeni tarihsel kusur gerçek üretim zincirine bağlanmıştır:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)
```

Bu eski hesap kuruluş gününden önce normatif gün sayımıyla uyuşur; kuruluş gününde `0` yerine `1` gerekir ve kuruluş gününden sonraki normatif tek değerler eski yolda çift kalır.

`LegacyDayTagAdapter` hem eylem hem hedef günü için bu yanlış hesabı çalıştırır. Yeni regresyon bu gerçek adapter yolunu temiz normatif başvuruyla karşılaştırır ve kuruluş günü ile sonraki örneklerde bilerek kırmızıdır. Henüz `PATCH 02` eklenmemiştir.

Birinci tarihsel yara ve Yama 01 aynen korunur; önceki bütün regresyonlar yeşildir. Gelecekteki 03–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Önceki Aşama 1–3 regresyonları ayrı olarak çalıştırılabilir.

Tam dördüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki regresyonlar geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni gün etiketi normatif regresyonunun kuruluş günü ve kuruluş gününden sonraki alt örnekleri başarısız olur. Bu kırmızılık `DISCOVERY 02` aşamasının beklenen sonucudur.
