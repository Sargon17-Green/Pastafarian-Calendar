# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi altıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 26/55, `DISCOVERY 13` durumundadır.

Production artık final bowl state üstünde exact answer ring kurar. First answer ve ±1 direction test-only normatif stream ile eşleşir.

Yeni tarihsel kusur:

```text
biasedLegacyPick(x,N)
    -> regularMod(x-1,N)+1
```

helper'ının acceptance/rejection yapılmadan hemen çağrılmasıdır.

`LegacyBiasedSelectionAdapter` bu wrong direct-modulo yolu gerçek `calendar_date_spaghetti` state-machine zincirine bağlar.

Yeni normatif regresyon üç gerçek sauce-derived answer ring için legacy direct modulo sonucunu aynı answer ring üzerinde rejection sonrası seçimle karşılaştırır ve bilinçli olarak kırmızıdır.

Henüz `PATCH 13` yoktur: production `limit=floor(M/N)*N` hesaplamaz ve accepted answer bulunana kadar ring üzerinde ilerlemez.

Patch 14 wide-selection kodu da henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi altıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–25 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni biased-modulo normatif regresyonunun üç sauce-derived alt örneği başarısız olur.
