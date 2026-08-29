# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin yirmi sekizinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 28/55, `DISCOVERY 14` durumundadır.

Stage 27 short-selection yolu aynen korunur.

Yeni tarihsel kusur `LegacyShortOnlySelectionDispatcher` içindedir: family size değerini ayrıştırmadan her zaman short adapter'a gönderir.

`N>M_OLD` için short adapter input'u reddeder; dispatcher bunu unsupported-wide scar olarak kaydeder ve semantic rank üretemez.

Real calendar path gerçek sauce-derived answer ring üzerinde `N=M_OLD+1` wide attempt çalıştırır.

Yeni normatif regresyon `M_OLD+1`, `M_OLD^2` ve `M_OLD^3` family size değerlerinde actual dispatcher sonucunu test-only exact wide selection ile karşılaştırır ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 14` yoktur: `N<=M`/`N>M` ayrımı, multi-place base-M number ve wide-number rejection production'a eklenmemiştir.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam yirmi sekizinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–27 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni short-only-versus-wide normatif regresyonunun üç wide-family alt örneği başarısız olur.
