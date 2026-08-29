# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on dördüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 14/55, `DISCOVERY 07` durumundadır. Yedinci tarihsel kusur gerçek visible-drop zincirine eklenmiştir.

11 gerçek grind satırı sentinel olmadan `index 0..10` tabloda tutulur. Legacy indexing ise 1-based grind numarasını doğrudan tablo indeksi olarak kullanır:

```text
legacyGrindRow(table, grind)
    -> table[grind]
```

Bu nedenle `grind=1` gerçek satır 2'yi okur, gerçek satır 1 atlanır ve `grind=11` index dışına çıkar. Recovery scar son hatayı kaydeder ve o ana kadar oluşmuş yanlış `x` değerini bırakır; bu bir düzeltme değildir.

`LegacyVisibleDropBuilderAdapter`, 46 görünür damlayı önceki exact count/stone/hidden/history katmanlarının üstünde gerçek production state-machine yoluna bağlar.

Yeni normatif regresyon görünür damla 1, 2 ve 46 değerlerini test-only normatif visible-drop builder ile karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 07` yoktur: index 0 sentinel row eklenmemiştir ve gerçek 11 grind satırı 1..11 slotlarına kaydırılmamıştır.

Önceki Aşama 1–13 regresyonlarının tamamı yeşildir. Gelecekteki 08–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on dördüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–13 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni grind-table normatif regresyonunun görünür damla `i=1`, `i=2` ve `i=46` alt örnekleri başarısız olur.
