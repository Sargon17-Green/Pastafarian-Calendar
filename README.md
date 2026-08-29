# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 32/55, `DISCOVERY 16` durumundadır.

Zorunlu legacy sabit:

```text
LEGACY_YEAR_MAX=5781
```

oluşturulmuş ve candidate acceptance içinde gerçekten kullanılmaktadır.

Legacy candidate family `gate_gap_count>=6` ve `252<=length<=5781` koşuluyla sort/selection girişine gider.

Real calendar state-machine `5778,5779,5780,5781` boundary probe ailesini actual adapter üzerinden acceptance/sort girişinde çalıştırır. Önceki real-path selection call-count scar'ları korunur; bu probe ekstra selection çağrısı yapmaz.

Yeni normatif regresyon 5779, 5780 ve 5781 günlük adayların normatif 5778 tavanına rağmen sort/selection öncesi family'ye sızdığını gösterir ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 16` yoktur: `REAL_YEAR_MAX_PATCH=5778` ve `candidateLength>5778` early reject filtresi eklenmemiştir.

Patch 17 tie düzeltmesi de henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–31 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni 5781-ceiling normatif regresyonunun 5779, 5780 ve 5781 alt örnekleri başarısız olur.
