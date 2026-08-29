# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk ikinci aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 42/55, `DISCOVERY 21` durumundadır.

Yeni `LegacyAllPositiveCutletPartitionFamily`, `gate_gap_count` toplamının bütün pozitif `cutlet_count` bileşimlerini lexicographic sırada temsil eder.

`LegacyCutletPartitionAdapter`, Aşama 20 semantic structure sauce state'inden bowl 2 / seal 21 answer ring kurar ve bu tam legacy family'den seçim yapar.

Internal calculation-day gate offset state'te gerçekten taşınır, fakat legacy family bundan dolayı filtrelenmez.

Real calendar path 9 gate aralığı, 6 köfte ve internal offset 4 witness'ını çalıştırır.

Üç normatif witness bilinçli olarak kırmızıdır: authoritative family internal gate offsetinin bir partial sum ile vurulmasını zorunlu tutarken current legacy family bunu yok sayar.

Patch 21 prefix-boundary düzeltmesi henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk ikinci aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki 263 test geçer. Aşama 42 yeni testlerinin non-normative kontrolleri geçer; yalnız `test_current_all_positive_cutlet_family_ignores_internal_gate_boundary` testinin üç subTest witness'ı beklenen nedenle kırmızı olur. Depo durumu `EXPECTED_RED` olur.
