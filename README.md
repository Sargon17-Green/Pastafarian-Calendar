# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin on altıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 16/55, `DISCOVERY 08` durumundadır. Sekizinci tarihsel kusur gerçek state-machine zincirine eklenmiştir.

`oldPermutationUnrank0(rank0)` fiziksel olarak 0-based helper'dır ve `0..719` rank aralığında doğru lexicographic permütasyonu üretir.

Kusur çağrı katmanındadır:

```text
oneBased = regularMod(drop-1,720)+1
order = oldPermutationUnrank0(oneBased)
```

Yani 1-based `1..720` order numarası yanlışlıkla doğrudan rank0 olarak kullanılır.

Böylece `oneBased=1` ilk permütasyon yerine ikinci permütasyona gider; `oneBased=720` ise helper aralığının dışındadır.

`LegacyPermutationOrderAdapter`, 46 görünür damlanın legacy order tablosunu gerçek `calendar_date_spaghetti` state-machine yoluna bağlar. Pours henüz başlatılmamıştır.

Yeni normatif regresyon gerçek order-table yolunun `i=1`, `i=2` ve `i=46` değerlerini test-only normatif bowl order ile karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 08` yoktur: `legacyRank0 = oneBased-1` çevirisi eklenmemiştir.

Stage 15'in kalıcı grind sentinel row'u korunur. Önceki Aşama 1–15 regresyonlarının tamamı yeşildir. Gelecekteki 09–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam on altıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–15 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni permutation-rank normatif regresyonunun `i=1`, `i=2` ve `i=46` alt örnekleri başarısız olur.
