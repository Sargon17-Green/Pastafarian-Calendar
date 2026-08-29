# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirminci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 20/55, `DISCOVERY 10` durumundadır.

Yeni tarihsel kusur bowl update loop'undadır:

```text
read current/previous/next from working
compute new bowl
write new bowl back to working immediately
continue with next position
```

Aynı logical drop içindeki sonraki positions böylece önceki position'ın yeni bowl değerini okuyabilir.

`LegacyBowlUpdateAdapter`, Stage 19 corrected pours üstünde bu wrong in-place yolu drop 1 için gerçek `calendar_date_spaghetti` state-machine zincirine bağlar.

Yeni normatif regresyon drop 1 için position 2, 3 ve 6 bowl sonuçlarını tek eski snapshot kullanan test-only normatif formülle karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 10` yoktur: eski bowl snapshot'ı, ayrı write buffer ve altı bowl sonrası toplu commit katmanı eklenmemiştir.

46-drop full bowl pass, order-at-46 latch ve post-stir de henüz yoktur.

Stage 15 sentinel, Stage 17 permutation patch ve Stage 19 bowlAlias patch korunur. Önceki Aşama 1–19 regresyonlarının tamamı yeşildir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirminci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–19 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni in-place bowl contamination normatif regresyonunun position 2, 3 ve 6 alt örnekleri başarısız olur.
