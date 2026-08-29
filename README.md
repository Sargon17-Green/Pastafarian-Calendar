# Python + Türkçe Makarna Canavarı takvim uygulaması

Bu ağaç, zaman tomarının normatif algoritmasını Python ile gerçekleştirecek bağımsız uygulama çizgisinin otuz dördüncü aşama durumudur. Çizgi sıfırdan kurulmuştur; başka bir programlama dilindeki uygulamanın kodu, testi, çıktısı, özeti, önbelleği, günlüğü veya sağlaması kaynak olarak kullanılmamıştır.

## Güncel aşama

Aşama 34/55, `DISCOVERY 17` durumundadır.

Stage 33 içindeki fiziksel stable length-only sort scar aynen korunur.

Year-5000 historical yolu ayrıca:

```text
legacyStableSortByLength(candidates)
```

helper'ıyla aynı yalnız-length stable davranışı taşır.

`LegacyYearCandidateAdapter.sort_year5000_candidates_after_filter` calculation-day containment ve patched 5778 ceiling contract'ından sonra Year-5000 tie family'yi bu historical sort'a yollar.

Real calendar state-machine üç equal-length opening-order witness candidate ile actual adapter yolunu gerçekten çalıştırır.

Yeni normatif regresyon üç farklı tie giriş sırasını, legacy stable-length sonucuyla test-only authoritative run-order beklentisi arasında karşılaştırır ve üç alt örneği bilinçli kırmızı bırakır.

Henüz `PATCH 17` yoktur: equal-length run taraması veya run içi opening-day sort production'a eklenmemiştir. Temiz iki-anahtarlı sort da yoktur.

Patch 18 `oldJumpGuess` kodu henüz yoktur.

## Korunan birinci aşama temeli

- Python standart kitaplığına dayanan temiz ve yalnızca test amaçlı normatif başvuru uygulaması.
- On yedi köfte adı ve kırk yedi ay adı için dondurulmuş `SourceLanguageCatalog`.
- Her ad için değişmez `canonicalIndex`; sıralama ve seçim yalnızca bu indislerle yapılır.
- Üretim tarafında çağrı başına `MonsterContext`, temel dağıtıcı, doğrulayıcı, hata sarmalayıcısı ve gözlem sayaçları.
- Henüz tarih sonucu üretmeyen `calendar_date_spaghetti` başlangıç yolu.

## Kaynak dili

Bu uygulamanın tek insan kaynak dili Türkçedir. Anlam taşıyan kaynak adları Türkçedeki anlamlarıyla çevrilmiştir. Yer adlarında yerleşik Türkçe biçimler kullanılmıştır. Uydurma ses dizileri sabit ve belgelenmiş bir çevriyazı kuralıyla yazılır. Metin hiçbir zaman normatif sıralamaya katılmaz; normatif kimlik `canonicalIndex` değeridir.

## Çalıştırma

Tam otuz dördüncü aşama paketi:

```text
python -m unittest discover -s tests -v
```

Beklenen sonuç: önceki Aşama 1–33 regresyonları geçer. Tam paket `EXPECTED_RED` durumundadır; yalnızca yeni Year-5000 equal-length opening-order normatif regresyonunun üç alt örneği başarısız olur.
