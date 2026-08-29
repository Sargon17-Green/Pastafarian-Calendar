# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin kırk altıncı aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 46/55, `DISCOVERY 23` durumundadır.

`LegacyAllMonthLengthWaysAPI`, bounded month-length composition family'yi literal concrete “bütün yollar listesi” olarak materialize eder.

Küçük uzaylar Python force brute ile exact doğrulanır.

`proveLegacyMonthLengthFamilyLowerBound`, exact DP count kullanmadan tamamen legal bir Cartesian alt-family kurar ve family'nin milyarlarca veya daha fazla eleman içerebildiğini OOM oluşturmadan kanıtlar.

Legacy concrete backend safe recovery sınırını aşan proof gördüğünde allocation başlamadan block olur.

Real calendar state-machine 300 gün / 10 ay witness'ı ile bu kusurlu API'yi gerçekten çağırır.

Henüz `VirtualLegacyList`, exact DP `count`, exact lexicographic `itemAt1` veya Patch 24 kodu yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam kırk altıncı aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki 295 test geçer. Yeni Discovery 23 non-normative kontrolleri geçer; yalnız `test_current_legacy_all_ways_api_cannot_expose_huge_family` testinin üç subTest witness'ı beklenen nedenle kırmızı olur. Depo durumu `EXPECTED_RED` olur.
