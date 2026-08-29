# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 22/55, `DISCOVERY 11` durumundadır.

Production yolu artık 46 exact drop bowl roundunu ve 12 exact post-stir roundunu tam olarak yürütür. Bowl sonuçları test-only normatif sonuçlarla eşleşir.

Yeni tarihsel kusur order belleğindedir. Legacy katman tek genel alan kullanır:

```text
drop 1..46 -> aynı order belleğine yaz
stir 1..12 -> yine aynı order belleğine yaz
query order -> son yazılan genel belleği oku
```

Bu nedenle drop 46 tamamlandığında doğru order geçici olarak bellekte olsa da 12 post-stir tarafından ezilir; semantic query yolu sonunda stir 12 order değerini görür.

Yeni normatif regresyon query order'ı exact drop 46 order ile karşılaştırır ve position 1, 2 ve 6 alt örneklerinde bilinçli olarak kırmızıdır.

Henüz `PATCH 11` latch'i yoktur. Drop 46 order için ayrı, tek-yazımlı bellek kurulmamıştır.

Patch 12'nin queried next-bowl mantığı da henüz eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–21 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni overwritten-order normatif regresyonunun position 1, 2 ve 6 alt örnekleri başarısız olur.
