# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi dördüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 24/55, `DISCOVERY 12` durumundadır.

Yeni tarihsel kusur:

```text
oldNextBowlFixedName(id)
1->2->3->4->5->6->1
```

Legacy next-bowl sorgusu queried ID'nin `orderAt46Latch` içindeki gerçek position'ını dikkate almaz.

`LegacyNextBowlAdapter` bu wrong fixed-ID helper'ını Stage 23 latch tamamlandıktan sonra gerçek production state-machine yoluna bağlar.

Fixture latch `(1,2,3,4,6,5)` için queried ID 4, 5 ve 6 sonuçları latch-based circular successor değerlerinden bilinçli olarak ayrışır.

Henüz `PATCH 12` yoktur: queried ID latch içinde aranmaz ve circular successor detour'u production'a eklenmemiştir.

Aşama 1 future-name guard zaten Patch 13+ isimleriyle sınırlıdır ve bu aşamada değiştirilmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi dördüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–23 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni fixed-ID next-bowl normatif regresyonunun queried ID 4, 5 ve 6 alt örnekleri başarısız olur.
