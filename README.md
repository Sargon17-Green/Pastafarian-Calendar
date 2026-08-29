# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin onuncu aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 10/55, `DISCOVERY 05` durumundadır. Beşinci tarihsel kusur gerçek çağrı zincirine eklenmiştir.

Gizli damlalar fiziksel olarak ters sırada saklanır:

```text
legacyHidden[1] = hidden7
legacyHidden[2] = hidden6
...
legacyHidden[7] = hidden1
```

`buildHiddenWithBackwardStorage` bu backward storage'ı üretir. `LegacyHiddenDropAdapter` onu gerçek `calendar_date_spaghetti` yoluna bağlar.

Discovery kusuru near-ness erişimindedir: `k` doğrudan `legacyHidden[k]` olarak okunur. Böylece `hidden1` isteği `hidden7` döndürür. `hidden4` ise ters düzenin orta noktası olduğu için tesadüfen doğru kalır.

Yeni normatif regresyon `k=1,2,4,6,7` için gerçek adapter erişimini test-only normatif gizli damlalarla karşılaştırır. Dört alt örnek bilinçli olarak kırmızıdır; `k=4` geçer.

Henüz `PATCH 05` yoktur: `hiddenByNearness(legacyHidden,k) -> legacyHidden[8-k]` erişim çevirmeni eklenmemiştir ve backward storage fiziksel olarak ters çevrilmemiştir.

Önceki Aşama 1–9 regresyonlarının tamamı yeşildir. Gelecekteki 06–26 kusur ve yamaları üretime eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam onuncu aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–9 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni gizli-damla near-ness regresyonunun `k=1`, `k=2`, `k=6` ve `k=7` alt örnekleri başarısız olur. `k=4` ters storage'ın sabit orta noktası olarak geçer.
